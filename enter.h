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

private:
    bool openDatabase();//打开数据库
    QString hashPassword(const QString &password);//密码哈希转换模块

    QSqlDatabase m_db;//连接数据库
    QString m_lastError;//错误信息
    int per;//权限级别
    Q_PROPERTY(int per READ getper WRITE setper NOTIFY perChanged)
    int getper() const{return per;}
    void setper(int value){per=value;}

signals:
    void perChanged(const int* &value);

};

#endif // ENTER_H
