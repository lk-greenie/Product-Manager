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

QString AppConfig::resolveFilePath()
{
    const QString configuredPath = qEnvironmentVariable("QML_PRODUCT_MANAGER_CONFIG").trimmed();
    if (!configuredPath.isEmpty())
        return QDir::cleanPath(configuredPath);

    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("config/app.ini"));
}
