#include "appconfig.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QSettings>

namespace {
QString s_filePath;
QString s_errorMessage;
bool s_loaded = false;
QVariantMap s_databaseServerValues;

bool isDatabaseServerKey(const QString &key)
{
    return key == QStringLiteral("userDatabase/host")
            || key == QStringLiteral("userDatabase/port")
            || key == QStringLiteral("userDatabase/username")
            || key == QStringLiteral("userDatabase/password")
            || key == QStringLiteral("userDatabase/name")
            || key == QStringLiteral("businessDatabase/host")
            || key == QStringLiteral("businessDatabase/port")
            || key == QStringLiteral("businessDatabase/username")
            || key == QStringLiteral("businessDatabase/password")
            || key == QStringLiteral("businessDatabase/name");
}

QSettings settings()
{
    return QSettings(s_filePath, QSettings::IniFormat);
}
}

void AppConfig::load()
{
    s_filePath = resolveFilePath();
    s_errorMessage.clear();
    s_loaded = false;
    s_databaseServerValues.clear();

    const QFileInfo configFile(s_filePath);
    if (!configFile.exists()) {
        s_errorMessage = QStringLiteral("未找到配置文件：%1。请复制 app.ini.example 为 app.ini，或设置 QML_PRODUCT_MANAGER_CONFIG。")
                             .arg(QDir::toNativeSeparators(s_filePath));
        return;
    }

    QSettings config(s_filePath, QSettings::IniFormat);
    if (config.status() != QSettings::NoError) {
        s_errorMessage = QStringLiteral("无法读取配置文件：%1").arg(QDir::toNativeSeparators(s_filePath));
        return;
    }

    s_loaded = true;
}

bool AppConfig::isLoaded()
{
    return s_loaded;
}

QString AppConfig::errorMessage()
{
    return s_errorMessage;
}

QString AppConfig::filePath()
{
    return s_filePath;
}

QString AppConfig::configDirectory()
{
    if (!s_filePath.isEmpty())
        return QFileInfo(s_filePath).absolutePath();
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("config"));
}

QString AppConfig::databaseServerConfigPath()
{
    return QDir(configDirectory()).filePath(QStringLiteral("database_server_config.enc"));
}

QString AppConfig::stringValue(const QString &key, const QString &defaultValue)
{
    if (!s_loaded)
        return defaultValue;

    // 服务器凭据不再从 app.ini 回退读取，避免旧版明文配置继续被使用。
    if (isDatabaseServerKey(key))
        return s_databaseServerValues.value(key, defaultValue).toString().trimmed();

    QSettings config = settings();
    return config.value(key, defaultValue).toString().trimmed();
}

int AppConfig::intValue(const QString &key, int defaultValue)
{
    if (!s_loaded)
        return defaultValue;

    bool ok = false;
    const int value = stringValue(key).toInt(&ok);
    return ok ? value : defaultValue;
}

bool AppConfig::boolValue(const QString &key, bool defaultValue)
{
    if (!s_loaded)
        return defaultValue;

    QSettings config = settings();
    return config.value(key, defaultValue).toBool();
}

bool AppConfig::setValues(const QVariantMap &values, QString *errorMessage)
{
    if (!s_loaded) {
        if (errorMessage)
            *errorMessage = s_errorMessage.isEmpty()
                    ? QStringLiteral("配置文件尚未加载") : s_errorMessage;
        return false;
    }

    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        if (isDatabaseServerKey(it.key())) {
            if (errorMessage)
                *errorMessage = QStringLiteral("数据库服务器信息必须通过加密配置文件管理");
            return false;
        }
    }

    QSettings config(s_filePath, QSettings::IniFormat);
    for (auto it = values.cbegin(); it != values.cend(); ++it)
        config.setValue(it.key(), it.value());
    config.sync();
    if (config.status() != QSettings::NoError) {
        if (errorMessage)
            *errorMessage = QStringLiteral("保存配置文件失败：%1")
                    .arg(QDir::toNativeSeparators(s_filePath));
        return false;
    }
    return true;
}

void AppConfig::setDatabaseServerValues(const QVariantMap &values)
{
    s_databaseServerValues = values;
}

bool AppConfig::hasDatabaseServerConfig()
{
    return !s_databaseServerValues.isEmpty();
}

QString AppConfig::resolveFilePath()
{
    const QString configuredPath = qEnvironmentVariable("QML_PRODUCT_MANAGER_CONFIG").trimmed();
    if (!configuredPath.isEmpty()) {
        const QFileInfo configuredFile(QDir::cleanPath(configuredPath));
        // 即使使用环境变量覆盖，也要求配置文件位于名为 config 的目录中。
        if (configuredFile.dir().dirName().compare(QStringLiteral("config"), Qt::CaseInsensitive) == 0)
            return configuredFile.absoluteFilePath();
    }

    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("config/app.ini"));
}
