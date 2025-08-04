#ifndef TABLEDISPLAY_H
#define TABLEDISPLAY_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRelationalTableModel>
#include <QSortFilterProxyModel>
#include <QDate>
#include <QDebug>

class TableDisplay : public QObject
{
    Q_OBJECT
public:
    explicit TableDisplay(QObject *parent = nullptr);
    ~TableDisplay();

    QSqlDatabase  DB; //数据库连接
    QSqlRelationalTableModel  *catModel;//分类数据模型
    Q_PROPERTY(QSqlRelationalTableModel* catModel READ getcatModel WRITE setcatModel NOTIFY catModelChanged)
    QSqlRelationalTableModel* getcatModel() const{return catModel;}
    void setcatModel(QSqlRelationalTableModel* value){catModel=value;}

    QSortFilterProxyModel *proxyModel;
    Q_PROPERTY(QSortFilterProxyModel* proxyModel READ getproxyModel WRITE setproxyModel NOTIFY proxyModelChanged)
    QSortFilterProxyModel* getproxyModel() const{return proxyModel;}
    void setproxyModel(QSortFilterProxyModel* value){proxyModel=value;}

    QSortFilterProxyModel *proxyModel1;
    Q_PROPERTY(QSortFilterProxyModel* proxyModel1 READ getproxyModel1 WRITE setproxyModel1 NOTIFY proxyModel1Changed)
    QSortFilterProxyModel* getproxyModel1() const{return proxyModel1;}
    void setproxyModel1(QSortFilterProxyModel* value){proxyModel1=value;}

    QSortFilterProxyModel *proxyModel2;
    Q_PROPERTY(QSortFilterProxyModel* proxyModel2 READ getproxyModel2 WRITE setproxyModel2 NOTIFY proxyModel2Changed)
    QSortFilterProxyModel* getproxyModel2() const{return proxyModel2;}
    void setproxyModel2(QSortFilterProxyModel* value){proxyModel2=value;}

    QSortFilterProxyModel *proxyModel3;
    Q_PROPERTY(QSortFilterProxyModel* proxyModel3 READ getproxyModel3 WRITE setproxyModel3 NOTIFY proxyModel3Changed)
    QSortFilterProxyModel* getproxyModel3() const{return proxyModel3;}
    void setproxyModel3(QSortFilterProxyModel* value){proxyModel3=value;}

    QSqlRelationalTableModel  *stockModel;//库存数据模型
    Q_PROPERTY(QSqlRelationalTableModel* stockModel READ getstockModel WRITE setstockModel NOTIFY stockModelChanged)
    QSqlRelationalTableModel* getstockModel() const{return stockModel;}
    void setstockModel(QSqlRelationalTableModel* value){stockModel=value;}


    QSqlRelationalTableModel  *checkModel;//交易数据模型
    Q_PROPERTY(QSqlRelationalTableModel* checkModel READ getcheckModel WRITE setcheckModel NOTIFY checkModelChanged)
    QSqlRelationalTableModel* getcheckModel() const{return checkModel;}
    void setcheckModel(QSqlRelationalTableModel* value){checkModel=value;}

    QSqlRelationalTableModel  *expenseModel;//支出数据模型
    Q_PROPERTY(QSqlRelationalTableModel* expenseModel READ getexpenseModel WRITE setexpenseModel NOTIFY expenseModelChanged)
    QSqlRelationalTableModel* getexpenseModel() const{return expenseModel;}
    void setexpenseModel(QSqlRelationalTableModel* value){expenseModel=value;}

    QSqlRelationalTableModel  *incomeModel;//收入数据模型
    Q_PROPERTY(QSqlRelationalTableModel* incomeModel READ getincomeModel WRITE setincomeModel NOTIFY incomeModelChanged)
    QSqlRelationalTableModel* getincomeModel() const{return incomeModel;}
    void setincomeModel(QSqlRelationalTableModel* value){incomeModel=value;}

    QSqlRelationalTableModel  *cnameModel;//商品名称数据模型
    Q_PROPERTY(QSqlRelationalTableModel* cnameModel READ getcnameModel WRITE setcnameModel NOTIFY cnameModelChanged)
    QSqlRelationalTableModel* getcnameModel() const{return cnameModel;}
    void setcnameModel(QSqlRelationalTableModel* value){cnameModel=value;}

    int getcat_id(QString cat);//查询分类ID函数
    Q_INVOKABLE bool addCat(QString cat);//添加分类函数
    Q_INVOKABLE bool inCommodity(QString cat,QString cname,QString sum,QString bid,QString m_date,QString e_date);//入库函数
    Q_INVOKABLE bool outCommodity(QString cat,QString cname,QString sum,QString price);//出库函数
    bool addCheck(int cat_id,QString cname,qreal b_p,int sum,QString check);//添加收支记录
    Q_INVOKABLE bool updatecnameModel(QString cat);//更新商品名称数据模型函数
    Q_INVOKABLE QString getPrice(QString cat,QString cname);//查询商品售价函数
    Q_INVOKABLE bool setPrice(QString cat,QString cname,QString price);//更新商品售价函数
    Q_INVOKABLE bool setLimits(QString cat,QString cname,QString up_sum,QString down_sum);//更新商品警告值函数
    Q_INVOKABLE bool displayC(QString cat,QString flag);//展示某类商品信息函数
    Q_INVOKABLE bool displayC(QString cat,QString flag,QString sort,QString flag2);
    Q_INVOKABLE QString sumCat(QString cat);//统计分类数函数
    Q_INVOKABLE QString sumC(QString cat,QString cname);//统计商品数函数
    Q_INVOKABLE QString sumCheck(QString cat,QString flag);//统计开支函数
    Q_INVOKABLE bool sortStock(QString cat,QString sort,QString flag);//统计开支函数

signals:
    void catModelChanged(const QSqlRelationalTableModel* &value);
    void stockModelChanged(const QSqlRelationalTableModel* &value);
    void checkModelChanged(const QSqlRelationalTableModel* &value);
    void expenseModelChanged(const QSqlRelationalTableModel* &value);
    void incomeModelChanged(const QSqlRelationalTableModel* &value);
    void cnameModelChanged(const QSqlRelationalTableModel* &value);
    void proxyModelChanged(const QSortFilterProxyModel* &value);
    void proxyModel1Changed(const QSortFilterProxyModel* &value);
    void proxyModel2Changed(const QSortFilterProxyModel* &value);
    void proxyModel3Changed(const QSortFilterProxyModel* &value);

};

#endif // TABLEDISPLAY_H
