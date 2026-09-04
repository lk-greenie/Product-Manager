#ifndef SERVERCONNECTIONSETTINGS_H
#define SERVERCONNECTIONSETTINGS_H

#include <QObject>

class Enter;
class TableDisplay;

// 统一管理用户库和业务库共用的服务器地址与连接状态。
class ServerConnectionSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString host READ host NOTIFY settingsChanged)
    Q_PROPERTY(int port READ port NOTIFY settingsChanged)
    Q_PROPERTY(QString username READ username NOTIFY settingsChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit ServerConnectionSettings(Enter *loginManager, TableDisplay *tableDisplay,
                                      QObject *parent = nullptr);

    QString host() const;
    int port() const;
    QString username() const;
    bool connected() const;
    QString statusMessage() const;

    Q_INVOKABLE bool saveSettings(const QString &host, int port, const QString &username,
                                  const QString &password);
    Q_INVOKABLE bool connectServer();
    Q_INVOKABLE void disconnectServer();
    Q_INVOKABLE void refreshConnectionState();

signals:
    void settingsChanged();
    void connectionChanged();
    void statusMessageChanged();

private:
    void setStatusMessage(const QString &message);

    Enter *m_loginManager = nullptr;
    TableDisplay *m_tableDisplay = nullptr;
    QString m_statusMessage;
};

#endif // SERVERCONNECTIONSETTINGS_H
