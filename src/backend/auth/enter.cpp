#include "enter.h"
#include "appconfig.h"

#include <QDebug>

namespace {
const QString kConnectionName = QStringLiteral("user_management_connection");

bool isPlaceholderValue(const QString &value)
{
    return value.startsWith(QStringLiteral("请填写"));
}
}



Enter::Enter(QObject *parent) : QObject(parent)
{
    if (!openDatabase())
        qWarning() << "Failed to open database:" << m_lastError;
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
    const QString host = AppConfig::stringValue(QStringLiteral("userDatabase/host"),
                                                QStringLiteral("127.0.0.1"));
    const int port = AppConfig::intValue(QStringLiteral("userDatabase/port"), 3306);
    const QString databaseName = AppConfig::stringValue(QStringLiteral("userDatabase/name"),
                                                        QStringLiteral("user_management"));
    const QString username = AppConfig::stringValue(QStringLiteral("userDatabase/username"),
                                                    QStringLiteral("root"));
    const QString password = AppConfig::stringValue(QStringLiteral("userDatabase/password"));
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
        m_lastError = QStringLiteral("无法连接用户数据库：%1").arg(m_db.lastError().text());
        qWarning().noquote() << m_lastError;
        return false;
    }

    // 检查表是否存在，不存在则创建。
    // permission 列为登录逻辑（select password_hash,permission）所依赖，必须包含。
    QSqlQuery query(m_db);
    if (!m_db.tables().contains("users")) {
        QString createTable = "CREATE TABLE users ("
                              "id INT AUTO_INCREMENT PRIMARY KEY, "
                              "username VARCHAR(50) NOT NULL UNIQUE, "
                              "password_hash VARCHAR(255) NOT NULL, "
                              "email VARCHAR(100), "
                              "permission INT NOT NULL DEFAULT 3, "
                              "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";
        if (!query.exec(createTable)) {
            m_lastError = query.lastError().text();
            return false;
        }
    } else {
        QSqlQuery columns(m_db);
        columns.prepare("SELECT COUNT(*) FROM information_schema.COLUMNS "
                        "WHERE TABLE_SCHEMA=? AND TABLE_NAME='users' AND COLUMN_NAME='permission'");
        columns.addBindValue(m_db.databaseName());
        if (!columns.exec() || !columns.next() || columns.value(0).toInt() == 0) {
            m_lastError = "用户表缺少 permission 字段，请先更新数据库结构！";
            return false;
        }
    }
    m_lastError.clear();
    return true;
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
    emit currentUserChanged();
}
