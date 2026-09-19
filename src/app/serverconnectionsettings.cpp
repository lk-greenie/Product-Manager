#include "serverconnectionsettings.h"

#include "appconfig.h"
#include "enter.h"
#include "tabledisplay.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStringList>

#ifdef Q_OS_WIN
#include <windows.h>
#include <wincrypt.h>
#endif

namespace {
const QByteArray kEncryptedConfigHeader("QPM_DATABASE_SERVER_CONFIG_V1\n");
const QByteArray kRememberedLoginHeader("QPM_REMEMBERED_LOGIN_V1\n");

QByteArray protectForCurrentWindowsUser(const QByteArray &plainText, QString *errorMessage)
{
#ifdef Q_OS_WIN
    DATA_BLOB input{};
    input.cbData = static_cast<DWORD>(plainText.size());
    input.pbData = reinterpret_cast<BYTE *>(const_cast<char *>(plainText.constData()));

    DATA_BLOB output{};
    if (!CryptProtectData(&input, L"qmlProductManager database server config", nullptr,
                          nullptr, nullptr, CRYPTPROTECT_UI_FORBIDDEN, &output)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Windows 加密服务失败（错误码 %1）").arg(GetLastError());
        return {};
    }

    const QByteArray encrypted(reinterpret_cast<const char *>(output.pbData),
                               static_cast<qsizetype>(output.cbData));
    LocalFree(output.pbData);
    return encrypted;
#else
    Q_UNUSED(plainText)
    if (errorMessage)
        *errorMessage = QStringLiteral("当前平台不支持 Windows 加密配置文件");
    return {};
#endif
}

QByteArray unprotectForCurrentWindowsUser(const QByteArray &encrypted, QString *errorMessage)
{
#ifdef Q_OS_WIN
    DATA_BLOB input{};
    input.cbData = static_cast<DWORD>(encrypted.size());
    input.pbData = reinterpret_cast<BYTE *>(const_cast<char *>(encrypted.constData()));

    DATA_BLOB output{};
    if (!CryptUnprotectData(&input, nullptr, nullptr, nullptr, nullptr,
                            CRYPTPROTECT_UI_FORBIDDEN, &output)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("无法解密配置文件（请使用生成该文件的 Windows 用户导入，错误码 %1）")
                    .arg(GetLastError());
        return {};
    }

    const QByteArray plainText(reinterpret_cast<const char *>(output.pbData),
                               static_cast<qsizetype>(output.cbData));
    LocalFree(output.pbData);
    return plainText;
#else
    Q_UNUSED(encrypted)
    if (errorMessage)
        *errorMessage = QStringLiteral("当前平台不支持 Windows 解密配置文件");
    return {};
#endif
}

QJsonObject databaseObjectFromValues(const QVariantMap &values, const QString &prefix)
{
    return {
        {QStringLiteral("host"), values.value(prefix + QStringLiteral("host")).toString()},
        {QStringLiteral("port"), values.value(prefix + QStringLiteral("port")).toInt()},
        {QStringLiteral("username"), values.value(prefix + QStringLiteral("username")).toString()},
        {QStringLiteral("password"), values.value(prefix + QStringLiteral("password")).toString()},
        {QStringLiteral("name"), values.value(prefix + QStringLiteral("name")).toString()}
    };
}

bool appendDatabaseValues(const QJsonObject &database, const QString &prefix, QVariantMap *values,
                          QString *errorMessage)
{
    const QStringList requiredKeys{
        QStringLiteral("host"), QStringLiteral("username"), QStringLiteral("password"),
        QStringLiteral("name")
    };
    for (const QString &key : requiredKeys) {
        if (!database.contains(key) || !database.value(key).isString()) {
            if (errorMessage)
                *errorMessage = QStringLiteral("加密配置文件缺少 %1 数据库的 %2 字段")
                        .arg(prefix, key);
            return false;
        }
    }
    if (!database.contains(QStringLiteral("port")) || !database.value(QStringLiteral("port")).isDouble()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("加密配置文件缺少 %1 数据库的端口")
                    .arg(prefix);
        return false;
    }

    values->insert(prefix + QStringLiteral("host"), database.value(QStringLiteral("host")).toString());
    values->insert(prefix + QStringLiteral("port"), database.value(QStringLiteral("port")).toInt());
    values->insert(prefix + QStringLiteral("username"), database.value(QStringLiteral("username")).toString());
    values->insert(prefix + QStringLiteral("password"), database.value(QStringLiteral("password")).toString());
    values->insert(prefix + QStringLiteral("name"), database.value(QStringLiteral("name")).toString());
    return true;
}
}

ServerConnectionSettings::ServerConnectionSettings(Enter *loginManager,
                                                   TableDisplay *tableDisplay,
                                                   QObject *parent)
    : QObject(parent), m_loginManager(loginManager), m_tableDisplay(tableDisplay)
{
    m_statusMessage = connected()
            ? QStringLiteral("数据库服务器已连接")
            : AppConfig::hasDatabaseServerConfig()
              ? QStringLiteral("已导入加密数据库服务器配置，可手动连接")
              : QStringLiteral("未导入加密数据库服务器配置");

    QString rememberedLoginError;
    if (!loadRememberedLogin(&rememberedLoginError))
        qWarning().noquote() << rememberedLoginError;
}

bool ServerConnectionSettings::importDefaultEncryptedConfig(QString *errorMessage)
{
    QVariantMap values;
    if (!readEncryptedConfig(AppConfig::databaseServerConfigPath(), &values, errorMessage))
        return false;
    AppConfig::setDatabaseServerValues(values);
    return true;
}

QString ServerConnectionSettings::encryptedConfigPath() const
{
    const QString path = AppConfig::databaseServerConfigPath();
    return AppConfig::hasDatabaseServerConfig() && QFileInfo::exists(path) ? path : QString();
}

QString ServerConnectionSettings::rememberedUsername() const
{
    return m_rememberedUsername;
}

QString ServerConnectionSettings::rememberedPassword() const
{
    return m_rememberedPassword;
}

bool ServerConnectionSettings::rememberLogin() const
{
    return m_rememberLogin;
}

bool ServerConnectionSettings::connected() const
{
    return m_loginManager && m_tableDisplay
            && m_loginManager->isDatabaseConnected()
            && m_tableDisplay->isDatabaseConnected();
}

QString ServerConnectionSettings::statusMessage() const
{
    return m_statusMessage;
}

bool ServerConnectionSettings::importEncryptedConfig(const QUrl &fileUrl)
{
    const QString sourcePath = fileUrl.toLocalFile();
    if (sourcePath.isEmpty()) {
        setStatusMessage(QStringLiteral("请选择本机上的加密数据库服务器配置文件"));
        return false;
    }

    QString error;
    QVariantMap values;
    if (!readEncryptedConfig(sourcePath, &values, &error)) {
        setStatusMessage(error);
        return false;
    }

    QFile sourceFile(sourcePath);
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        setStatusMessage(QStringLiteral("无法读取配置文件：%1").arg(sourceFile.errorString()));
        return false;
    }
    const QByteArray encryptedContents = sourceFile.readAll();
    sourceFile.close();

    const QString destinationPath = AppConfig::databaseServerConfigPath();
    if (!QDir().mkpath(AppConfig::configDirectory())) {
        setStatusMessage(QStringLiteral("无法创建配置目录：%1").arg(AppConfig::configDirectory()));
        return false;
    }

    QSaveFile destinationFile(destinationPath);
    if (!destinationFile.open(QIODevice::WriteOnly) || destinationFile.write(encryptedContents) != encryptedContents.size()
            || !destinationFile.commit()) {
        setStatusMessage(QStringLiteral("无法保存加密配置文件到：%1").arg(destinationPath));
        return false;
    }

    AppConfig::setDatabaseServerValues(values);
    emit settingsChanged();
    setStatusMessage(QStringLiteral("已导入加密数据库服务器配置：%1")
                     .arg(QDir::toNativeSeparators(destinationPath)));
    return true;
}

bool ServerConnectionSettings::generateEncryptedConfig(const QString &host, int port,
                                                        const QString &username, const QString &password,
                                                        const QString &userDatabaseName,
                                                        const QString &businessDatabaseName)
{
    const QString normalizedHost = host.trimmed();
    const QString normalizedUsername = username.trimmed();
    QVariantMap values{
        {QStringLiteral("userDatabase/host"), normalizedHost},
        {QStringLiteral("userDatabase/port"), port},
        {QStringLiteral("userDatabase/username"), normalizedUsername},
        {QStringLiteral("userDatabase/password"), password},
        {QStringLiteral("userDatabase/name"), userDatabaseName.trimmed()},
        {QStringLiteral("businessDatabase/host"), normalizedHost},
        {QStringLiteral("businessDatabase/port"), port},
        {QStringLiteral("businessDatabase/username"), normalizedUsername},
        {QStringLiteral("businessDatabase/password"), password},
        {QStringLiteral("businessDatabase/name"), businessDatabaseName.trimmed()}
    };

    QString error;
    const QString destinationPath = AppConfig::databaseServerConfigPath();
    if (!writeEncryptedConfig(destinationPath, values, &error)) {
        setStatusMessage(error);
        return false;
    }

    AppConfig::setDatabaseServerValues(values);
    emit settingsChanged();
    setStatusMessage(QStringLiteral("已生成并导入加密数据库服务器配置：%1")
                     .arg(QDir::toNativeSeparators(destinationPath)));
    return true;
}

bool ServerConnectionSettings::saveRememberedLogin(const QString &username, const QString &password,
                                                    bool remember)
{
    removeLegacyLoginSettingsFile();
    const QString filePath = rememberedLoginFilePath();
    if (!remember) {
        if (QFileInfo::exists(filePath) && !QFile::remove(filePath))
            return false;
        m_rememberedUsername.clear();
        m_rememberedPassword.clear();
        m_rememberLogin = false;
        emit rememberedLoginChanged();
        return true;
    }

    const QString normalizedUsername = username.trimmed();
    if (normalizedUsername.isEmpty() || password.isEmpty())
        return false;
    if (!QDir().mkpath(AppConfig::configDirectory()))
        return false;

    const QJsonObject object{
        {QStringLiteral("format"), QStringLiteral("qmlProductManager.rememberedLogin.v1")},
        {QStringLiteral("username"), normalizedUsername},
        {QStringLiteral("password"), password}
    };
    QString encryptionError;
    const QByteArray encrypted = protectForCurrentWindowsUser(
        QJsonDocument(object).toJson(QJsonDocument::Compact), &encryptionError);
    if (encrypted.isEmpty()) {
        qWarning().noquote() << encryptionError;
        return false;
    }

    const QByteArray encodedCredentials = encrypted.toBase64();
    QSaveFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)
            || file.write(kRememberedLoginHeader) != kRememberedLoginHeader.size()
            || file.write(encodedCredentials) != encodedCredentials.size()
            || file.write("\n") != 1
            || !file.commit()) {
        return false;
    }

    m_rememberedUsername = normalizedUsername;
    m_rememberedPassword = password;
    m_rememberLogin = true;
    emit rememberedLoginChanged();
    return true;
}

bool ServerConnectionSettings::connectServer()
{
    if (!m_loginManager || !m_tableDisplay) {
        setStatusMessage(QStringLiteral("连接管理器未初始化"));
        return false;
    }

    // QSqlDatabase 已打开时再次 open() 可能直接复用旧会话；先关闭才能保证
    // 保存新地址、端口或账号后执行的是到新服务器的真实重连。
    m_loginManager->disconnectDatabase();
    m_tableDisplay->disconnectDatabase();
    const bool userConnected = m_loginManager->connectDatabase();
    const bool businessConnected = m_tableDisplay->openDatabase();
    refreshConnectionState();

    if (userConnected && businessConnected) {
        setStatusMessage(QStringLiteral("数据库服务器连接成功"));
        return true;
    }

    QStringList errors;
    if (!userConnected)
        errors << QStringLiteral("用户库：%1").arg(m_loginManager->getLastError());
    if (!businessConnected)
        errors << QStringLiteral("业务库：%1").arg(m_tableDisplay->databaseError());
    setStatusMessage(QStringLiteral("连接失败：%1").arg(errors.join(QStringLiteral("；"))));
    return false;
}

void ServerConnectionSettings::disconnectServer()
{
    if (m_loginManager)
        m_loginManager->disconnectDatabase();
    if (m_tableDisplay)
        m_tableDisplay->disconnectDatabase();
    setStatusMessage(QStringLiteral("已断开数据库服务器连接"));
    emit connectionChanged();
}

void ServerConnectionSettings::refreshConnectionState()
{
    emit connectionChanged();
    if (connected())
        setStatusMessage(QStringLiteral("数据库服务器已连接"));
    else if (m_statusMessage.isEmpty() || m_statusMessage == QStringLiteral("数据库服务器已连接"))
        setStatusMessage(QStringLiteral("数据库服务器未连接"));
}

void ServerConnectionSettings::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message)
        return;
    m_statusMessage = message;
    emit statusMessageChanged();
}

bool ServerConnectionSettings::loadRememberedLogin(QString *errorMessage)
{
    removeLegacyLoginSettingsFile();
    m_rememberedUsername.clear();
    m_rememberedPassword.clear();
    m_rememberLogin = false;

    QFile file(rememberedLoginFilePath());
    if (!file.exists())
        return true;
    if (!file.open(QIODevice::ReadOnly)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("无法读取加密登录记住状态文件");
        return false;
    }
    const QByteArray contents = file.readAll();
    if (!contents.startsWith(kRememberedLoginHeader)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("登录记住状态文件格式无效，已忽略");
        return false;
    }

    QString decryptError;
    const QByteArray plainText = unprotectForCurrentWindowsUser(
        QByteArray::fromBase64(contents.mid(kRememberedLoginHeader.size()).trimmed()), &decryptError);
    if (plainText.isEmpty()) {
        if (errorMessage)
            *errorMessage = decryptError;
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(plainText, &parseError);
    const QJsonObject object = document.object();
    if (parseError.error != QJsonParseError::NoError || !document.isObject()
            || object.value(QStringLiteral("format")).toString()
                   != QStringLiteral("qmlProductManager.rememberedLogin.v1")
            || !object.value(QStringLiteral("username")).isString()
            || !object.value(QStringLiteral("password")).isString()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("登录记住状态文件内容无效，已忽略");
        return false;
    }

    m_rememberedUsername = object.value(QStringLiteral("username")).toString();
    m_rememberedPassword = object.value(QStringLiteral("password")).toString();
    m_rememberLogin = !m_rememberedUsername.isEmpty() && !m_rememberedPassword.isEmpty();
    return true;
}

QString ServerConnectionSettings::rememberedLoginFilePath()
{
    return QDir(AppConfig::configDirectory()).filePath(QStringLiteral("login_credentials.enc"));
}

void ServerConnectionSettings::removeLegacyLoginSettingsFile()
{
    // 旧版 login.ini 仅包含 Base64 文本，不能继续保留为可恢复的明文密码副本。
    QFile::remove(QDir(AppConfig::configDirectory()).filePath(QStringLiteral("login.ini")));
}

bool ServerConnectionSettings::readEncryptedConfig(const QString &filePath, QVariantMap *values,
                                                    QString *errorMessage)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("未找到加密数据库服务器配置文件：%1")
                    .arg(QDir::toNativeSeparators(filePath));
        return false;
    }
    const QByteArray contents = file.readAll();
    if (!contents.startsWith(kEncryptedConfigHeader)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("选择的文件不是本程序生成的加密数据库服务器配置文件");
        return false;
    }

    const QByteArray encrypted = QByteArray::fromBase64(contents.mid(kEncryptedConfigHeader.size()).trimmed());
    if (encrypted.isEmpty()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("加密数据库服务器配置文件内容无效");
        return false;
    }

    QString decryptError;
    const QByteArray plainText = unprotectForCurrentWindowsUser(encrypted, &decryptError);
    if (plainText.isEmpty()) {
        if (errorMessage)
            *errorMessage = decryptError;
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(plainText, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("加密配置文件格式无效");
        return false;
    }

    const QJsonObject object = document.object();
    if (object.value(QStringLiteral("format")).toString() != QStringLiteral("qmlProductManager.databaseServer.v1")) {
        if (errorMessage)
            *errorMessage = QStringLiteral("加密配置文件版本不受支持");
        return false;
    }

    QVariantMap parsedValues;
    if (!appendDatabaseValues(object.value(QStringLiteral("userDatabase")).toObject(),
                              QStringLiteral("userDatabase/"), &parsedValues, errorMessage)
            || !appendDatabaseValues(object.value(QStringLiteral("businessDatabase")).toObject(),
                                     QStringLiteral("businessDatabase/"), &parsedValues, errorMessage)
            || !validateValues(parsedValues, errorMessage)) {
        return false;
    }

    if (values)
        *values = parsedValues;
    return true;
}

bool ServerConnectionSettings::writeEncryptedConfig(const QString &filePath, const QVariantMap &values,
                                                     QString *errorMessage)
{
    if (!validateValues(values, errorMessage))
        return false;
    if (!QDir().mkpath(QFileInfo(filePath).absolutePath())) {
        if (errorMessage)
            *errorMessage = QStringLiteral("无法创建配置目录：%1")
                    .arg(QDir::toNativeSeparators(QFileInfo(filePath).absolutePath()));
        return false;
    }

    QJsonObject object{
        {QStringLiteral("format"), QStringLiteral("qmlProductManager.databaseServer.v1")},
        {QStringLiteral("userDatabase"), databaseObjectFromValues(values, QStringLiteral("userDatabase/"))},
        {QStringLiteral("businessDatabase"), databaseObjectFromValues(values, QStringLiteral("businessDatabase/"))}
    };
    QString encryptionError;
    const QByteArray encrypted = protectForCurrentWindowsUser(QJsonDocument(object).toJson(QJsonDocument::Compact),
                                                               &encryptionError);
    if (encrypted.isEmpty()) {
        if (errorMessage)
            *errorMessage = encryptionError;
        return false;
    }

    QSaveFile file(filePath);
    const QByteArray encodedConfig = encrypted.toBase64();
    if (!file.open(QIODevice::WriteOnly)
            || file.write(kEncryptedConfigHeader) != kEncryptedConfigHeader.size()
            || file.write(encodedConfig) != encodedConfig.size()
            || file.write("\n") != 1
            || !file.commit()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("无法保存加密数据库服务器配置文件：%1")
                    .arg(QDir::toNativeSeparators(filePath));
        return false;
    }
    return true;
}

bool ServerConnectionSettings::validateValues(const QVariantMap &values, QString *errorMessage)
{
    const QString host = values.value(QStringLiteral("userDatabase/host")).toString().trimmed();
    const int port = values.value(QStringLiteral("userDatabase/port")).toInt();
    const QString username = values.value(QStringLiteral("userDatabase/username")).toString().trimmed();
    const QString password = values.value(QStringLiteral("userDatabase/password")).toString();
    const QString userDatabaseName = values.value(QStringLiteral("userDatabase/name")).toString().trimmed();
    const QString businessDatabaseName = values.value(QStringLiteral("businessDatabase/name")).toString().trimmed();
    if (host.isEmpty() || username.isEmpty() || password.isEmpty() || userDatabaseName.isEmpty()
            || businessDatabaseName.isEmpty()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("请完整填写服务器地址、账号、密码和两个数据库名称");
        return false;
    }
    if (port < 1 || port > 65535) {
        if (errorMessage)
            *errorMessage = QStringLiteral("端口必须在 1 到 65535 之间");
        return false;
    }
    return true;
}
