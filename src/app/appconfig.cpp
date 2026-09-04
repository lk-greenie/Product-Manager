#include "appconfig.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QSettings>

namespace {
QString s_filePath;
QString s_errorMessage;
bool s_loaded = false;

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

QString AppConfig::stringValue(const QString &key, const QString &defaultValue)
{
    if (!s_loaded)
        return defaultValue;

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

QString AppConfig::resolveFilePath()
{
    const QString configuredPath = qEnvironmentVariable("QML_PRODUCT_MANAGER_CONFIG").trimmed();
    if (!configuredPath.isEmpty())
        return QDir::cleanPath(configuredPath);

    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("config/app.ini"));
}
