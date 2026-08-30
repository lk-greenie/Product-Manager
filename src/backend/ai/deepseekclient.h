#ifndef DEEPSEEKCLIENT_H
#define DEEPSEEKCLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QStandardItemModel>

class DeepSeekClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorOccurred)
    Q_PROPERTY(QStandardItemModel *conversationsModel READ conversationsModel CONSTANT)
    Q_PROPERTY(QStandardItemModel *messagesModel READ messagesModel CONSTANT)

public:
    explicit DeepSeekClient(QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    QString lastError() const { return m_lastError; }
    QStandardItemModel *conversationsModel() { return &m_conversations; }
    QStandardItemModel *messagesModel() { return &m_messages; }

    Q_INVOKABLE void setCurrentUser(int userId);
    Q_INVOKABLE qlonglong createConversation(const QString &title = QString());
    Q_INVOKABLE bool loadConversation(qlonglong conversationId);
    Q_INVOKABLE bool deleteConversation(qlonglong conversationId);
    Q_INVOKABLE void sendMessage(qlonglong conversationId, const QString &message);

signals:
    void busyChanged();
    void errorOccurred();
    void responseReceived();
    void conversationsChanged();

private:
    bool ensureTables();
    bool saveMessage(qlonglong conversationId, const QString &role, const QString &content);
    void refreshConversations();
    void setError(const QString &error);
    void setBusy(bool busy);

    QNetworkAccessManager m_network;
    QStandardItemModel m_conversations;
    QStandardItemModel m_messages;
    int m_userId = 0;
    bool m_busy = false;
    QString m_lastError;
};

#endif
