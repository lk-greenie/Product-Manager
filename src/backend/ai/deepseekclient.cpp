#include "deepseekclient.h"
#include "appconfig.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardItem>

namespace {
const QString kUserConnection = QStringLiteral("user_management_connection");
}

DeepSeekClient::DeepSeekClient(QObject *parent)
    : QObject(parent)
{
    m_conversations.setColumnCount(1);
    m_conversations.setItemRoleNames({{Qt::DisplayRole, "display"}, {Qt::UserRole + 1, "conversationId"}});
    m_messages.setColumnCount(1);
    m_messages.setItemRoleNames({{Qt::DisplayRole, "display"}, {Qt::UserRole + 1, "role"}});
}

void DeepSeekClient::setCurrentUser(int userId)
{
    m_userId = userId;
    m_messages.clear();
    refreshConversations();
}

void DeepSeekClient::setError(const QString &error)
{
    m_lastError = error;
    emit errorOccurred();
}

void DeepSeekClient::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

bool DeepSeekClient::ensureTables()
{
    if (!QSqlDatabase::contains(kUserConnection) || !QSqlDatabase::database(kUserConnection).isOpen()) {
        setError(QStringLiteral("用户数据库未连接"));
        return false;
    }

    QSqlQuery query(QSqlDatabase::database(kUserConnection));
    if (!query.exec("CREATE TABLE IF NOT EXISTS ai_conversations ("
                    "id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, "
                    "title VARCHAR(100) NOT NULL DEFAULT '新对话', "
                    "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
                    "updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
                    "CONSTRAINT fk_conversations_user FOREIGN KEY (user_id) "
                    "REFERENCES users(id) ON DELETE CASCADE)")) {
        setError(query.lastError().text());
        return false;
    }
    if (!query.exec("CREATE TABLE IF NOT EXISTS ai_messages ("
                    "id BIGINT AUTO_INCREMENT PRIMARY KEY, conversation_id BIGINT NOT NULL, "
                    "role ENUM('user', 'assistant', 'system') NOT NULL, content TEXT NOT NULL, "
                    "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
                    "CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) "
                    "REFERENCES ai_conversations(id) ON DELETE CASCADE)")) {
        setError(query.lastError().text());
        return false;
    }
    return true;
}

void DeepSeekClient::refreshConversations()
{
    m_conversations.clear();
    if (!ensureTables() || m_userId <= 0)
        return;

    QSqlQuery query(QSqlDatabase::database(kUserConnection));
    query.prepare("SELECT id, title FROM ai_conversations WHERE user_id=? ORDER BY updated_at DESC");
    query.addBindValue(m_userId);
    if (!query.exec()) {
        setError(query.lastError().text());
        return;
    }
    while (query.next()) {
        auto *item = new QStandardItem(query.value(1).toString());
        item->setData(query.value(0), Qt::UserRole + 1);
        m_conversations.appendRow(item);
    }
    emit conversationsChanged();
}

qlonglong DeepSeekClient::createConversation(const QString &title)
{
    if (!ensureTables() || m_userId <= 0) {
        setError(QStringLiteral("请先登录后再创建对话"));
        return 0;
    }

    QSqlQuery query(QSqlDatabase::database(kUserConnection));
    query.prepare("INSERT INTO ai_conversations(user_id,title) VALUES(?,?)");
    query.addBindValue(m_userId);
    query.addBindValue(title.trimmed().isEmpty() ? QStringLiteral("新对话") : title.trimmed());
    if (!query.exec()) {
        setError(query.lastError().text());
        return 0;
    }
    const qlonglong id = query.lastInsertId().toLongLong();
    refreshConversations();
    return id;
}

bool DeepSeekClient::loadConversation(qlonglong conversationId)
{
    m_messages.clear();
    if (!ensureTables() || m_userId <= 0)
        return false;

    QSqlQuery ownership(QSqlDatabase::database(kUserConnection));
    ownership.prepare("SELECT 1 FROM ai_conversations WHERE id=? AND user_id=?");
    ownership.addBindValue(conversationId);
    ownership.addBindValue(m_userId);
    if (!ownership.exec() || !ownership.next()) {
        setError(QStringLiteral("无法访问该对话"));
        return false;
    }

    QSqlQuery query(QSqlDatabase::database(kUserConnection));
    query.prepare("SELECT role, content FROM ai_messages WHERE conversation_id=? ORDER BY id");
    query.addBindValue(conversationId);
    if (!query.exec()) {
        setError(query.lastError().text());
        return false;
    }
    while (query.next()) {
        auto *item = new QStandardItem(query.value(1).toString());
        item->setData(query.value(0).toString(), Qt::UserRole + 1);
        m_messages.appendRow(item);
    }
    return true;
}

bool DeepSeekClient::deleteConversation(qlonglong conversationId)
{
    if (!ensureTables() || m_userId <= 0)
        return false;
    QSqlQuery query(QSqlDatabase::database(kUserConnection));
    query.prepare("DELETE FROM ai_conversations WHERE id=? AND user_id=?");
    query.addBindValue(conversationId);
    query.addBindValue(m_userId);
    if (!query.exec()) {
        setError(query.lastError().text());
        return false;
    }
    m_messages.clear();
    refreshConversations();
    return true;
}

bool DeepSeekClient::saveMessage(qlonglong conversationId, const QString &role, const QString &content)
{
    QSqlQuery query(QSqlDatabase::database(kUserConnection));
    query.prepare("INSERT INTO ai_messages(conversation_id,role,content) VALUES(?,?,?)");
    query.addBindValue(conversationId);
    query.addBindValue(role);
    query.addBindValue(content);
    if (!query.exec()) {
        setError(query.lastError().text());
        return false;
    }
    query.prepare("UPDATE ai_conversations SET updated_at=CURRENT_TIMESTAMP WHERE id=?");
    query.addBindValue(conversationId);
    query.exec();
    return true;
}

void DeepSeekClient::sendMessage(qlonglong conversationId, const QString &message)
{
    const QString apiKey = AppConfig::stringValue(QStringLiteral("ai/apiKey"));
    if (apiKey.isEmpty()) {
        setError(QStringLiteral("请在配置文件中设置 ai/apiKey"));
        return;
    }
    const QString model = AppConfig::stringValue(QStringLiteral("ai/model"),
                                                 QStringLiteral("deepseek-chat"));
    const QString baseUrl = AppConfig::stringValue(QStringLiteral("ai/baseUrl"),
                                                   QStringLiteral("https://api.deepseek.com/chat/completions"));
    const QString systemPrompt = AppConfig::stringValue(
        QStringLiteral("ai/systemPrompt"),
        QStringLiteral("你是产品进销存管理系统的小助手，只回答库存、入库、出库、收支记录和数据分析相关问题。非相关问题请礼貌说明能力范围。"));
    const bool stream = AppConfig::boolValue(QStringLiteral("ai/stream"), false);

    if (m_busy || message.trimmed().isEmpty() || !loadConversation(conversationId))
        return;
    if (!saveMessage(conversationId, QStringLiteral("user"), message.trimmed()))
        return;

    auto *userItem = new QStandardItem(message.trimmed());
    userItem->setData(QStringLiteral("user"), Qt::UserRole + 1);
    m_messages.appendRow(userItem);

    QJsonArray messages;
    QJsonObject system;
    system.insert("role", "system");
    system.insert("content", systemPrompt);
    messages.append(system);
    for (int row = 0; row < m_messages.rowCount(); ++row) {
        const QModelIndex index = m_messages.index(row, 0);
        QJsonObject entry;
        entry.insert("role", m_messages.data(index, Qt::UserRole + 1).toString());
        entry.insert("content", m_messages.data(index).toString());
        messages.append(entry);
    }

    QJsonObject payload;
    payload.insert("model", model);
    payload.insert("messages", messages);
    payload.insert("stream", stream);

    QNetworkRequest request{QUrl(baseUrl)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QByteArray("Bearer ") + apiKey.toUtf8());

    setBusy(true);
    QNetworkReply *reply = m_network.post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, conversationId] {
        setBusy(false);
        const QByteArray body = reply->readAll();
        const QNetworkReply::NetworkError error = reply->error();
        reply->deleteLater();
        if (error != QNetworkReply::NoError) {
            setError(QStringLiteral("AI 请求失败，请检查网络或密钥配置"));
            return;
        }
        const QJsonDocument document = QJsonDocument::fromJson(body);
        const QJsonArray choices = document.object().value("choices").toArray();
        if (choices.isEmpty()) {
            setError(QStringLiteral("AI 服务返回了无效响应"));
            return;
        }
        const QString answer = choices.first().toObject().value("message").toObject().value("content").toString().trimmed();
        if (answer.isEmpty() || !saveMessage(conversationId, QStringLiteral("assistant"), answer))
            return;
        auto *assistantItem = new QStandardItem(answer);
        assistantItem->setData(QStringLiteral("assistant"), Qt::UserRole + 1);
        m_messages.appendRow(assistantItem);
        refreshConversations();
        emit responseReceived();
    });
}
