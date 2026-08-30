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
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>

class TableDisplay : public QObject
{
    Q_OBJECT

    // 模型指针在构造后不再变化，暴露为只读（CONSTANT）属性，
    // 供 QML 直接引用；属性名保持不变（QML 依赖）。
    Q_PROPERTY(QSqlRelationalTableModel* catModel READ getcatModel CONSTANT)
    Q_PROPERTY(QSortFilterProxyModel* proxyModel READ getproxyModel CONSTANT)
    Q_PROPERTY(QSortFilterProxyModel* proxyModel1 READ getproxyModel1 CONSTANT)
    Q_PROPERTY(QSortFilterProxyModel* proxyModel2 READ getproxyModel2 CONSTANT)
    Q_PROPERTY(QSortFilterProxyModel* proxyModel3 READ getproxyModel3 CONSTANT)
    Q_PROPERTY(QSqlRelationalTableModel* stockModel READ getstockModel CONSTANT)
    Q_PROPERTY(QSqlRelationalTableModel* checkModel READ getcheckModel CONSTANT)
    Q_PROPERTY(QSqlRelationalTableModel* expenseModel READ getexpenseModel CONSTANT)
    Q_PROPERTY(QSqlRelationalTableModel* incomeModel READ getincomeModel CONSTANT)
    Q_PROPERTY(QSqlRelationalTableModel* cnameModel READ getcnameModel CONSTANT)

public:
    explicit TableDisplay(QObject *parent = nullptr);
    ~TableDisplay();

    // 属性读取函数
    QSqlRelationalTableModel* getcatModel() const{return catModel;}
    QSortFilterProxyModel* getproxyModel() const{return proxyModel;}
    QSortFilterProxyModel* getproxyModel1() const{return proxyModel1;}
    QSortFilterProxyModel* getproxyModel2() const{return proxyModel2;}
    QSortFilterProxyModel* getproxyModel3() const{return proxyModel3;}
    QSqlRelationalTableModel* getstockModel() const{return stockModel;}
    QSqlRelationalTableModel* getcheckModel() const{return checkModel;}
    QSqlRelationalTableModel* getexpenseModel() const{return expenseModel;}
    QSqlRelationalTableModel* getincomeModel() const{return incomeModel;}
    QSqlRelationalTableModel* getcnameModel() const{return cnameModel;}

    // 登录成功后 QML（LoginPage）直接调用 openDatabase() 确保业务库已连接，
    // 再调用 init_Cat()，因此二者必须为 Q_INVOKABLE。
    Q_INVOKABLE bool openDatabase();//连接数据库函数（构造时调用一次，登录时 QML 再调用一次）
    Q_INVOKABLE bool init_Cat();//初始化分类函数
    Q_INVOKABLE QString addCat(QString cat);//添加分类函数
    Q_INVOKABLE bool inCommodity(QString cat,QString cname,QString sum,QString bid,QString m_date,QString e_date);//入库函数
    Q_INVOKABLE bool outCommodity(QString cat,QString cname,QString sum,QString price);//出库函数
    Q_INVOKABLE bool updatecnameModel(QString cat);//更新商品名称数据模型函数
    Q_INVOKABLE QString getPrice(QString cat,QString cname);//查询商品售价函数
    Q_INVOKABLE bool setPrice(QString cat,QString cname,QString price);//更新商品售价函数
    Q_INVOKABLE bool setLimits(QString cat,QString cname,QString up_sum,QString down_sum);//更新商品警告值函数
    Q_INVOKABLE bool displayC(QString cat,QString flag);//展示某类商品信息函数
    Q_INVOKABLE bool displayC(QString cat,QString flag,QString sort,QString flag2);
    Q_INVOKABLE QString sumCat(QString cat);//统计分类数函数
    Q_INVOKABLE QString sumC(QString cat,QString cname);//统计商品数函数
    Q_INVOKABLE QString sumCheck(QString cat,QString flag);//统计开支函数
    Q_INVOKABLE bool filterRecords(const QString &flag, const QString &category,
                                   const QString &name, const QString &startDate,
                                   const QString &endDate);
    Q_INVOKABLE QString sumFilteredRecords(const QString &flag, const QString &category,
                                           const QString &name, const QString &startDate,
                                           const QString &endDate);
    Q_INVOKABLE QVariantMap productInfo(const QString &category, const QString &name);
    Q_INVOKABLE QVariantList chartBreakdown(const QString &metric, const QString &category,
                                            const QString &startDate, const QString &endDate);
    Q_INVOKABLE QVariantList chartTrend(const QString &metric, const QString &category,
                                        const QString &name, const QString &scale,
                                        const QString &startDate, const QString &endDate);
    Q_INVOKABLE bool sortStock(QString cat,QString sort,QString flag);//排序库存函数
    Q_INVOKABLE void setCurrentPermission(int permission);
    Q_INVOKABLE int currentPermission() const { return m_currentPermission; }

private:
    int getcat_id(const QString &cat);
    bool addCheck(int cat_id, const QString &cname, qreal price, int sum, const QString &recordType);
    QSqlDatabase db() const;

    static bool validCat(int catId) { return catId > 0; }
    static bool isAllCategory(const QString &cat);
    static bool parsePositiveInt(const QString &value, int &result);
    static bool parseNonNegativeReal(const QString &value, qreal &result);
    static bool parseDateRange(const QString &startDate, const QString &endDate,
                               QDate &start, QDate &end);
    QSqlRelationalTableModel *modelForFlag(const QString &flag) const;
    QSortFilterProxyModel *proxyForFlag(const QString &flag) const;
    bool appendRecordFilters(QStringList &filters, QVariantList &values,
                             const QString &category, const QString &name,
                             const QString &startDate, const QString &endDate) const;
    bool canAddCategory() const { return m_currentPermission == 1; }
    bool canManageInventory() const { return m_currentPermission == 1 || m_currentPermission == 2; }
    bool canChangeSettings() const { return m_currentPermission == 1; }

    QSqlDatabase  DB; //数据库连接
    int m_currentPermission = 3;
    // 指针显式初始化为 nullptr，防止构造器 openDatabase() 失败时 QML 读到垃圾地址
    QSqlRelationalTableModel  *catModel     = nullptr;//分类数据模型
    QSortFilterProxyModel     *proxyModel   = nullptr;
    QSortFilterProxyModel     *proxyModel1  = nullptr;
    QSortFilterProxyModel     *proxyModel2  = nullptr;
    QSortFilterProxyModel     *proxyModel3  = nullptr;
    QSqlRelationalTableModel  *stockModel   = nullptr;//库存数据模型
    QSqlRelationalTableModel  *checkModel   = nullptr;//交易数据模型
    QSqlRelationalTableModel  *expenseModel = nullptr;//支出数据模型
    QSqlRelationalTableModel  *incomeModel  = nullptr;//收入数据模型
    QSqlRelationalTableModel  *cnameModel   = nullptr;//商品名称数据模型
};

#endif // TABLEDISPLAY_H
