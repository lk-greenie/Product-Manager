#include "tabledisplay.h"
#include "appconfig.h"

#include <QDebug>
#include <utility>

namespace {
const QString kConnectionName = QStringLiteral("ecjtu_market_connection");

bool isPlaceholderValue(const QString &value)
{
    return value.startsWith(QStringLiteral("请填写"));
}
}


TableDisplay::TableDisplay(QObject *parent)
    : QObject{parent}
{
    if (!openDatabase())
        qWarning() << "Failed to open database:" ;
}

TableDisplay::~TableDisplay()
{
    // 先显式删除所有持有数据库连接引用的模型子对象，
    // 再关闭连接、使本地副本失效、移除连接名。
    // 顺序必须如此：模型在析构时会访问连接，若 removeDatabase 先执行
    // 则模型析构时连接已消失，产生 "still in use" 告警。
    delete proxyModel;   proxyModel   = nullptr;
    delete proxyModel1;  proxyModel1  = nullptr;
    delete proxyModel2;  proxyModel2  = nullptr;
    delete proxyModel3;  proxyModel3  = nullptr;
    delete catModel;     catModel     = nullptr;
    delete stockModel;   stockModel   = nullptr;
    delete checkModel;   checkModel   = nullptr;
    delete expenseModel; expenseModel = nullptr;
    delete incomeModel;  incomeModel  = nullptr;
    delete cnameModel;   cnameModel   = nullptr;

    if (DB.isOpen()) {
        DB.close();
    }
    DB = QSqlDatabase();
    QSqlDatabase::removeDatabase(kConnectionName);
}

// 返回业务数据库活跃连接
QSqlDatabase TableDisplay::db() const
{
    return QSqlDatabase::database(kConnectionName);
}

bool TableDisplay::openDatabase()
{
    if (!AppConfig::isLoaded()) {
        qWarning().noquote() << AppConfig::errorMessage();
        return false;
    }

    const QString driver = AppConfig::stringValue(QStringLiteral("businessDatabase/driver"),
                                                  QStringLiteral("QMYSQL"));
    const QString host = AppConfig::stringValue(QStringLiteral("businessDatabase/host"),
                                                QStringLiteral("127.0.0.1"));
    const int port = AppConfig::intValue(QStringLiteral("businessDatabase/port"), 3306);
    const QString databaseName = AppConfig::stringValue(QStringLiteral("businessDatabase/name"),
                                                        QStringLiteral("ecjtu_market"));
    const QString username = AppConfig::stringValue(QStringLiteral("businessDatabase/username"),
                                                    QStringLiteral("root"));
    const QString password = AppConfig::stringValue(QStringLiteral("businessDatabase/password"));
    if (isPlaceholderValue(password)) {
        qWarning().noquote() << QStringLiteral("请先在配置文件中填写 businessDatabase/password");
        return false;
    }

    if (QSqlDatabase::contains(kConnectionName)) {
        DB = QSqlDatabase::database(kConnectionName);
    } else {
        DB = QSqlDatabase::addDatabase(driver, kConnectionName);
    }
    DB.setHostName(host);
    DB.setPort(port);
    DB.setDatabaseName(databaseName);
    DB.setUserName(username);
    DB.setPassword(password);
    if (!DB.open()) {
        qWarning().noquote() << QStringLiteral("无法连接业务数据库：%1").arg(DB.lastError().text());
        return false;
    }

    // 幂等保护：模型已存在（构造时已成功初始化）时只刷新数据，不重建对象。
    // 重建会产生新指针，而 QML 已通过 Q_PROPERTY CONSTANT 缓存了旧指针地址，
    // 重建导致 QML 持有失效/旧指针，引发崩溃或数据不更新。
    if (catModel != nullptr) {
        catModel->select();
        stockModel->select();
        checkModel->select();
        expenseModel->select();
        incomeModel->select();
        return true;
    }

    //分类数据模型

    catModel=new QSqlRelationalTableModel(this,DB);
    catModel->setTable("category");     //设置数据表
    catModel->setRelation(catModel->fieldIndex("cat_id"),
                          QSqlRelation("category","cat_id","cat_name"));
    catModel->setSort(1,Qt::AscendingOrder);
    catModel->select(); //查询数据表的数据

    //库存数据模型
    // 注意：列顺序 cat_id,cname,bid,m_date,e_date,price,sum,up_sum,down_sum 必须保持，
    // QML delegate 依赖列索引（2=进价色标，3/4=日期）格式化。
    stockModel=new QSqlRelationalTableModel(this,DB);
    stockModel->setTable("stock");     //设置数据表
    stockModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略
    stockModel->setQuery(QSqlQuery("select cat_id,cname,bid,date_format(m_date,'%Y-%m-%d') as m_date,date_format(e_date,'%Y-%m-%d') as e_date,price,sum,up_sum,down_sum from stock",DB));

    stockModel->setHeaderData(stockModel->fieldIndex("cat_id"),  Qt::Horizontal, "分类名");
    stockModel->setHeaderData(stockModel->fieldIndex("cname"),    Qt::Horizontal, "商品名");
    stockModel->setHeaderData(stockModel->fieldIndex("bid"),  Qt::Horizontal, "进价");
    stockModel->setHeaderData(stockModel->fieldIndex("m_date"),Qt::Horizontal, "生产日期");
    stockModel->setHeaderData(stockModel->fieldIndex("e_date"), Qt::Horizontal, "保质日期");
    stockModel->setHeaderData(stockModel->fieldIndex("price"), Qt::Horizontal, "售价");
    stockModel->setHeaderData(stockModel->fieldIndex("sum"), Qt::Horizontal, "数量");
    stockModel->setHeaderData(stockModel->fieldIndex("up_sum"), Qt::Horizontal, "上限值");
    stockModel->setHeaderData(stockModel->fieldIndex("down_sum"), Qt::Horizontal, "下限值");


    //设置代码字段的关系
    stockModel->setRelation(stockModel->fieldIndex("cat_id"),
                            QSqlRelation("category","cat_id","cat_name"));

    stockModel->select(); //查询数据表的数据

    proxyModel=new QSortFilterProxyModel(this);
    proxyModel->setSourceModel(stockModel);
    proxyModel->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel->setFilterKeyColumn(1);

    //交易数据模型

    checkModel=new QSqlRelationalTableModel(this,DB);
    checkModel->setTable("record");     //设置数据表
    checkModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略

    checkModel->setHeaderData(checkModel->fieldIndex("num"),  Qt::Horizontal, "单据编号");
    checkModel->setHeaderData(checkModel->fieldIndex("cat_id"),  Qt::Horizontal, "分类名");
    checkModel->setHeaderData(checkModel->fieldIndex("cname"),    Qt::Horizontal, "商品名");
    checkModel->setHeaderData(checkModel->fieldIndex("b_p"),  Qt::Horizontal, "进价/售价");
    checkModel->setHeaderData(checkModel->fieldIndex("sum"), Qt::Horizontal, "数量");
    checkModel->setHeaderData(checkModel->fieldIndex("e_i"),Qt::Horizontal, "支出/收入");
    checkModel->setHeaderData(checkModel->fieldIndex("t_time"),Qt::Horizontal, "交易时间");

    //设置代码字段的关系
    checkModel->setRelation(checkModel->fieldIndex("cat_id"),
                            QSqlRelation("category","cat_id","cat_name"));

    checkModel->select(); //查询数据表的数据

    proxyModel1=new QSortFilterProxyModel(this);
    proxyModel1->setSourceModel(checkModel);
    proxyModel1->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel1->setFilterKeyColumn(2);


    //支出数据模型

    expenseModel=new QSqlRelationalTableModel(this,DB);
    expenseModel->setTable("expense");     //设置数据表
    expenseModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略

    expenseModel->setHeaderData(expenseModel->fieldIndex("num"),  Qt::Horizontal, "单据编号");
    expenseModel->setHeaderData(expenseModel->fieldIndex("cat_id"),  Qt::Horizontal, "分类名");
    expenseModel->setHeaderData(expenseModel->fieldIndex("cname"),    Qt::Horizontal, "商品名");
    expenseModel->setHeaderData(expenseModel->fieldIndex("b"),  Qt::Horizontal, "进价");
    expenseModel->setHeaderData(expenseModel->fieldIndex("sum"), Qt::Horizontal, "数量");
    expenseModel->setHeaderData(expenseModel->fieldIndex("e"),Qt::Horizontal, "支出");
    expenseModel->setHeaderData(expenseModel->fieldIndex("t_time"),Qt::Horizontal, "交易时间");

    //设置代码字段的关系
    expenseModel->setRelation(expenseModel->fieldIndex("cat_id"),
                              QSqlRelation("category","cat_id","cat_name"));

    expenseModel->select(); //查询数据表的数据

    proxyModel2=new QSortFilterProxyModel(this);
    proxyModel2->setSourceModel(expenseModel);
    proxyModel2->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel2->setFilterKeyColumn(2);

    //收入数据模型

    incomeModel=new QSqlRelationalTableModel(this,DB);
    incomeModel->setTable("income");     //设置数据表
    incomeModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略

    incomeModel->setHeaderData(incomeModel->fieldIndex("num"),  Qt::Horizontal, "单据编号");
    incomeModel->setHeaderData(incomeModel->fieldIndex("cat_id"),  Qt::Horizontal, "分类名");
    incomeModel->setHeaderData(incomeModel->fieldIndex("cname"),    Qt::Horizontal, "商品名");
    incomeModel->setHeaderData(incomeModel->fieldIndex("p"),  Qt::Horizontal, "售价");
    incomeModel->setHeaderData(incomeModel->fieldIndex("sum"), Qt::Horizontal, "数量");
    incomeModel->setHeaderData(incomeModel->fieldIndex("i"),Qt::Horizontal, "收入");
    incomeModel->setHeaderData(incomeModel->fieldIndex("t_time"),Qt::Horizontal, "交易时间");

    //设置代码字段的关系
    incomeModel->setRelation(incomeModel->fieldIndex("cat_id"),
                             QSqlRelation("category","cat_id","cat_name"));

    incomeModel->select(); //查询数据表的数据

    proxyModel3=new QSortFilterProxyModel(this);
    proxyModel3->setSourceModel(incomeModel);
    proxyModel3->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel3->setFilterKeyColumn(2);


    cnameModel=new QSqlRelationalTableModel(this,DB);
    cnameModel->setTable("stock");

    return true;
}
bool TableDisplay::updatecnameModel(QString cat)
{
    const int catId = getcat_id(cat);
    if (catId < 0)
        return false;

    if (catId == 0) {
        cnameModel->setQuery(QSqlQuery("select distinct cname from stock order by cname", db()));
    } else {
        QSqlQuery query(db());
        query.prepare("select distinct cname from stock where cat_id=? order by cname");
        query.addBindValue(catId);
        query.exec();
        cnameModel->setQuery(std::move(query));
    }
    return true;
}

//查询商品售价函数
bool TableDisplay::displayC(QString cat,QString flag)
{
    int cat_id=getcat_id(cat);
    if(cat_id==-1)
        return false;

    // cat_id==0（全部）时不加过滤条件；否则按分类过滤。
    // 各模型过滤列前缀不同，做映射。
    QSqlRelationalTableModel *model=nullptr;
    QString col;
    if(flag=="stock"){ model=stockModel;   col="stock.cat_id"; }
    else if(flag=="check"){ model=checkModel;   col="record.cat_id"; }
    else if(flag=="expense"){ model=expenseModel; col="expense.cat_id"; }
    else if(flag=="income"){ model=incomeModel;  col="income.cat_id"; }
    else return false;

    QString filter = (cat_id==0) ? "" : (col+"="+QString::number(cat_id));
    model->setFilter(filter);
    model->select();
    return true;
}

bool TableDisplay::displayC(QString cat,QString flag,QString sort,QString flag2)
{
    // 复用 2 参版本做过滤，再排序，消除重复分支与不可达代码
    if(!displayC(cat,flag))
        return false;
    return sortStock(cat,sort,flag2);
}


//统计分类数函数
bool TableDisplay::sortStock(QString cat,QString sort,QString flag)
{
    int cat_id=getcat_id(cat);
    if(cat_id==-1)
        return false;

    // 表驱动：排序列、升降序、过滤条件三者映射后统一处理，消除重复分支。
    // 保持字面量标志不变（QML 依赖）。
    QString col = sort=="按进价排序" ? "bid"
                : sort=="按售价排序" ? "price"
                : sort=="按数量排序" ? "sum"
                : QString();
    if(col.isEmpty())
        return false;

    Qt::SortOrder order = (flag=="升序") ? Qt::AscendingOrder
                        : (flag=="降序") ? Qt::DescendingOrder
                        : Qt::AscendingOrder;
    if(flag!="升序" && flag!="降序")
        return false;

    QString filter = (cat_id==0) ? "" : ("stock.cat_id="+QString::number(cat_id));
    stockModel->setFilter(filter);
    stockModel->setSort(stockModel->fieldIndex(col),order);
    stockModel->select();
    return true;
}
