#include "tabledisplay.h"

#include <QDebug>

namespace {
const QString kConnectionName = QStringLiteral("warehouse_connection");
const QString kExpenseType = QStringLiteral("支出");
}

bool TableDisplay::parsePositiveInt(const QString &value, int &result)
{
    bool ok = false;
    const int parsed = value.trimmed().toInt(&ok);
    if (!ok || parsed <= 0)
        return false;
    result = parsed;
    return true;
}

bool TableDisplay::parseNonNegativeReal(const QString &value, qreal &result)
{
    bool ok = false;
    const qreal parsed = value.trimmed().toDouble(&ok);
    if (!ok || parsed < 0)
        return false;
    result = parsed;
    return true;
}

void TableDisplay::setCurrentPermission(int permission)
{
    m_currentPermission = permission >= 1 && permission <= 3 ? permission : 3;
}

bool TableDisplay::inCommodity(QString cat, QString cname, QString sum, QString bid,
                               QString m_date, QString e_date)
{
    if (!canManageInventory()) {
        qDebug() << "入库失败：当前角色没有权限";
        return false;
    }

    const int catId = getcat_id(cat);
    int quantity = 0;
    qreal purchasePrice = 0;
    if (!validCat(catId) || cname.trimmed().isEmpty()
        || !parsePositiveInt(sum, quantity)
        || !parseNonNegativeReal(bid, purchasePrice)) {
        qDebug() << "入库失败：分类、商品名、数量或进价无效";
        return false;
    }

    const QDate manufactureDate = QDate::fromString(m_date, QStringLiteral("yyyy-MM-dd"));
    const QDate expiryDate = QDate::fromString(e_date, QStringLiteral("yyyy-MM-dd"));
    if (!manufactureDate.isValid() || !expiryDate.isValid() || expiryDate < manufactureDate) {
        qDebug() << "入库失败：日期无效" << m_date << e_date;
        return false;
    }

    QSqlDatabase activeDb = db();
    if (!activeDb.isOpen() || !activeDb.transaction()) {
        qDebug() << "开启入库事务失败:" << activeDb.lastError().text();
        return false;
    }

    QSqlQuery query(activeDb);
    query.prepare("select 1 from stock where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
    query.addBindValue(catId);
    query.addBindValue(cname.trimmed());
    query.addBindValue(purchasePrice);
    query.addBindValue(manufactureDate);
    query.addBindValue(expiryDate);
    if (!query.exec()) {
        qDebug() << "查找商品失败:" << query.lastError().text();
        activeDb.rollback();
        return false;
    }

    if (query.next()) {
        query.prepare("update stock set sum=sum+? where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
        query.addBindValue(quantity);
        query.addBindValue(catId);
        query.addBindValue(cname.trimmed());
        query.addBindValue(purchasePrice);
        query.addBindValue(manufactureDate);
        query.addBindValue(expiryDate);
    } else {
        query.prepare("insert into stock(cat_id,cname,bid,m_date,e_date,sum) values(?,?,?,?,?,?)");
        query.addBindValue(catId);
        query.addBindValue(cname.trimmed());
        query.addBindValue(purchasePrice);
        query.addBindValue(manufactureDate);
        query.addBindValue(expiryDate);
        query.addBindValue(quantity);
    }

    if (!query.exec() || !addCheck(catId, cname.trimmed(), purchasePrice, quantity, kExpenseType)) {
        qDebug() << "入库写入失败:" << query.lastError().text();
        activeDb.rollback();
        return false;
    }
    if (!activeDb.commit()) {
        qDebug() << "入库提交失败:" << activeDb.lastError().text();
        activeDb.rollback();
        return false;
    }

    stockModel->select();
    checkModel->select();
    expenseModel->select();
    emit dataChanged();
    return true;
}

bool TableDisplay::addCheck(int catId, const QString &cname, qreal price, int sum,
                            const QString &recordType)
{
    if (!QSqlDatabase::contains(kConnectionName))
        return false;

    QSqlDatabase activeDb = db();
    if (!activeDb.isOpen())
        return false;

    const bool isExpense = recordType == kExpenseType;
    QSqlQuery query(activeDb);
    query.prepare("insert into record(cat_id,cname,b_p,sum,e_i) values(?,?,?,?,?)");
    query.addBindValue(catId);
    query.addBindValue(cname);
    query.addBindValue(price);
    query.addBindValue(sum);
    query.addBindValue(isExpense ? -price * sum : price * sum);
    if (!query.exec()) {
        qDebug() << "插入总交易记录失败:" << query.lastError().text();
        return false;
    }

    query.prepare(isExpense
                      ? "insert into expense(cat_id,cname,b,sum,e) values(?,?,?,?,?)"
                      : "insert into income(cat_id,cname,p,sum,i) values(?,?,?,?,?)");
    query.addBindValue(catId);
    query.addBindValue(cname);
    query.addBindValue(price);
    query.addBindValue(sum);
    query.addBindValue(price * sum);
    if (!query.exec()) {
        qDebug() << "插入收支明细失败:" << query.lastError().text();
        return false;
    }
    return true;
}

bool TableDisplay::outCommodity(QString cat, QString cname, QString sum, QString price)
{
    if (!canManageInventory()) {
        qDebug() << "出库失败：当前角色没有权限";
        return false;
    }

    const int catId = getcat_id(cat);
    int quantity = 0;
    qreal salePrice = 0;
    if (!validCat(catId) || cname.trimmed().isEmpty()
        || !parsePositiveInt(sum, quantity)
        || !parseNonNegativeReal(price, salePrice)) {
        qDebug() << "出库失败：分类、商品名、数量或售价无效";
        return false;
    }

    QSqlDatabase activeDb = db();
    if (!activeDb.isOpen() || !activeDb.transaction()) {
        qDebug() << "开启出库事务失败:" << activeDb.lastError().text();
        return false;
    }

    QSqlQuery totalQuery(activeDb);
    totalQuery.prepare("select coalesce(sum(sum),0) from stock where cat_id=? and cname=?");
    totalQuery.addBindValue(catId);
    totalQuery.addBindValue(cname.trimmed());
    if (!totalQuery.exec() || !totalQuery.next() || totalQuery.value(0).toInt() < quantity) {
        qDebug() << "出库失败：库存数量不足" << totalQuery.lastError().text();
        activeDb.rollback();
        return false;
    }

    QSqlQuery batches(activeDb);
    batches.prepare("select bid,m_date,e_date,sum from stock where cat_id=? and cname=? "
                    "order by e_date asc,m_date asc,bid asc");
    batches.addBindValue(catId);
    batches.addBindValue(cname.trimmed());
    if (!batches.exec()) {
        qDebug() << "查询库存批次失败:" << batches.lastError().text();
        activeDb.rollback();
        return false;
    }

    int remaining = quantity;
    QSqlQuery writeQuery(activeDb);
    while (batches.next() && remaining > 0) {
        const int batchQuantity = batches.value("sum").toInt();
        const int deduction = qMin(remaining, batchQuantity);
        if (deduction == batchQuantity) {
            writeQuery.prepare("delete from stock where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
        } else {
            writeQuery.prepare("update stock set sum=sum-? where cat_id=? and cname=? and bid=? and m_date=? and e_date=?");
            writeQuery.addBindValue(deduction);
        }
        writeQuery.addBindValue(catId);
        writeQuery.addBindValue(cname.trimmed());
        writeQuery.addBindValue(batches.value("bid"));
        writeQuery.addBindValue(batches.value("m_date"));
        writeQuery.addBindValue(batches.value("e_date"));
        if (!writeQuery.exec()) {
            qDebug() << "扣减库存失败:" << writeQuery.lastError().text();
            activeDb.rollback();
            return false;
        }
        remaining -= deduction;
    }

    if (remaining != 0 || !addCheck(catId, cname.trimmed(), salePrice, quantity,
                                     QStringLiteral("收入"))) {
        activeDb.rollback();
        return false;
    }
    if (!activeDb.commit()) {
        qDebug() << "出库提交失败:" << activeDb.lastError().text();
        activeDb.rollback();
        return false;
    }

    stockModel->select();
    checkModel->select();
    incomeModel->select();
    emit dataChanged();
    return true;
}

QString TableDisplay::getPrice(QString cat, QString cname)
{
    const int catId = getcat_id(cat);
    if (!validCat(catId))
        return QString();

    QSqlQuery query(db());
    query.prepare("select price from stock where cat_id=? and cname=? limit 1");
    query.addBindValue(catId);
    query.addBindValue(cname);
    return query.exec() && query.next() ? query.value("price").toString() : QString();
}

bool TableDisplay::setPrice(QString cat, QString cname, QString price)
{
    if (!canChangeSettings()) {
        qDebug() << "更新售价失败：当前角色没有权限";
        return false;
    }

    const int catId = getcat_id(cat);
    qreal parsedPrice = 0;
    if (!validCat(catId) || cname.trimmed().isEmpty()
        || !parseNonNegativeReal(price, parsedPrice))
        return false;

    QSqlQuery query(db());
    query.prepare("update stock set price=? where cat_id=? and cname=?");
    query.addBindValue(parsedPrice);
    query.addBindValue(catId);
    query.addBindValue(cname.trimmed());
    if (!query.exec()) {
        qDebug() << "更新售价失败:" << query.lastError().text();
        return false;
    }
    stockModel->select();
    emit dataChanged();
    return true;
}

bool TableDisplay::setLimits(QString cat, QString cname, QString up_sum, QString down_sum)
{
    if (!canChangeSettings()) {
        qDebug() << "更新警告值失败：当前角色没有权限";
        return false;
    }

    const int catId = getcat_id(cat);
    int upperLimit = 0;
    int lowerLimit = 0;
    bool upperOk = false;
    bool lowerOk = false;
    upperLimit = up_sum.trimmed().toInt(&upperOk);
    lowerLimit = down_sum.trimmed().toInt(&lowerOk);
    if (!validCat(catId) || cname.trimmed().isEmpty() || !upperOk || !lowerOk
        || lowerLimit < 0 || upperLimit < lowerLimit)
        return false;

    QSqlQuery query(db());
    query.prepare("update stock set up_sum=?,down_sum=? where cat_id=? and cname=?");
    query.addBindValue(upperLimit);
    query.addBindValue(lowerLimit);
    query.addBindValue(catId);
    query.addBindValue(cname.trimmed());
    if (!query.exec()) {
        qDebug() << "更新警告值失败:" << query.lastError().text();
        return false;
    }
    stockModel->select();
    emit dataChanged();
    return true;
}
