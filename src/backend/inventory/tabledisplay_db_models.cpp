#include "tabledisplay.h"
#include "appconfig.h"

#include <QDebug>
#include <QSqlRecord>
#include <utility>

namespace {
const QString kConnectionName = QStringLiteral("warehouse_connection");

bool isPlaceholderValue(const QString &value)
{
    return value.startsWith(QStringLiteral("请填写"));
}

bool createDatabaseIfMissing(const QString &driver, const QString &host, int port,
                            const QString &databaseName, const QString &username,
                            const QString &password, QString *error)
{
    const QString adminName = QStringLiteral("warehouse_admin_connection");
    QSqlDatabase admin = QSqlDatabase::addDatabase(driver, adminName);
    admin.setHostName(host); admin.setPort(port); admin.setUserName(username); admin.setPassword(password);
    if (!admin.open()) {
        if (error) *error = admin.lastError().text();
        admin = QSqlDatabase(); QSqlDatabase::removeDatabase(adminName); return false;
    }
    QString identifier = databaseName;
    {
        QSqlQuery query(admin);
        if (!query.exec(QStringLiteral("CREATE DATABASE IF NOT EXISTS `%1` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
                            .arg(identifier.replace('`', "``")))) {
            if (error) *error = query.lastError().text();
            admin.close(); admin = QSqlDatabase(); QSqlDatabase::removeDatabase(adminName); return false;
        }
    }
    admin.close(); admin = QSqlDatabase(); QSqlDatabase::removeDatabase(adminName); return true;
}

bool ensureBusinessTables(QSqlDatabase db, QString *error)
{
    QSqlQuery query(db);
    const QStringList statements = {
        QStringLiteral("CREATE TABLE IF NOT EXISTS category (cat_id INT AUTO_INCREMENT PRIMARY KEY, cat_name VARCHAR(50) NOT NULL UNIQUE)"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS stock (stock_id BIGINT AUTO_INCREMENT PRIMARY KEY, cat_id INT NOT NULL, cname VARCHAR(100) NOT NULL, bid DECIMAL(10,2) NOT NULL, m_date DATE NOT NULL, e_date DATE NOT NULL, price DECIMAL(10,2) NOT NULL DEFAULT 0, `sum` INT NOT NULL DEFAULT 0, up_sum INT NOT NULL DEFAULT 0, down_sum INT NOT NULL DEFAULT 0, CONSTRAINT fk_stock_category FOREIGN KEY (cat_id) REFERENCES category(cat_id))"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS record (num BIGINT AUTO_INCREMENT PRIMARY KEY, cat_id INT NOT NULL, cname VARCHAR(100) NOT NULL, b_p DECIMAL(10,2) NOT NULL, `sum` INT NOT NULL, e_i DECIMAL(12,2) NOT NULL, t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT fk_record_category FOREIGN KEY (cat_id) REFERENCES category(cat_id))"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS expense (num BIGINT AUTO_INCREMENT PRIMARY KEY, cat_id INT NOT NULL, cname VARCHAR(100) NOT NULL, b DECIMAL(10,2) NOT NULL, `sum` INT NOT NULL, e DECIMAL(12,2) NOT NULL, t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT fk_expense_category FOREIGN KEY (cat_id) REFERENCES category(cat_id))"),
        QStringLiteral("CREATE TABLE IF NOT EXISTS income (num BIGINT AUTO_INCREMENT PRIMARY KEY, cat_id INT NOT NULL, cname VARCHAR(100) NOT NULL, p DECIMAL(10,2) NOT NULL, `sum` INT NOT NULL, i DECIMAL(12,2) NOT NULL, t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT fk_income_category FOREIGN KEY (cat_id) REFERENCES category(cat_id))")
    };
    for (const QString &sql : statements) {
        if (!query.exec(sql)) { if (error) *error = query.lastError().text(); return false; }
    }
    return true;
}
}


TableDisplay::TableDisplay(QObject *parent)
    : QObject{parent}
{
    if (!openDatabase())
        qWarning().noquote() << QStringLiteral("无法打开业务数据库");
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
    // open=false 是关键：用户手动断开后，查询只会在关闭的连接上失败，
    // 不会因取得连接对象而触发 Qt 的隐式重连。
    return QSqlDatabase::database(kConnectionName, false);
}

bool TableDisplay::openDatabase()
{
    if (!AppConfig::isLoaded()) {
        m_lastDatabaseError = AppConfig::errorMessage();
        qWarning().noquote() << m_lastDatabaseError;
        return false;
    }

    const QString driver = AppConfig::stringValue(QStringLiteral("businessDatabase/driver"),
                                                  QStringLiteral("QMYSQL"));
    const QString host = AppConfig::stringValue(QStringLiteral("businessDatabase/host"));
    const int port = AppConfig::intValue(QStringLiteral("businessDatabase/port"));
    QString databaseName = AppConfig::stringValue(QStringLiteral("businessDatabase/name"),
                                                  QStringLiteral("warehouse"));
    if (databaseName == QStringLiteral("ecjtu_market"))
        databaseName = QStringLiteral("warehouse");
    const QString username = AppConfig::stringValue(QStringLiteral("businessDatabase/username"),
                                                    QStringLiteral("root"));
    const QString password = AppConfig::stringValue(QStringLiteral("businessDatabase/password"));
    if (host.isEmpty() || port < 1 || port > 65535) {
        m_lastDatabaseError = QStringLiteral("请先在配置文件中填写有效的 businessDatabase/host 和 businessDatabase/port");
        return false;
    }
    if (isPlaceholderValue(password)) {
        m_lastDatabaseError = QStringLiteral("请先在配置文件中填写 businessDatabase/password");
        qWarning().noquote() << m_lastDatabaseError;
        return false;
    }

    if (QSqlDatabase::contains(kConnectionName)) {
        DB = QSqlDatabase::database(kConnectionName, false);
    } else {
        DB = QSqlDatabase::addDatabase(driver, kConnectionName);
    }
    DB.setHostName(host);
    DB.setPort(port);
    DB.setDatabaseName(databaseName);
    DB.setUserName(username);
    DB.setPassword(password);
    if (!DB.open()) {
        QString createError;
        DB.close();
        if (!createDatabaseIfMissing(driver, host, port, databaseName, username, password, &createError)) {
            m_lastDatabaseError = QStringLiteral("无法连接或创建业务数据库：%1").arg(createError);
            qWarning().noquote() << m_lastDatabaseError;
            return false;
        }
        if (!DB.open()) {
            m_lastDatabaseError = QStringLiteral("无法打开业务数据库：%1").arg(DB.lastError().text());
            qWarning().noquote() << m_lastDatabaseError;
            return false;
        }
    }

    QString schemaError;
    if (!ensureBusinessTables(DB, &schemaError)) {
        m_lastDatabaseError = QStringLiteral("初始化业务数据库表失败：%1").arg(schemaError);
        qWarning().noquote() << m_lastDatabaseError;
        return false;
    }

    // 交易时间要求为北京时间。
    // 说明：QMYSQL 驱动把 TIMESTAMP 解析成 QDateTime，QML 再以“本机时区”格式化展示。
    // 本机为东八区，因此让会话返回 UTC（+00:00），展示时 +8 即为北京时间，
    // 从而与数据库工具（东八区会话）显示的时间一致，避免再次叠加 +8 造成“多 8 小时”。
    {
        QSqlQuery tzQuery(DB);
        if (!tzQuery.exec(QStringLiteral("SET time_zone = '+00:00'")))
            qWarning().noquote() << QStringLiteral("设置会话时区失败：%1").arg(tzQuery.lastError().text());
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
        m_lastDatabaseError.clear();
        return true;
    }

    //分类数据模型

    catModel=new QSqlRelationalTableModel(this,DB);
    catModel->setTable("category");     //设置数据表
    catModel->setRelation(catModel->fieldIndex("cat_id"),
                          QSqlRelation("category","cat_id","cat_name"));
    catModel->setSort(1,Qt::AscendingOrder);
    catModel->select(); //查询数据表的数据

    // 库存关系模型沿用 stock 表的十个字段，cat_id 列通过关联显示为分类名称。
    // 这样筛选、排序与 TableView 的列索引保持一致，不会再出现表头错列或字段缺失。
    stockModel=new QSqlRelationalTableModel(this,DB);
    stockModel->setTable("stock");     //设置数据表
    stockModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略
    stockModel->setHeaderData(0, Qt::Horizontal, QStringLiteral("库存编号"));
    stockModel->setHeaderData(1, Qt::Horizontal, QStringLiteral("分类名称"));
    stockModel->setHeaderData(2, Qt::Horizontal, QStringLiteral("商品名称"));
    stockModel->setHeaderData(3, Qt::Horizontal, QStringLiteral("进货单价"));
    stockModel->setHeaderData(4, Qt::Horizontal, QStringLiteral("生产日期"));
    stockModel->setHeaderData(5, Qt::Horizontal, QStringLiteral("保质期至"));
    stockModel->setHeaderData(6, Qt::Horizontal, QStringLiteral("销售单价"));
    stockModel->setHeaderData(7, Qt::Horizontal, QStringLiteral("库存数量"));
    stockModel->setHeaderData(8, Qt::Horizontal, QStringLiteral("库存上限"));
    stockModel->setHeaderData(9, Qt::Horizontal, QStringLiteral("库存下限"));


    //设置代码字段的关系
    stockModel->setRelation(stockModel->fieldIndex("cat_id"),
                            QSqlRelation("category","cat_id","cat_name"));

    stockModel->select(); //查询数据表的数据

    proxyModel=new QSortFilterProxyModel(this);
    proxyModel->setSourceModel(stockModel);
    proxyModel->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel->setFilterKeyColumn(2);

    //交易数据模型

    checkModel=new QSqlRelationalTableModel(this,DB);
    checkModel->setTable("record");     //设置数据表
    checkModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略

    checkModel->setHeaderData(0, Qt::Horizontal, QStringLiteral("单据编号"));
    checkModel->setHeaderData(1, Qt::Horizontal, QStringLiteral("分类名"));
    checkModel->setHeaderData(2, Qt::Horizontal, QStringLiteral("商品名"));
    checkModel->setHeaderData(3, Qt::Horizontal, QStringLiteral("进价/售价"));
    checkModel->setHeaderData(4, Qt::Horizontal, QStringLiteral("数量"));
    checkModel->setHeaderData(5, Qt::Horizontal, QStringLiteral("支出/收入"));
    checkModel->setHeaderData(6, Qt::Horizontal, QStringLiteral("交易时间"));

    //设置代码字段的关系
    checkModel->setRelation(checkModel->fieldIndex("cat_id"),
                            QSqlRelation("category","cat_id","cat_name"));

    checkModel->select(); //查询数据表的数据

    proxyModel1=new QSortFilterProxyModel(this);
    proxyModel1->setSourceModel(checkModel);
    proxyModel1->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel1->setFilterKeyColumn(3);


    //支出数据模型

    expenseModel=new QSqlRelationalTableModel(this,DB);
    expenseModel->setTable("expense");     //设置数据表
    expenseModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略

    expenseModel->setHeaderData(0, Qt::Horizontal, QStringLiteral("单据编号"));
    expenseModel->setHeaderData(1, Qt::Horizontal, QStringLiteral("分类名"));
    expenseModel->setHeaderData(2, Qt::Horizontal, QStringLiteral("商品名"));
    expenseModel->setHeaderData(3, Qt::Horizontal, QStringLiteral("进价"));
    expenseModel->setHeaderData(4, Qt::Horizontal, QStringLiteral("数量"));
    expenseModel->setHeaderData(5, Qt::Horizontal, QStringLiteral("支出"));
    expenseModel->setHeaderData(6, Qt::Horizontal, QStringLiteral("交易时间"));

    //设置代码字段的关系
    expenseModel->setRelation(expenseModel->fieldIndex("cat_id"),
                              QSqlRelation("category","cat_id","cat_name"));

    expenseModel->select(); //查询数据表的数据

    proxyModel2=new QSortFilterProxyModel(this);
    proxyModel2->setSourceModel(expenseModel);
    proxyModel2->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel2->setFilterKeyColumn(3);

    //收入数据模型

    incomeModel=new QSqlRelationalTableModel(this,DB);
    incomeModel->setTable("income");     //设置数据表
    incomeModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略

    incomeModel->setHeaderData(0, Qt::Horizontal, QStringLiteral("单据编号"));
    incomeModel->setHeaderData(1, Qt::Horizontal, QStringLiteral("分类名"));
    incomeModel->setHeaderData(2, Qt::Horizontal, QStringLiteral("商品名"));
    incomeModel->setHeaderData(3, Qt::Horizontal, QStringLiteral("售价"));
    incomeModel->setHeaderData(4, Qt::Horizontal, QStringLiteral("数量"));
    incomeModel->setHeaderData(5, Qt::Horizontal, QStringLiteral("收入"));
    incomeModel->setHeaderData(6, Qt::Horizontal, QStringLiteral("交易时间"));

    //设置代码字段的关系
    incomeModel->setRelation(incomeModel->fieldIndex("cat_id"),
                             QSqlRelation("category","cat_id","cat_name"));

    incomeModel->select(); //查询数据表的数据

    proxyModel3=new QSortFilterProxyModel(this);
    proxyModel3->setSourceModel(incomeModel);
    proxyModel3->setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxyModel3->setFilterKeyColumn(3);


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
    const int catId = getcat_id(cat);
    if (catId < 0)
        return false;

    QSqlRelationalTableModel *model = nullptr;
    QString filterColumn;
    if (flag == QStringLiteral("stock")) {
        model = stockModel;
        filterColumn = QStringLiteral("stock.cat_id");
    } else if (flag == QStringLiteral("check")) {
        model = checkModel;
        filterColumn = QStringLiteral("record.cat_id");
    } else if (flag == QStringLiteral("expense")) {
        model = expenseModel;
        filterColumn = QStringLiteral("expense.cat_id");
    } else if (flag == QStringLiteral("income")) {
        model = incomeModel;
        filterColumn = QStringLiteral("income.cat_id");
    } else {
        return false;
    }

    // 分类、排序和刷新合并为一次 select，避免分类切换时重复查询同一个模型。
    model->setFilter(catId == 0 ? QString() : filterColumn + QStringLiteral("=") + QString::number(catId));
    if (flag == QStringLiteral("stock") && !sort.isEmpty() && !flag2.isEmpty()) {
        const QString sortColumn = sort == QStringLiteral("按进价排序") ? QStringLiteral("bid")
                                  : sort == QStringLiteral("按售价排序") ? QStringLiteral("price")
                                  : sort == QStringLiteral("按数量排序") ? QStringLiteral("sum")
                                  : QString();
        if (sortColumn.isEmpty())
            return false;
        if (flag2 != QStringLiteral("升序") && flag2 != QStringLiteral("降序"))
            return false;
        model->setSort(model->fieldIndex(sortColumn),
                       flag2 == QStringLiteral("升序") ? Qt::AscendingOrder : Qt::DescendingOrder);
    }
    model->select();
    m_lastDatabaseError.clear();
    return true;
}

void TableDisplay::disconnectDatabase()
{
    if (DB.isOpen())
        DB.close();
    m_lastDatabaseError.clear();
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
