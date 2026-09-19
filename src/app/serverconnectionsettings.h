#ifndef SERVERCONNECTIONSETTINGS_H
#define SERVERCONNECTIONSETTINGS_H

#include <QObject>
#include <QUrl>
#include <QVariant>

class Enter;
class TableDisplay;

// 统一管理用户库和业务库共用的服务器地址与连接状态。
class ServerConnectionSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString encryptedConfigPath READ encryptedConfigPath NOTIFY settingsChanged)
    Q_PROPERTY(QString rememberedUsername READ rememberedUsername NOTIFY rememberedLoginChanged)
    Q_PROPERTY(QString rememberedPassword READ rememberedPassword NOTIFY rememberedLoginChanged)
    Q_PROPERTY(bool rememberLogin READ rememberLogin NOTIFY rememberedLoginChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit ServerConnectionSettings(Enter *loginManager, TableDisplay *tableDisplay,
                                      QObject *parent = nullptr);

    static bool importDefaultEncryptedConfig(QString *errorMessage = nullptr);

    QString encryptedConfigPath() const;
    QString rememberedUsername() const;
    QString rememberedPassword() const;
    bool rememberLogin() const;
    bool connected() const;
    QString statusMessage() const;

    Q_INVOKABLE bool importEncryptedConfig(const QUrl &fileUrl);
    Q_INVOKABLE bool generateEncryptedConfig(const QString &host, int port,
                                             const QString &username, const QString &password,
                                             const QString &userDatabaseName,
                                             const QString &businessDatabaseName);
    Q_INVOKABLE bool saveRememberedLogin(const QString &username, const QString &password,
                                         bool remember);
    Q_INVOKABLE bool connectServer();
    Q_INVOKABLE void disconnectServer();
    Q_INVOKABLE void refreshConnectionState();

signals:
    void settingsChanged();
    void rememberedLoginChanged();
    void connectionChanged();
    void statusMessageChanged();

private:
    static bool readEncryptedConfig(const QString &filePath, QVariantMap *values,
                                    QString *errorMessage);
    static bool writeEncryptedConfig(const QString &filePath, const QVariantMap &values,
                                     QString *errorMessage);
    static bool validateValues(const QVariantMap &values, QString *errorMessage);
    bool loadRememberedLogin(QString *errorMessage = nullptr);
    static QString rememberedLoginFilePath();
    static void removeLegacyLoginSettingsFile();
    void setStatusMessage(const QString &message);

    Enter *m_loginManager = nullptr;
    TableDisplay *m_tableDisplay = nullptr;
    QString m_statusMessage;
    QString m_rememberedUsername;
    QString m_rememberedPassword;
    bool m_rememberLogin = false;
};

#endif // SERVERCONNECTIONSETTINGS_H
