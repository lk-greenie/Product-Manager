#include "enter.h"
#include <QDebug>

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
    QSqlDatabase::removeDatabase("user_management_connection");
}


bool Enter::openDatabase()
{
    m_db = QSqlDatabase::addDatabase("QMYSQL","user_management_connection");
    m_db.setHostName("127.0.0.1");
    m_db.setPort(3306);
    m_db.setDatabaseName("user_management");
    m_db.setUserName("root");
    m_db.setPassword("123456789lk");

    if (!m_db.open()) {
        m_lastError = "user_management未打开："+m_db.lastError().text();
        qDebug()<<m_lastError;
        return false;
    }

    // 检查表是否存在，不存在则创建
    QSqlQuery query;
    if (!m_db.tables().contains("users")) {
        QString createTable = "CREATE TABLE users ("
                              "id INT AUTO_INCREMENT PRIMARY KEY, "
                              "username VARCHAR(50) NOT NULL UNIQUE, "
                              "password_hash VARCHAR(255) NOT NULL, "
                              "email VARCHAR(100), "
                              "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";
        if (!query.exec(createTable)) {
            m_lastError = query.lastError().text();
            return false;
        }
    }
    return true;
}

bool Enter::registerUser(const QString &username, const QString &password, const QString &email)
{
    if (username.isEmpty() || password.isEmpty()) {
        m_lastError = "用户名和密码不能为空！";
        return false;
    }

    if (QSqlDatabase::contains("user_management_connection")) {
        QSqlDatabase activeDb = QSqlDatabase::database("user_management_connection");
        if (activeDb.isOpen()) {
            // 检查用户名是否已存在
            QSqlQuery checkQuery(activeDb);
            checkQuery.prepare("SELECT id FROM users WHERE username = ?");
            checkQuery.addBindValue(username);
            if (!checkQuery.exec()) {
                m_lastError = checkQuery.lastError().text();
                qDebug()<<"检查失败:"<<m_lastError;
                return false;
            }

            if (checkQuery.next()) {
                m_lastError = "用户已存在！";
                return false;
            }
            // 插入新用户
            QSqlQuery insertQuery(activeDb);
            insertQuery.prepare("INSERT INTO users (username, password_hash, email) VALUES (?, ?, ?)");
            insertQuery.addBindValue(username);
            insertQuery.addBindValue(hashPassword(password));
            insertQuery.addBindValue(email);

            if (!insertQuery.exec()) {
                m_lastError = insertQuery.lastError().text();
                return false;
            }
            return true;
        }
    }
    return false;
}

bool Enter::loginUser(const QString &username, const QString &password)
{
    if (username.isEmpty() || password.isEmpty()) {
        m_lastError = "用户名和密码不能为空！";
        return false;
    }

    // 执行前检查连接是否有效
    if (QSqlDatabase::contains("user_management_connection")) {
        QSqlDatabase activeDb = QSqlDatabase::database("user_management_connection");
        if (activeDb.isOpen()) {
            QSqlQuery query(activeDb);
            query.prepare("SELECT password_hash,permission FROM users WHERE username = ?");
            query.addBindValue(username);
            if (!query.exec()) {
                m_lastError = query.lastError().text();
                return false;
            }
            if (!query.next()) {
                m_lastError = "用户未找到！";
                return false;
            }
            QString storedHash = query.value(0).toString();
            per=query.value(1).toInt();
            return (storedHash == hashPassword(password));
        }qDebug()<<"user_management不活跃!";
    }else qDebug()<<"user_management未包含!";
    return false;
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

