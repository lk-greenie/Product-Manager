#ifndef APPCONFIG_H
#define APPCONFIG_H

#include <QString>
#include <QVariantMap>

class AppConfig
{
public:
    static void load();
    static bool isLoaded();
    static QString errorMessage();
    static QString filePath();
    static QString configDirectory();
    static QString databaseServerConfigPath();
    static QString stringValue(const QString &key, const QString &defaultValue = QString());
    static int intValue(const QString &key, int defaultValue = 0);
    static bool boolValue(const QString &key, bool defaultValue = false);
    // 将运行时设置持久化到当前外部 INI 配置文件，不在代码中保存服务器地址。
    static bool setValues(const QVariantMap &values, QString *errorMessage = nullptr);
    // 数据库服务器信息只在加密配置文件中保存；解密后仅覆盖当前进程的运行时配置。
    static void setDatabaseServerValues(const QVariantMap &values);
    static bool hasDatabaseServerConfig();

private:
    static QString resolveFilePath();
};

#endif // APPCONFIG_H
