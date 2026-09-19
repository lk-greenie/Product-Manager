#include "deepseekclient.h"
#include "appconfig.h"
#include "tabledisplay.h"

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

// 把配置中的 baseUrl 规范化为 DeepSeek 的 chat/completions 端点。
// 空值使用默认端点；裸主机（如 https://api.deepseek.com）补上 /chat/completions；
// 已含完整端点的 URL 原样保留。比较时忽略末尾斜杠。
QString normalizeChatEndpoint(QString url)
{
    url = url.trimmed();
    if (url.isEmpty())
        return QStringLiteral("https://api.deepseek.com/chat/completions");
    while (url.endsWith(QLatin1Char('/')))
        url.chop(1);
    if (!url.endsWith(QStringLiteral("/chat/completions")))
        url += QStringLiteral("/chat/completions");
    return url;
}

// 若对话标题仍为默认“新对话”（或为空），用首条用户消息（约 30 字）作为标题。
void updateConversationTitleIfDefault(qlonglong conversationId, const QString &message)
{
    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
    query.prepare("SELECT title FROM ai_conversations WHERE id=?");
    query.addBindValue(conversationId);
    if (!query.exec() || !query.next())
        return;
    const QString currentTitle = query.value(0).toString();
    if (!currentTitle.isEmpty() && currentTitle != QStringLiteral("新对话"))
        return;

    QString title = message;
    title.replace(QChar::LineFeed, QLatin1Char(' '));
    title.replace(QChar::CarriageReturn, QLatin1Char(' '));
    if (title.size() > 30) {
        title = title.left(30);
        title += QStringLiteral("…");
    }

    QSqlQuery update(QSqlDatabase::database(kUserConnection, false));
    update.prepare("UPDATE ai_conversations SET title=? WHERE id=?");
    update.addBindValue(title);
    update.addBindValue(conversationId);
    update.exec();
}

// 构造一个无参数的 function tool（DeepSeek/OpenAI 兼容格式）。
QJsonObject toolObject(const QString &name, const QString &description)
{
    QJsonObject fn;
    fn.insert("name", name);
    fn.insert("description", description);
    QJsonObject params;
    params.insert("type", "object");
    params.insert("properties", QJsonObject());
    params.insert("required", QJsonArray());
    fn.insert("parameters", params);

    QJsonObject tool;
    tool.insert("type", "function");
    tool.insert("function", fn);
    return tool;
}

// 将 Markdown 表格转换为易于 `Text.MarkdownText` 展示的普通文本：
// 对任何含竖线 | 的行，去掉竖线、丢弃空单元格与“---/---:”等分隔单元格，
// 单元格用两个空格分隔；普通文本行（不含竖线）原样保留。
// 避免 MarkdownText 无法渲染表格时把 | 与 --- 原样显示成乱码。
QString sanitizeForDisplay(QString text)
{
    const QStringList lines = text.split(QLatin1Char('\n'));
    QStringList out;
    out.reserve(lines.size());
    for (const QString &line : lines) {
        const QString trimmed = line.trimmed();
        if (!trimmed.contains(QLatin1Char('|'))) {
            out << line;
            continue;
        }
        // 表格行/分隔行：以 | 拆分，过滤空单元格与纯线条分隔单元格。
        const QStringList rawCells = line.split(QLatin1Char('|'));
        QStringList cells;
        for (const QString &c : rawCells) {
            const QString t = c.trimmed();
            if (t.isEmpty())
                continue;
            bool onlyDash = true;
            for (const QChar &ch : t) {
                if (ch != QLatin1Char('-') && ch != QLatin1Char(':') && !ch.isSpace()) {
                    onlyDash = false;
                    break;
                }
            }
            if (onlyDash)
                continue;
            cells << t;
        }
        out << cells.join(QStringLiteral("  "));
    }
    return out.join(QLatin1Char('\n'));
}
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

void DeepSeekClient::setDataProvider(TableDisplay *provider)
{
    m_dataProvider = provider;
}

void DeepSeekClient::clearMessages()
{
    m_messages.clear();
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

void DeepSeekClient::setBusyStatus(const QString &status)
{
    if (m_busyStatus == status)
        return;
    m_busyStatus = status;
    emit busyStatusChanged();
}

bool DeepSeekClient::ensureTables()
{
    if (!QSqlDatabase::contains(kUserConnection) || !QSqlDatabase::database(kUserConnection, false).isOpen()) {
        setError(QStringLiteral("用户数据库未连接"));
        return false;
    }

    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
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

    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
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

    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
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

    QSqlQuery ownership(QSqlDatabase::database(kUserConnection, false));
    ownership.prepare("SELECT 1 FROM ai_conversations WHERE id=? AND user_id=?");
    ownership.addBindValue(conversationId);
    ownership.addBindValue(m_userId);
    if (!ownership.exec() || !ownership.next()) {
        setError(QStringLiteral("无法访问该对话"));
        return false;
    }

    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
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
    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
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
    QSqlQuery query(QSqlDatabase::database(kUserConnection, false));
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
    const QString baseUrl = normalizeChatEndpoint(
        AppConfig::stringValue(QStringLiteral("ai/baseUrl"),
                               QStringLiteral("https://api.deepseek.com/chat/completions")));
    const QString systemPrompt = AppConfig::stringValue(
        QStringLiteral("ai/systemPrompt"),
        QStringLiteral("你是产品进销存管理系统的小助手，只回答库存、入库、出库、收支记录和数据分析相关问题。回答时请使用简洁易读的中文文本：可用“•”项目符号列表或用“字段：值”分行罗列数据，可用 **加粗** 强调重点；请不要使用 Markdown 表格（不要用竖线|和横线-拼接的表格）、代码块、引用、图片等复杂语法。非相关问题请礼貌说明能力范围。"));

    if (m_busy || message.trimmed().isEmpty() || !loadConversation(conversationId))
        return;
    setBusyStatus(QStringLiteral("读取会话"));
    if (!saveMessage(conversationId, QStringLiteral("user"), message.trimmed()))
        return;
    updateConversationTitleIfDefault(conversationId, message.trimmed());

    auto *userItem = new QStandardItem(message.trimmed());
    userItem->setData(QStringLiteral("user"), Qt::UserRole + 1);
    m_messages.appendRow(userItem);

    const QJsonArray tools = buildTools();

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

    postChat(messages, tools, conversationId, model, baseUrl, apiKey, 0);
}

QJsonArray DeepSeekClient::buildTools() const
{
    QJsonArray tools;
    const int permission = m_dataProvider ? m_dataProvider->currentPermission() : 3;
    if (permission == 3) {
        // 顾客访客：只知道库存管理页面展示的商品信息。
        tools.append(toolObject(QStringLiteral("get_inventory"),
                                QStringLiteral("获取库存商品信息：分类、商品名、生产日期、保质日期、售价、数量。")));
    } else {
        // 店主/店员：知道 warehouse 库全部信息（含所有交易记录）。
        tools.append(toolObject(QStringLiteral("get_categories"),
                                QStringLiteral("获取所有商品分类列表。")));
        tools.append(toolObject(QStringLiteral("get_inventory"),
                                QStringLiteral("获取完整库存数据：分类汇总、商品明细（进价/售价/数量/生产与保质日期/上下限）、低库存提醒。")));
        tools.append(toolObject(QStringLiteral("get_transactions"),
                                QStringLiteral("获取所有交易/收支记录（入库、出库明细）。")));
        tools.append(toolObject(QStringLiteral("get_financial_summary"),
                                QStringLiteral("获取总收入、总支出、净收入汇总。")));
    }
    return tools;
}

QString DeepSeekClient::executeTool(const QString &name) const
{
    if (!m_dataProvider)
        return QStringLiteral("数据查询不可用。");
    if (name == QStringLiteral("get_categories"))
        return m_dataProvider->aiCategories();
    if (name == QStringLiteral("get_inventory"))
        return m_dataProvider->aiInventory();
    if (name == QStringLiteral("get_transactions"))
        return m_dataProvider->aiTransactions();
    if (name == QStringLiteral("get_financial_summary"))
        return m_dataProvider->aiFinancialSummary();
    return QStringLiteral("未知查询。");
}

void DeepSeekClient::postChat(QJsonArray messages, const QJsonArray &tools,
                              qlonglong conversationId, const QString &model,
                              const QString &baseUrl, const QString &apiKey, int round)
{
    if (round > 4) { // 防止工具调用死循环
        setError(QStringLiteral("AI 查询次数过多，请重试。"));
        return;
    }

    QJsonObject payload;
    payload.insert("model", model);
    payload.insert("messages", messages);
    if (!tools.isEmpty())
        payload.insert("tools", tools);
    payload.insert("stream", false); // 函数调用阶段使用非流式，便于稳定解析工具调用

    QNetworkRequest request{QUrl(baseUrl)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QByteArray("Bearer ") + apiKey.toUtf8());

    setBusyStatus(round > 0 ? QStringLiteral("整理查询结果") : QStringLiteral("连接 AI 服务"));
    setBusy(true);
    QNetworkReply *reply = m_network.post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this,
            [this, reply, messages, tools, conversationId, model, baseUrl, apiKey, round]() mutable {
        setBusy(false);
        const QByteArray body = reply->readAll();
        const QNetworkReply::NetworkError error = reply->error();
        reply->deleteLater();
        if (error != QNetworkReply::NoError) {
            setError(QStringLiteral("AI 请求失败，请检查网络或密钥配置。"));
            return;
        }
        const QJsonDocument document = QJsonDocument::fromJson(body);
        const QJsonArray choices = document.object().value("choices").toArray();
        if (choices.isEmpty()) {
            setError(QStringLiteral("AI 服务返回了无效响应。"));
            return;
        }
        QJsonObject message = choices.first().toObject().value("message").toObject();
        const QJsonArray toolCalls = message.value("tool_calls").toArray();
        if (!toolCalls.isEmpty()) {
            // 模型请求调用工具：先把含 tool_calls 的 assistant 消息追加，
            // 再逐个执行并追加 tool 结果，然后继续对话。
            messages.append(message);
            setBusyStatus(QStringLiteral("查询库存与经营数据"));
            for (const QJsonValue &value : toolCalls) {
                const QJsonObject call = value.toObject();
                const QString callId = call.value("id").toString();
                const QString fnName = call.value("function").toObject().value("name").toString();
                const QString result = executeTool(fnName);
                QJsonObject toolMsg;
                toolMsg.insert("role", "tool");
                toolMsg.insert("tool_call_id", callId);
                toolMsg.insert("content", result);
                messages.append(toolMsg);
            }
            postChat(messages, tools, conversationId, model, baseUrl, apiKey, round + 1);
            return;
        }

        const QString answer = sanitizeForDisplay(message.value("content").toString().trimmed());
        if (answer.isEmpty() || !saveMessage(conversationId, QStringLiteral("assistant"), answer))
            return;
        auto *assistantItem = new QStandardItem(answer);
        assistantItem->setData(QStringLiteral("assistant"), Qt::UserRole + 1);
        m_messages.appendRow(assistantItem);
        refreshConversations();
        emit responseReceived();
        setBusyStatus(QStringLiteral("准备处理"));
    });
}
