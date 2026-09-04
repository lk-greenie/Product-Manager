#ifndef DEEPSEEKCLIENT_H
#define DEEPSEEKCLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QStandardItemModel>
#include <QJsonArray>
#include <QJsonObject>

class TableDisplay;

class DeepSeekClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString busyStatus READ busyStatus NOTIFY busyStatusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorOccurred)
    Q_PROPERTY(QStandardItemModel *conversationsModel READ conversationsModel CONSTANT)
    Q_PROPERTY(QStandardItemModel *messagesModel READ messagesModel CONSTANT)

public:
    explicit DeepSeekClient(QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    QString lastError() const { return m_lastError; }
    QString busyStatus() const { return m_busyStatus; }
    QStandardItemModel *conversationsModel() { return &m_conversations; }
    QStandardItemModel *messagesModel() { return &m_messages; }

    // 注入业务数据提供者，向 AI 提供按需查询数据库的能力（函数调用）。
    void setDataProvider(TableDisplay *provider);
    // 清空当前消息列表（用于取消选中对话）。（QML 调用，需 Q_INVOKABLE）
    Q_INVOKABLE void clearMessages();

    Q_INVOKABLE void setCurrentUser(int userId);
    Q_INVOKABLE qlonglong createConversation(const QString &title = QString());
    Q_INVOKABLE bool loadConversation(qlonglong conversationId);
    Q_INVOKABLE bool deleteConversation(qlonglong conversationId);
    Q_INVOKABLE void sendMessage(qlonglong conversationId, const QString &message);
    // 供 QML 读取最近会话，避免直接依赖模型 rowCount/index 的 QML 访问语义。
    Q_INVOKABLE int conversationCount() const { return m_conversations.rowCount(); }
    Q_INVOKABLE qlonglong latestConversationId() const {
        return m_conversations.rowCount() > 0
                   ? m_conversations.item(0)->data(Qt::UserRole + 1).toLongLong()
                   : 0;
    }

signals:
    void busyChanged();
    void busyStatusChanged();
    void errorOccurred();
    void responseReceived();
    void conversationsChanged();

private:
    bool ensureTables();
    bool saveMessage(qlonglong conversationId, const QString &role, const QString &content);
    void refreshConversations();
    void setError(const QString &error);
    void setBusy(bool busy);
    void setBusyStatus(const QString &status);

    // —— AI 函数调用（工具）支持 ——
    QJsonArray buildTools() const;
    QString executeTool(const QString &name) const;
    void postChat(QJsonArray messages, const QJsonArray &tools,
                  qlonglong conversationId, const QString &model,
                  const QString &baseUrl, const QString &apiKey, int round);

    QNetworkAccessManager m_network;
    QStandardItemModel m_conversations;
    QStandardItemModel m_messages;
    TableDisplay *m_dataProvider = nullptr;
    int m_userId = 0;
    bool m_busy = false;
    QString m_lastError;
    QString m_busyStatus = QStringLiteral("准备处理");
};

#endif
