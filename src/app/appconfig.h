#ifndef APPCONFIG_H
#define APPCONFIG_H

#include <QString>

class AppConfig
{
public:
    static void load();
    static bool isLoaded();
    static QString errorMessage();
    static QString filePath();
    static QString stringValue(const QString &key, const QString &defaultValue = QString());
    static int intValue(const QString &key, int defaultValue = 0);
    static bool boolValue(const QString &key, bool defaultValue = false);

private:
    static QString resolveFilePath();
};

#endif // APPCONFIG_H
