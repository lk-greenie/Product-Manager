#ifndef ENTER_H
#define ENTER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QCryptographicHash>

class Enter : public QObject
{
    Q_OBJECT
public:
    explicit Enter(QObject *parent = nullptr);
    ~Enter();

    Q_INVOKABLE bool registerUser(const QString &username, const QString &password, const QString &email);//注册模块
    Q_INVOKABLE bool loginUser(const QString &username, const QString &password);//登录验证模块
    Q_INVOKABLE QString getLastError() const;//错误信息模块
    Q_INVOKABLE void clearSession();

    Q_PROPERTY(int per READ getper WRITE setper NOTIFY perChanged)
    Q_PROPERTY(int userId READ userId NOTIFY currentUserChanged)
    Q_PROPERTY(QString username READ username NOTIFY currentUserChanged)
    Q_PROPERTY(QString email READ email NOTIFY currentUserChanged)
    Q_PROPERTY(QString roleName READ roleName NOTIFY currentUserChanged)

    int getper() const{return per;}
    void setper(int value){if(per!=value){per=value; emit perChanged();}}
    int userId() const { return m_userId; }
    QString username() const { return m_username; }
    QString email() const { return m_email; }
    QString roleName() const;

private:
    bool openDatabase();//打开数据库
    QString hashPassword(const QString &password);//密码哈希转换模块

    QSqlDatabase m_db;//连接数据库
    QString m_lastError;//错误信息
    int per=3;//权限级别，默认访客
    int m_userId = 0;
    QString m_username;
    QString m_email;

signals:
    void perChanged();
    void currentUserChanged();

};

#endif // ENTER_H
