#include "serverconnectionsettings.h"

#include "appconfig.h"
#include "enter.h"
#include "tabledisplay.h"

#include <QStringList>

ServerConnectionSettings::ServerConnectionSettings(Enter *loginManager,
                                                   TableDisplay *tableDisplay,
                                                   QObject *parent)
    : QObject(parent), m_loginManager(loginManager), m_tableDisplay(tableDisplay)
{
    m_statusMessage = connected()
            ? QStringLiteral("数据库服务器已连接")
            : QStringLiteral("数据库服务器未连接，可修改地址后手动连接");
}

QString ServerConnectionSettings::host() const
{
    return AppConfig::stringValue(QStringLiteral("userDatabase/host"));
}

int ServerConnectionSettings::port() const
{
    return AppConfig::intValue(QStringLiteral("userDatabase/port"));
}

QString ServerConnectionSettings::username() const
{
    return AppConfig::stringValue(QStringLiteral("userDatabase/username"));
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

bool ServerConnectionSettings::saveSettings(const QString &hostValue, int portValue,
                                            const QString &usernameValue,
                                            const QString &passwordValue)
{
    const QString normalizedHost = hostValue.trimmed();
    const QString normalizedUsername = usernameValue.trimmed();
    if (normalizedHost.isEmpty()) {
        setStatusMessage(QStringLiteral("请输入数据库服务器地址"));
        return false;
    }
    if (portValue < 1 || portValue > 65535) {
        setStatusMessage(QStringLiteral("端口必须在 1 到 65535 之间"));
        return false;
    }
    if (normalizedUsername.isEmpty()) {
        setStatusMessage(QStringLiteral("请输入数据库服务器账号"));
        return false;
    }

    QString error;
    QVariantMap values{
        {QStringLiteral("userDatabase/host"), normalizedHost},
        {QStringLiteral("userDatabase/port"), portValue},
        {QStringLiteral("userDatabase/username"), normalizedUsername},
        {QStringLiteral("businessDatabase/host"), normalizedHost},
        {QStringLiteral("businessDatabase/port"), portValue},
        {QStringLiteral("businessDatabase/username"), normalizedUsername}
    };
    // 密码框为空时保留原配置，避免在仅修改地址或端口时意外清空密码。
    if (!passwordValue.isEmpty()) {
        values.insert(QStringLiteral("userDatabase/password"), passwordValue);
        values.insert(QStringLiteral("businessDatabase/password"), passwordValue);
    }
    if (!AppConfig::setValues(values, &error)) {
        setStatusMessage(error);
        return false;
    }

    emit settingsChanged();
    setStatusMessage(QStringLiteral("服务器地址已保存到配置文件"));
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
