#include "enter.h"
#include "appconfig.h"

#include <QDebug>
#include <QStringList>
#include <QVariantList>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardItem>

namespace {
const QString kConnectionName = QStringLiteral("user_management_connection");

bool isPlaceholderValue(const QString &value)
{
    return value.startsWith(QStringLiteral("请填写"));
}

bool createDatabaseIfMissing(const QString &driver, const QString &host, int port,
                            const QString &databaseName, const QString &username,
                            const QString &password, QString *error)
{
    const QString adminName = QStringLiteral("user_management_admin_connection");
    QSqlDatabase admin = QSqlDatabase::addDatabase(driver, adminName);
    admin.setHostName(host);
    admin.setPort(port);
    admin.setUserName(username);
    admin.setPassword(password);
    if (!admin.open()) {
        if (error) *error = admin.lastError().text();
        QSqlDatabase::removeDatabase(adminName);
        return false;
    }
    QString identifier = databaseName;
    {
        QSqlQuery query(admin);
        if (!query.exec(QStringLiteral("CREATE DATABASE IF NOT EXISTS `%1` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
                            .arg(identifier.replace('`', "``")))) {
            if (error) *error = query.lastError().text();
            admin.close();
            admin = QSqlDatabase();
            QSqlDatabase::removeDatabase(adminName);
            return false;
        }
    }
    admin.close();
    admin = QSqlDatabase();
    QSqlDatabase::removeDatabase(adminName);
    return true;
}

bool ensureUserTables(QSqlDatabase db, QString *error)
{
    QSqlQuery query(db);
    const QStringList statements = {
        QStringLiteral("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50) NOT NULL UNIQUE, password_hash VARCHAR(255) NOT NULL, email VARCHAR(100), permission TINYINT NOT NULL DEFAULT 3, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS ai_conversations (id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, title VARCHAR(100) NOT NULL DEFAULT '新对话', created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, CONSTRAINT fk_conversations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE)"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS ai_messages (id BIGINT AUTO_INCREMENT PRIMARY KEY, conversation_id BIGINT NOT NULL, role ENUM('user','assistant','system') NOT NULL, content TEXT NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id) ON DELETE CASCADE)")
    };
    for (const QString &sql : statements) {
        if (!query.exec(sql)) {
            if (error) *error = query.lastError().text();
            return false;
        }
    }
    return true;
}

bool ensureDefaultOwner(QSqlDatabase db, QString *error)
{
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM users")) || !query.next()) {
        if (error)
            *error = query.lastError().text();
        return false;
    }
    if (query.value(0).toInt() > 0)
        return true;

    query.prepare(QStringLiteral(
        "INSERT INTO users(username, password_hash, email, permission) VALUES(?, ?, ?, 1)"));
    query.addBindValue(QStringLiteral("admin"));
    query.addBindValue(QString(QCryptographicHash::hash(QByteArrayLiteral("1"),
                                                        QCryptographicHash::Sha256).toHex()));
    query.addBindValue(QStringLiteral("admin@warehouse.local"));
    if (!query.exec()) {
        if (error)
            *error = query.lastError().text();
        return false;
    }
    return true;
}
}



Enter::Enter(QObject *parent) : QObject(parent)
{
    m_users.setColumnCount(1);
    m_users.setItemRoleNames({
        {Qt::DisplayRole, "display"},
        {Qt::UserRole + 1, "userId"},
        {Qt::UserRole + 2, "email"},
        {Qt::UserRole + 3, "permission"},
        {Qt::UserRole + 4, "roleName"}
    });
    if (!openDatabase())
        qWarning().noquote() << QStringLiteral("无法打开用户数据库：") << m_lastError;
}

Enter::~Enter()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
    // 先让本地副本失效再移除，否则 removeDatabase 时副本仍计入引用计数
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(kConnectionName);
}


bool Enter::openDatabase()
{
    if (!AppConfig::isLoaded()) {
        m_lastError = AppConfig::errorMessage();
        return false;
    }

    const QString driver = AppConfig::stringValue(QStringLiteral("userDatabase/driver"),
                                                  QStringLiteral("QMYSQL"));
    const QString host = AppConfig::stringValue(QStringLiteral("userDatabase/host"));
    const int port = AppConfig::intValue(QStringLiteral("userDatabase/port"));
    const QString databaseName = AppConfig::stringValue(QStringLiteral("userDatabase/name"),
                                                         QStringLiteral("user_management"));
    const QString username = AppConfig::stringValue(QStringLiteral("userDatabase/username"),
                                                    QStringLiteral("root"));
    const QString password = AppConfig::stringValue(QStringLiteral("userDatabase/password"));
    if (host.isEmpty() || port < 1 || port > 65535) {
        m_lastError = QStringLiteral("请先在配置文件中填写有效的 userDatabase/host 和 userDatabase/port");
        return false;
    }
    if (isPlaceholderValue(password)) {
        m_lastError = QStringLiteral("请先在配置文件中填写 userDatabase/password");
        return false;
    }

    if (QSqlDatabase::contains(kConnectionName)) {
        m_db = QSqlDatabase::database(kConnectionName);
    } else {
        m_db = QSqlDatabase::addDatabase(driver, kConnectionName);
    }
    m_db.setHostName(host);
    m_db.setPort(port);
    m_db.setDatabaseName(databaseName);
    m_db.setUserName(username);
    m_db.setPassword(password);

    if (!m_db.open()) {
        QString createError;
        m_db.close();
        if (!createDatabaseIfMissing(driver, host, port, databaseName, username, password, &createError)) {
            m_lastError = QStringLiteral("无法连接或创建用户数据库：%1").arg(createError);
            qWarning().noquote() << m_lastError;
            return false;
        }
        if (!m_db.open()) {
            m_lastError = QStringLiteral("无法打开用户数据库：%1").arg(m_db.lastError().text());
            return false;
        }
    }

    QString tableError;
    if (!ensureUserTables(m_db, &tableError)) {
        m_lastError = QStringLiteral("初始化用户数据库表失败：%1").arg(tableError);
        return false;
    }
    if (!ensureDefaultOwner(m_db, &tableError)) {
        m_lastError = QStringLiteral("初始化默认店主账户失败：%1").arg(tableError);
        return false;
    }
    m_lastError.clear();
    return true;
}

bool Enter::connectDatabase()
{
    return openDatabase();
}

void Enter::disconnectDatabase()
{
    if (m_db.isOpen())
        m_db.close();
}

bool Enter::registerUser(const QString &username, const QString &password, const QString &email)
{
    if (username.isEmpty() || password.isEmpty()) {
        m_lastError = "用户名和密码不能为空！";
        return false;
    }

    if (!QSqlDatabase::contains(kConnectionName)) {
        m_lastError = "用户数据库连接不存在！";
        return false;
    }
    QSqlDatabase activeDb = QSqlDatabase::database(kConnectionName);
    if (!activeDb.isOpen()) {
        m_lastError = "用户数据库未打开！";
        return false;
    }

    QSqlQuery checkQuery(activeDb);
    checkQuery.prepare("SELECT id FROM users WHERE username = ?");
    checkQuery.addBindValue(username);
    if (!checkQuery.exec()) {
        m_lastError = checkQuery.lastError().text();
        return false;
    }
    if (checkQuery.next()) {
        m_lastError = "用户已存在！";
        return false;
    }

    QSqlQuery insertQuery(activeDb);
    insertQuery.prepare("INSERT INTO users (username, password_hash, email, permission) VALUES (?, ?, ?, ?)");
    insertQuery.addBindValue(username);
    insertQuery.addBindValue(hashPassword(password));
    insertQuery.addBindValue(email);
    insertQuery.addBindValue(3);
    if (!insertQuery.exec()) {
        m_lastError = insertQuery.lastError().text();
        return false;
    }
    m_lastError.clear();
    return true;
}

bool Enter::loginUser(const QString &username, const QString &password)
{
    if (username.isEmpty() || password.isEmpty()) {
        m_lastError = "用户名和密码不能为空！";
        return false;
    }

    if (!QSqlDatabase::contains(kConnectionName)) {
        m_lastError = "用户数据库连接不存在！";
        return false;
    }
    QSqlDatabase activeDb = QSqlDatabase::database(kConnectionName);
    if (!activeDb.isOpen()) {
        m_lastError = "用户数据库未打开！";
        return false;
    }

    QSqlQuery query(activeDb);
    query.prepare("SELECT id, username, email, password_hash, permission FROM users WHERE username = ?");
    query.addBindValue(username);
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return false;
    }
    if (!query.next()) {
        m_lastError = "用户不存在！";
        return false;
    }
    if (query.value(3).toString() != hashPassword(password)) {
        m_lastError = "密码错误！";
        return false;
    }

    m_userId = query.value(0).toInt();
    m_username = query.value(1).toString();
    m_email = query.value(2).toString();
    setper(query.value(4).toInt());
    emit currentUserChanged();
    refreshUsers();
    m_lastError.clear();
    return true;
}

QString Enter::hashPassword(const QString &password)
{
    // 实际项目中应该使用更安全的哈希算法如bcrypt
    return QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());
}

QString Enter::getLastError() const
{
    return m_lastError;
}

QString Enter::roleName() const
{
    switch (per) {
    case 1:
        return QStringLiteral("店主");
    case 2:
        return QStringLiteral("店员");
    default:
        return QStringLiteral("顾客访客");
    }
}

void Enter::clearSession()
{
    m_userId = 0;
    m_username.clear();
    m_email.clear();
    setper(3);
    m_users.clear();
    emit usersChanged();
    emit currentUserChanged();
}

bool Enter::updateProfile(const QString &oldPassword, const QString &newEmail,
                          const QString &newUsername, const QString &newPassword)
{
    if (m_userId <= 0) {
        m_lastError = QStringLiteral("请先登录！");
        return false;
    }

    const QString email = newEmail.trimmed();
    const QString username = newUsername.trimmed();
    const QString password = newPassword;
    if (email.isEmpty() && username.isEmpty() && password.isEmpty()) {
        m_lastError = QStringLiteral("请至少填写一项需要修改的内容！");
        return false;
    }

    if (!QSqlDatabase::contains(kConnectionName)) {
        m_lastError = QStringLiteral("用户数据库连接不存在！");
        return false;
    }
    QSqlDatabase activeDb = QSqlDatabase::database(kConnectionName);
    if (!activeDb.isOpen()) {
        m_lastError = QStringLiteral("用户数据库未打开！");
        return false;
    }

    // 校验原密码
    QSqlQuery verify(activeDb);
    verify.prepare("SELECT password_hash FROM users WHERE id=?");
    verify.addBindValue(m_userId);
    if (!verify.exec() || !verify.next()) {
        m_lastError = QStringLiteral("查询用户失败！");
        return false;
    }
    if (verify.value(0).toString() != hashPassword(oldPassword)) {
        m_lastError = QStringLiteral("原密码不正确！");
        return false;
    }

    // 若修改用户名，需校验唯一性
    if (!username.isEmpty() && username != m_username) {
        QSqlQuery dup(activeDb);
        dup.prepare("SELECT id FROM users WHERE username=? AND id<>?");
        dup.addBindValue(username);
        dup.addBindValue(m_userId);
        if (dup.exec() && dup.next()) {
            m_lastError = QStringLiteral("用户名已存在！");
            return false;
        }
    }

    QStringList sets;
    QVariantList values;
    if (!email.isEmpty()) {
        sets << QStringLiteral("email=?");
        values << email;
    }
    if (!username.isEmpty()) {
        sets << QStringLiteral("username=?");
        values << username;
    }
    if (!password.isEmpty()) {
        sets << QStringLiteral("password_hash=?");
        values << hashPassword(password);
    }
    if (sets.isEmpty()) {
        m_lastError = QStringLiteral("没有需要修改的内容！");
        return false;
    }

    QSqlQuery update(activeDb);
    update.prepare(QStringLiteral("UPDATE users SET %1 WHERE id=?").arg(sets.join(QStringLiteral(", "))));
    for (const QVariant &value : values)
        update.addBindValue(value);
    update.addBindValue(m_userId);
    if (!update.exec()) {
        m_lastError = QStringLiteral("更新失败：%1").arg(update.lastError().text());
        return false;
    }

    // 同步内存中的会话信息
    if (!username.isEmpty())
        m_username = username;
    if (!email.isEmpty())
        m_email = email;
    emit currentUserChanged();
    m_lastError.clear();
    return true;
}

bool Enter::refreshUsers()
{
    m_users.clear();
    if (per != 1 || m_userId <= 0)
        return true;

    if (!QSqlDatabase::contains(kConnectionName)) {
        m_lastError = QStringLiteral("用户数据库连接不存在！");
        emit usersChanged();
        return false;
    }
    const QSqlDatabase activeDb = QSqlDatabase::database(kConnectionName);
    if (!activeDb.isOpen()) {
        m_lastError = QStringLiteral("用户数据库未打开！");
        emit usersChanged();
        return false;
    }

    QSqlQuery query(activeDb);
    query.prepare(QStringLiteral("SELECT id, username, COALESCE(email, ''), permission "
                                 "FROM users WHERE id<>? ORDER BY username"));
    query.addBindValue(m_userId);
    if (!query.exec()) {
        m_lastError = QStringLiteral("读取注册用户失败：%1").arg(query.lastError().text());
        emit usersChanged();
        return false;
    }

    while (query.next()) {
        auto *item = new QStandardItem(query.value(1).toString());
        const int permission = query.value(3).toInt();
        item->setData(query.value(0).toInt(), Qt::UserRole + 1);
        item->setData(query.value(2).toString(), Qt::UserRole + 2);
        item->setData(permission, Qt::UserRole + 3);
        item->setData(permission == 2 ? QStringLiteral("店员")
                                      : permission == 3 ? QStringLiteral("顾客访客")
                                                        : QStringLiteral("店主"),
                     Qt::UserRole + 4);
        m_users.appendRow(item);
    }
    emit usersChanged();
    return true;
}

bool Enter::updateUserPermission(int userId, int permission)
{
    if (per != 1) {
        m_lastError = QStringLiteral("只有店主可以修改用户角色！");
        return false;
    }
    if (userId <= 0 || userId == m_userId) {
        m_lastError = QStringLiteral("不能修改当前登录用户的角色！");
        return false;
    }
    if (permission != 2 && permission != 3) {
        m_lastError = QStringLiteral("用户角色只能设置为店员或顾客访客！");
        return false;
    }
    if (!QSqlDatabase::contains(kConnectionName)) {
        m_lastError = QStringLiteral("用户数据库连接不存在！");
        return false;
    }
    const QSqlDatabase activeDb = QSqlDatabase::database(kConnectionName);
    if (!activeDb.isOpen()) {
        m_lastError = QStringLiteral("用户数据库未打开！");
        return false;
    }

    QSqlQuery query(activeDb);
    query.prepare(QStringLiteral("UPDATE users SET permission=? WHERE id=? AND id<>?"));
    query.addBindValue(permission);
    query.addBindValue(userId);
    query.addBindValue(m_userId);
    if (!query.exec()) {
        m_lastError = QStringLiteral("修改用户角色失败：%1").arg(query.lastError().text());
        return false;
    }
    if (query.numRowsAffected() <= 0) {
        m_lastError = QStringLiteral("未找到要修改的注册用户！");
        return false;
    }

    m_lastError.clear();
    refreshUsers();
    return true;
}
