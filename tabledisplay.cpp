#include "tabledisplay.h"
#include <QDebug>

TableDisplay::TableDisplay(QObject *parent)
    : QObject{parent}
{
    //连接数据库
    DB = QSqlDatabase::addDatabase("QMYSQL","ecjtu_market_connection");
    DB.setHostName("127.0.0.1");
    DB.setPort(3306);
    DB.setDatabaseName("ecjtu_market");
    DB.setUserName("root");
    DB.setPassword("123456789lk");
    if (!DB.open()) qDebug()<<"ecjtu_market未打开："<<DB.lastError().text();

    //分类数据模型

    catModel=new QSqlRelationalTableModel(this,DB);
    catModel->setTable("category");     //设置数据表

    catModel->setRelation(catModel->fieldIndex("cat_id"),
                            QSqlRelation("category","cat_id","cat_name"));

    catModel->select(); //查询数据表的数据

    //库存数据模型

    stockModel=new QSqlRelationalTableModel(this,DB);
    stockModel->setTable("stock");     //设置数据表
    stockModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略
    // cnameModel->setQuery(QSqlQuery("select distinct cname from stock",QSqlDatabase::database("ecjtu_market_connection")));
    // QSqlQuery q(QSqlDatabase::database("ecjtu_market_connection"));
    // q.exec("select cat_id,date(m_date) from stock");
    stockModel->setQuery(QSqlQuery("select cat_id,cname,bid,date_format(m_date,'%Y-%m-%d') as m_date,date_format(e_date,'%Y-%m-%d') as e_date,price,sum,up_sum,down_sum from stock",QSqlDatabase::database("ecjtu_market_connection")));

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

    // for (int row = 0; row < stockModel->rowCount(); ++row) {
    //     for (int col = 0; col < stockModel->columnCount(); ++col) {
    //         QModelIndex index = stockModel->index(row, col);
    //         QString value = stockModel->data(index, Qt::DisplayRole).toString();
    //         qDebug() << "Row:" << row << "Column:" << col << "Value:" << value;
    //     }
    // }

    //交易数据模型

    checkModel=new QSqlRelationalTableModel(this,DB);
    checkModel->setTable("record");     //设置数据表
    checkModel->setEditStrategy(QSqlTableModel::OnManualSubmit);  //编辑策略
    // stockModel->setSort(stockModel->fieldIndex("studID"),Qt::AscendingOrder);

    // selModel=new QItemSelectionModel(stockModel,this);     //创建选择模型

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
    // stockModel->setSort(stockModel->fieldIndex("studID"),Qt::AscendingOrder);

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
    // stockModel->setSort(stockModel->fieldIndex("studID"),Qt::AscendingOrder);

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

}

TableDisplay::~TableDisplay()
{
    if (DB.isOpen()) {
        DB.close();
    }
    QSqlDatabase::removeDatabase("ecjtu_market_connection");
}


//添加分类函数
bool TableDisplay::addCat(QString cat)
{
    if (QSqlDatabase::contains("ecjtu_market_connection")) {
        QSqlDatabase activeDb = QSqlDatabase::database("ecjtu_market_connection");
        if (activeDb.isOpen()) {
            // 检查用户名是否已存在
            QSqlQuery query(activeDb);
            query.prepare("insert into category(cat_name) values(?)");
            query.addBindValue(cat);

            if (!query.exec()) {
                qDebug()<<"添加分类失败:"<<query.lastError().text();
                return false;
            }
            catModel->select();
            return true;
        }
    }
    return false;
}

//查询分类ID函数
int TableDisplay::getcat_id(QString cat)
{
    if (QSqlDatabase::contains("ecjtu_market_connection")) {
        QSqlDatabase activeDb = QSqlDatabase::database("ecjtu_market_connection");
        if (activeDb.isOpen()) {
            // 检查用户名是否已存在
            QSqlQuery query(activeDb);
            query.prepare("select cat_id from category where cat_name=?");
            query.addBindValue(cat);
            if (query.exec()) {
                if(query.next()){
                    return query.value("cat_id").toInt();
                }else{
                    qDebug()<<"该分类的ID未找到！";
                    return -1;
                }
            }else{
                qDebug()<<"分类ID查询语句失败！"<<query.lastError().text();
                return -1;
            }
        }else{
            qDebug()<<"ecjtu_market_connection数据库未打开！";
            return -1;
        }
    }else{
        qDebug()<<"ecjtu_market_connection数据库不存在！";
        return -1;
    }
    return -1;
}

//入库
bool TableDisplay::inCommodity(QString cat,QString cname,QString sum,QString bid,QString m_date,QString e_date)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("select cat_id,cname,bid,m_date,e_date from stock where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
        query.addBindValue(cat_id);
        query.addBindValue(cname);
        query.addBindValue(bid.toFloat());
        query.addBindValue(QDate::fromString(m_date,"yyyy-MM-dd"));
        query.addBindValue(QDate::fromString(e_date,"yyyy-MM-dd"));
        if(query.exec()){
            if(query.next()){
                query.prepare("update stock set sum=sum+? where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
                query.addBindValue(sum);
                query.addBindValue(cat_id);
                query.addBindValue(cname);
                query.addBindValue(bid.toFloat());
                query.addBindValue(QDate::fromString(m_date,"yyyy-MM-dd"));
                query.addBindValue(QDate::fromString(e_date,"yyyy-MM-dd"));
                if(query.exec()){
                    qDebug()<<"入库增加商品成功！";
                    addCheck(cat_id,cname,bid.toFloat(),sum.toInt(),"支出");
                    stockModel->select();
                    checkModel->select();
                    expenseModel->select();
                    return true;
                }
                else {
                    qDebug()<<"入库增加商品失败！"<<query.lastError().text();
                    return false;
                }
            }else{
                query.prepare("insert into stock(cat_id,cname,bid,m_date,e_date,sum) values(?,?,?,?,?,?)");
                query.addBindValue(cat_id);
                query.addBindValue(cname);
                query.addBindValue(bid.toFloat());
                query.addBindValue(QDate::fromString(m_date,"yyyy-MM-dd"));
                query.addBindValue(QDate::fromString(e_date,"yyyy-MM-dd"));
                query.addBindValue(sum.toInt());
                if(query.exec()){
                    qDebug()<<"入库商品成功！";
                    addCheck(cat_id,cname,bid.toFloat(),sum.toInt(),"支出");
                    stockModel->select();
                    checkModel->select();
                    expenseModel->select();
                    return true;
                }
                else {
                    qDebug()<<"入库商品失败！"<<query.lastError().text();
                    return false;
                }
            }
        }else{
            qDebug()<<"查找商品失败:"<<query.lastError().text();
            return false;
        }
    }
    return false;
}

//添加收支记录
bool TableDisplay::addCheck(int cat_id,QString cname,qreal b_p,int sum,QString check)
{
    if (QSqlDatabase::contains("ecjtu_market_connection")) {
        QSqlDatabase activeDb = QSqlDatabase::database("ecjtu_market_connection");
        if (activeDb.isOpen()) {
            // 检查用户名是否已存在
            QSqlQuery query(activeDb);

            //插入总交易记录
            query.prepare("insert into record(cat_id,cname,b_p,sum,e_i) values(?,?,?,?,?)");
            query.addBindValue(cat_id);
            query.addBindValue(cname);
            query.addBindValue(b_p);
            query.addBindValue(sum);
            query.addBindValue(check=="支出"?b_p*sum*-1:b_p*sum);
            if (query.exec()) {

            }else{
                qDebug()<<"插入总交易记录失败:"<<query.lastError().text();
                return false;
            }

            if(check=="支出")
            {
                //插入支出记录
                query.prepare("insert into expense(cat_id,cname,b,sum,e) values(?,?,?,?,?)");
                query.addBindValue(cat_id);
                query.addBindValue(cname);
                query.addBindValue(b_p);
                query.addBindValue(sum);
                query.addBindValue(b_p*sum);
                if (query.exec()) {

                }else{
                    qDebug()<<"插入支出记录失败:"<<query.lastError().text();
                    return false;
                }
            }else{
                //插入收入记录
                query.prepare("insert into income(cat_id,cname,p,sum,i) values(?,?,?,?,?)");
                query.addBindValue(cat_id);
                query.addBindValue(cname);
                query.addBindValue(b_p);
                query.addBindValue(sum);
                query.addBindValue(b_p*sum);
                if (query.exec()) {

                }else{
                    qDebug()<<"插入收入记录失败:"<<query.lastError().text();
                    return false;
                }
            }
        }
    }
    return false;
}

//出库函数
bool TableDisplay::outCommodity(QString cat,QString cname,QString sum,QString price)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("select sum(sum) from stock where cat_id=? and cname=?");
        query.addBindValue(cat_id);
        query.addBindValue(cname);

        if(query.exec()){
            if(query.next()){
                if(query.value(0).toInt()<sum.toInt()){
                    qDebug()<<"此种分类的商品数量不够！";
                    return false;
                }else{
                    int s=sum.toInt();
                    QSqlQuery query1(QSqlDatabase::database("ecjtu_market_connection"));
                    query1.prepare("select * from stock where cat_id=? and cname=?");
                    query1.addBindValue(cat_id);
                    query1.addBindValue(cname);
                    query1.exec();
                    if(query.exec()){
                        while(query1.next()&&s>0){

                            if(query1.value("sum").toInt()<=s)
                            {
                                s-=query1.value("sum").toInt();
                                query.prepare("delete from stock where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
                                query.addBindValue(cat_id);
                                query.addBindValue(cname);
                                query.addBindValue(query1.value("bid").toFloat());
                                query.addBindValue(QDate::fromString(query1.value("m_date").toString(),"yyyy-MM-dd"));
                                query.addBindValue(QDate::fromString(query1.value("e_date").toString(),"yyyy-MM-dd"));
                            }else{
                                query.prepare("update stock set sum=sum-? where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
                                query.addBindValue(s);
                                query.addBindValue(cat_id);
                                query.addBindValue(cname);
                                query.addBindValue(query1.value("bid").toFloat());
                                query.addBindValue(QDate::fromString(query1.value("m_date").toString(),"yyyy-MM-dd"));
                                query.addBindValue(QDate::fromString(query1.value("e_date").toString(),"yyyy-MM-dd"));
                                s=0;
                            }
                        }
                        addCheck(cat_id,cname,price.toFloat(),sum.toInt(),"收入");
                        stockModel->select();
                        checkModel->select();
                        incomeModel->select();
                        return true;
                    }else{
                        qDebug()<<"未找到此种分类的商品！"<<query.lastError().text();
                        return false;
                    }
                }
            }else{
                qDebug()<<"未找到此种分类的商品！"<<query.lastError().text();
                return false;
            }
        }else{
            qDebug()<<"未找到此种分类的商品！"<<query.lastError().text();
            return false;
        }
    }
    return false;
}

//更新商品名称数据模型函数
bool TableDisplay::updatecnameModel(QString cat)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        cnameModel->setQuery(QSqlQuery("select distinct cname from stock",QSqlDatabase::database("ecjtu_market_connection")));
        cnameModel->setFilter("cat_id="+QString::number(cat_id));
        cnameModel->select();
        return true;
    }
    return false;
}

//查询商品售价函数
QString TableDisplay::getPrice(QString cat,QString cname)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("select price from stock where cat_id=? and cname=?");
        query.addBindValue(cat_id);
        query.addBindValue(cname);
        if (query.exec()) {
            if(query.next()){
                return query.value("price").toString();
            }
        }
    }
    return "";
}

//更新商品售价函数
bool TableDisplay::setPrice(QString cat,QString cname,QString price)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("update stock set price=? where cat_id=? and cname=?");
        query.addBindValue(price.toFloat());
        query.addBindValue(cat_id);
        query.addBindValue(cname);
        query.exec();
        stockModel->select();
        return true;
    }
    return false;
}

//更新商品警告值函数
bool TableDisplay::setLimits(QString cat,QString cname,QString up_sum,QString down_sum)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("update stock set up_sum=?,down_sum=? where cat_id=? and cname=?");
        query.addBindValue(up_sum.toInt());
        query.addBindValue(down_sum.toInt());
        query.addBindValue(cat_id);
        query.addBindValue(cname);
        query.exec();
        stockModel->select();
        return true;
    }
    return false;
}

//展示某类商品函数
bool TableDisplay::displayC(QString cat,QString flag)
{
    int cat_id=getcat_id(cat);
    if(cat_id==0)
    {
        if(flag=="stock"){
            stockModel->setFilter("");
            stockModel->select();
            return true;
        }else if(flag=="check"){
            checkModel->setFilter("");
            checkModel->select();
            return true;
        }else if(flag=="expense"){
            expenseModel->setFilter("");
            expenseModel->select();
            return true;
        }else if(flag=="income"){
            incomeModel->setFilter("");
            incomeModel->select();
            return true;
        }
    }else if(cat_id!=-1){
        if(flag=="stock"){
            stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
            stockModel->select();
            return true;
        }else if(flag=="check"){
            checkModel->setFilter("record.cat_id="+QString::number(cat_id));
            checkModel->select();
            return true;
        }else if(flag=="expense"){
            expenseModel->setFilter("expense.cat_id="+QString::number(cat_id));
            expenseModel->select();
            return true;
        }else if(flag=="income"){
            incomeModel->setFilter("income.cat_id="+QString::number(cat_id));
            incomeModel->select();
            return true;
        }
    }

    return false;
}

bool TableDisplay::displayC(QString cat,QString flag,QString sort,QString flag2)
{
    int cat_id=getcat_id(cat);
    if(cat_id==0)
    {
        if(flag=="stock"){
            stockModel->setFilter("");
            stockModel->select();
            return true;
        }else if(flag=="check"){
            checkModel->setFilter("");
            checkModel->select();
            return true;
        }else if(flag=="expense"){
            expenseModel->setFilter("");
            expenseModel->select();
            return true;
        }else if(flag=="income"){
            incomeModel->setFilter("");
            incomeModel->select();
            return true;
        }
    }else if(cat_id!=-1){
        if(flag=="stock"){
            stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
            stockModel->select();
            return true;
        }else if(flag=="check"){
            checkModel->setFilter("record.cat_id="+QString::number(cat_id));
            checkModel->select();
            return true;
        }else if(flag=="expense"){
            expenseModel->setFilter("expense.cat_id="+QString::number(cat_id));
            expenseModel->select();
            return true;
        }else if(flag=="income"){
            incomeModel->setFilter("income.cat_id="+QString::number(cat_id));
            incomeModel->select();
            return true;
        }
    }
    sortStock(cat,sort,flag2);
    return false;
}


//统计分类数函数
QString TableDisplay::sumCat(QString cat)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("select count(distinct cname) as unique_cname from stock where cat_id=?");
        query.addBindValue(cat_id);
        query.exec();
        query.next();
        return query.value(0).toString();
    }
    return 0;
}

//统计商品数函数
QString TableDisplay::sumC(QString cat,QString cname)
{
    int cat_id=getcat_id(cat);
    if(cat_id!=-1&&cat_id!=0)
    {
        QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
        query.prepare("select sum(sum) from stock where cat_id=? and cname=?");
        query.addBindValue(cat_id);
        query.addBindValue(cname);
        query.exec();
        query.next();
        return query.value(0).toString();
    }
    return 0;
}

//统计开支函数
QString TableDisplay::sumCheck(QString cat,QString flag)
{
    int cat_id=getcat_id(cat);
    QSqlQuery query(QSqlDatabase::database("ecjtu_market_connection"));
    if(cat_id==0)
    {
        if(flag=="check"){
            query.prepare("select sum(e_i) from record");
            query.exec();
            query.next();
            return query.value(0).toString();
        }else if(flag=="expense"){
            query.prepare("select sum(e) from expense");
            query.exec();
            query.next();
            return query.value(0).toString();
        }else if(flag=="income"){
            query.prepare("select sum(i) from income");
            query.exec();
            query.next();
            return query.value(0).toString();
        }

    }else if(cat_id!=-1){
        if(flag=="check"){
            query.prepare("select sum(e_i) from record where cat_id=?");
            query.addBindValue(cat_id);
            query.exec();
            query.next();
            return query.value(0).toString();
        }else if(flag=="expense"){
            query.prepare("select sum(e) from expense where cat_id=?");
            query.addBindValue(cat_id);
            query.exec();
            query.next();
            return query.value(0).toString();
        }else if(flag=="income"){
            query.prepare("select sum(i) from income where cat_id=?");
            query.addBindValue(cat_id);
            query.exec();
            query.next();
            return query.value(0).toString();
        }
    }
    return 0;

}

//统计开支函数
bool TableDisplay::sortStock(QString cat,QString sort,QString flag)
{
    int cat_id=getcat_id(cat);
    if(cat_id==0)
    {
        if(flag=="升序"){
            if(sort=="按进价排序"){
                stockModel->setFilter("");
                stockModel->setSort(stockModel->fieldIndex("bid"),Qt::AscendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按售价排序"){
                stockModel->setFilter("");
                stockModel->setSort(stockModel->fieldIndex("price"),Qt::AscendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按数量排序"){
                stockModel->setFilter("");
                stockModel->setSort(stockModel->fieldIndex("sum"),Qt::AscendingOrder);
                stockModel->select();
                return true;
            }
        }else if(flag=="降序"){
            if(sort=="按进价排序"){
                stockModel->setFilter("");
                stockModel->setSort(stockModel->fieldIndex("bid"),Qt::DescendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按售价排序"){
                stockModel->setFilter("");
                stockModel->setSort(stockModel->fieldIndex("price"),Qt::DescendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按数量排序"){
                stockModel->setFilter("");
                stockModel->setSort(stockModel->fieldIndex("sum"),Qt::DescendingOrder);
                stockModel->select();
                return true;
            }
        }
    }else if(cat_id!=-1){
        if(flag=="升序"){
            if(sort=="按进价排序"){
                stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
                stockModel->setSort(stockModel->fieldIndex("bid"),Qt::AscendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按售价排序"){
                stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
                stockModel->setSort(stockModel->fieldIndex("price"),Qt::AscendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按数量排序"){
                stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
                stockModel->setSort(stockModel->fieldIndex("sum"),Qt::AscendingOrder);
                stockModel->select();
                return true;
            }
        }else if(flag=="降序"){
            if(sort=="按进价排序"){
                stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
                stockModel->setSort(stockModel->fieldIndex("bid"),Qt::DescendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按售价排序"){
                stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
                stockModel->setSort(stockModel->fieldIndex("price"),Qt::DescendingOrder);
                stockModel->select();
                return true;
            }else if(sort=="按数量排序"){
                stockModel->setFilter("stock.cat_id="+QString::number(cat_id));
                stockModel->setSort(stockModel->fieldIndex("sum"),Qt::DescendingOrder);
                stockModel->select();
                return true;
            }
        }
    }
    return false;
}


