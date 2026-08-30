#include "tabledisplay.h"

#include <QDebug>
#include <QMap>

namespace {
const QString kConnectionName = QStringLiteral("ecjtu_market_connection");

QString sqlQuote(QString value)
{
    return QStringLiteral("'") + value.replace("'", "''") + QStringLiteral("'");
}

QString tableForMetric(const QString &metric)
{
    if (metric == QStringLiteral("cost"))
        return QStringLiteral("expense");
    if (metric == QStringLiteral("sales"))
        return QStringLiteral("income");
    return QString();
}

QString amountColumnForMetric(const QString &metric)
{
    if (metric == QStringLiteral("cost"))
        return QStringLiteral("e");
    if (metric == QStringLiteral("sales"))
        return QStringLiteral("i");
    return QString();
}
}

bool TableDisplay::init_Cat()
{
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return false;

    QSqlQuery query(db());
    query.prepare("SELECT 1 FROM category WHERE cat_name=?");
    query.addBindValue(QStringLiteral("全部"));
    if (!query.exec())
        return false;

    if (!query.next()) {
        query.prepare("INSERT INTO category(cat_name) VALUES(?)");
        query.addBindValue(QStringLiteral("全部"));
        if (!query.exec())
            return false;
        catModel->select();
    }
    return true;
}

QString TableDisplay::addCat(QString cat)
{
    if (!canAddCategory())
        return QStringLiteral("当前角色没有添加分类权限！");

    cat = cat.trimmed();
    if (cat.isEmpty() || isAllCategory(cat))
        return QStringLiteral("分类名不能为空或为保留名称！");
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return QStringLiteral("数据库未打开！");

    QSqlQuery query(db());
    query.prepare("SELECT cat_id FROM category WHERE cat_name=?");
    query.addBindValue(cat);
    if (!query.exec())
        return QStringLiteral("查询分类失败：%1").arg(query.lastError().text());
    if (query.next())
        return QStringLiteral("分类已存在，请勿重复添加！");

    query.prepare("INSERT INTO category(cat_name) VALUES(?)");
    query.addBindValue(cat);
    if (!query.exec())
        return QStringLiteral("添加分类失败：%1").arg(query.lastError().text());

    catModel->select();
    return QString();
}

int TableDisplay::getcat_id(const QString &cat)
{
    if (isAllCategory(cat))
        return 0;
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return -1;

    QSqlQuery query(db());
    query.prepare("SELECT cat_id FROM category WHERE cat_name=?");
    query.addBindValue(cat.trimmed());
    if (!query.exec() || !query.next())
        return -1;
    return query.value(0).toInt();
}

bool TableDisplay::isAllCategory(const QString &cat)
{
    return cat.trimmed() == QStringLiteral("全部");
}

bool TableDisplay::parseDateRange(const QString &startDate, const QString &endDate,
                                  QDate &start, QDate &end)
{
    start = startDate.trimmed().isEmpty() ? QDate() : QDate::fromString(startDate, "yyyy-MM-dd");
    end = endDate.trimmed().isEmpty() ? QDate() : QDate::fromString(endDate, "yyyy-MM-dd");
    return (!startDate.trimmed().isEmpty() && !start.isValid()) ||
                   (!endDate.trimmed().isEmpty() && !end.isValid()) ||
                   (start.isValid() && end.isValid() && start > end)
               ? false
               : true;
}

bool TableDisplay::appendRecordFilters(QStringList &filters, QVariantList &values,
                                       const QString &category, const QString &name,
                                       const QString &startDate, const QString &endDate) const
{
    QDate start;
    QDate end;
    if (!parseDateRange(startDate, endDate, start, end))
        return false;

    const int catId = const_cast<TableDisplay *>(this)->getcat_id(category);
    if (catId < 0)
        return false;
    if (catId > 0) {
        filters << QStringLiteral("cat_id=?");
        values << catId;
    }
    if (!name.trimmed().isEmpty()) {
        filters << QStringLiteral("cname LIKE ?");
        values << QStringLiteral("%%1%").arg(name.trimmed());
    }
    if (start.isValid()) {
        filters << QStringLiteral("t_time>=?");
        values << start.startOfDay();
    }
    if (end.isValid()) {
        filters << QStringLiteral("t_time<?");
        values << end.addDays(1).startOfDay();
    }
    return true;
}

QSqlRelationalTableModel *TableDisplay::modelForFlag(const QString &flag) const
{
    if (flag == QStringLiteral("check"))
        return checkModel;
    if (flag == QStringLiteral("expense"))
        return expenseModel;
    if (flag == QStringLiteral("income"))
        return incomeModel;
    return nullptr;
}

QSortFilterProxyModel *TableDisplay::proxyForFlag(const QString &flag) const
{
    if (flag == QStringLiteral("check"))
        return proxyModel1;
    if (flag == QStringLiteral("expense"))
        return proxyModel2;
    if (flag == QStringLiteral("income"))
        return proxyModel3;
    return nullptr;
}

QString TableDisplay::sumCat(QString cat)
{
    const int catId = getcat_id(cat);
    if (!validCat(catId))
        return QString();

    QSqlQuery query(db());
    query.prepare("SELECT COUNT(DISTINCT cname) FROM stock WHERE cat_id=?");
    query.addBindValue(catId);
    return query.exec() && query.next() ? query.value(0).toString() : QStringLiteral("0");
}

QString TableDisplay::sumC(QString cat, QString cname)
{
    const int catId = getcat_id(cat);
    if (!validCat(catId) || cname.trimmed().isEmpty())
        return QString();

    QSqlQuery query(db());
    query.prepare("SELECT COALESCE(SUM(sum), 0) FROM stock WHERE cat_id=? AND cname=?");
    query.addBindValue(catId);
    query.addBindValue(cname.trimmed());
    return query.exec() && query.next() ? query.value(0).toString() : QStringLiteral("0");
}

QString TableDisplay::sumCheck(QString cat, QString flag)
{
    return sumFilteredRecords(flag, cat, QString(), QString(), QString());
}

bool TableDisplay::filterRecords(const QString &flag, const QString &category,
                                 const QString &name, const QString &startDate,
                                 const QString &endDate)
{
    QSqlRelationalTableModel *model = modelForFlag(flag);
    if (!model)
        return false;

    QDate start;
    QDate end;
    if (!parseDateRange(startDate, endDate, start, end))
        return false;
    const int catId = getcat_id(category);
    if (catId < 0)
        return false;

    QStringList filters;
    if (catId > 0)
        filters << QStringLiteral("cat_id=%1").arg(catId);
    if (!name.trimmed().isEmpty())
        filters << QStringLiteral("cname LIKE %1").arg(sqlQuote(QStringLiteral("%%1%").arg(name.trimmed())));
    if (start.isValid())
        filters << QStringLiteral("t_time >= %1").arg(sqlQuote(start.toString(Qt::ISODate)));
    if (end.isValid())
        filters << QStringLiteral("t_time < %1").arg(sqlQuote(end.addDays(1).toString(Qt::ISODate)));

    model->setFilter(filters.join(QStringLiteral(" AND ")));
    model->select();
    return true;
}

QString TableDisplay::sumFilteredRecords(const QString &flag, const QString &category,
                                         const QString &name, const QString &startDate,
                                         const QString &endDate)
{
    QString table;
    QString column;
    if (flag == QStringLiteral("check")) {
        table = QStringLiteral("record");
        column = QStringLiteral("e_i");
    } else if (flag == QStringLiteral("expense")) {
        table = QStringLiteral("expense");
        column = QStringLiteral("e");
    } else if (flag == QStringLiteral("income")) {
        table = QStringLiteral("income");
        column = QStringLiteral("i");
    } else {
        return QString();
    }

    QStringList filters;
    QVariantList values;
    if (!appendRecordFilters(filters, values, category, name, startDate, endDate))
        return QString();

    QSqlQuery query(db());
    query.prepare(QStringLiteral("SELECT COALESCE(SUM(%1), 0) FROM %2%3")
                      .arg(column, table, filters.isEmpty() ? QString() : QStringLiteral(" WHERE ") + filters.join(QStringLiteral(" AND "))));
    for (const QVariant &value : values)
        query.addBindValue(value);
    return query.exec() && query.next() ? query.value(0).toString() : QStringLiteral("0");
}

QVariantMap TableDisplay::productInfo(const QString &category, const QString &name)
{
    QVariantMap result;
    const int catId = getcat_id(category);
    if (!validCat(catId) || name.trimmed().isEmpty())
        return result;

    QSqlQuery query(db());
    query.prepare("SELECT COALESCE(AVG(bid),0), COALESCE(MAX(price),0), "
                  "COALESCE(MAX(up_sum),0), COALESCE(MAX(down_sum),0), COALESCE(SUM(sum),0) "
                  "FROM stock WHERE cat_id=? AND cname=?");
    query.addBindValue(catId);
    query.addBindValue(name.trimmed());
    if (!query.exec() || !query.next())
        return result;

    result.insert(QStringLiteral("purchasePrice"), query.value(0));
    result.insert(QStringLiteral("salePrice"), query.value(1));
    result.insert(QStringLiteral("upperLimit"), query.value(2));
    result.insert(QStringLiteral("lowerLimit"), query.value(3));
    result.insert(QStringLiteral("quantity"), query.value(4));
    return result;
}

QVariantList TableDisplay::chartBreakdown(const QString &metric, const QString &category,
                                          const QString &startDate, const QString &endDate)
{
    QMap<QString, double> values;
    const QStringList metrics = metric == QStringLiteral("profit")
                                    ? QStringList{QStringLiteral("sales"), QStringLiteral("cost")}
                                    : QStringList{metric};

    for (const QString &currentMetric : metrics) {
        const QString currentTable = tableForMetric(currentMetric);
        const QString currentColumn = amountColumnForMetric(currentMetric);
        QStringList filters;
        QVariantList bindings;
        if (!appendRecordFilters(filters, bindings, category, QString(), startDate, endDate))
            return {};

        QSqlQuery query(db());
        query.prepare(QStringLiteral("SELECT cname, COALESCE(SUM(%1),0) FROM %2%3 GROUP BY cname ORDER BY 2 DESC")
                          .arg(currentColumn, currentTable,
                               filters.isEmpty() ? QString() : QStringLiteral(" WHERE ") + filters.join(QStringLiteral(" AND "))));
        for (const QVariant &binding : bindings)
            query.addBindValue(binding);
        if (!query.exec())
            return {};
        while (query.next()) {
            const double signedValue = query.value(1).toDouble() * (currentMetric == QStringLiteral("cost") && metric == QStringLiteral("profit") ? -1.0 : 1.0);
            values[query.value(0).toString()] += signedValue;
        }
    }

    QVariantList result;
    for (auto it = values.cbegin(); it != values.cend(); ++it)
        result << QVariantMap{{QStringLiteral("label"), it.key()}, {QStringLiteral("value"), it.value()}};
    return result;
}

QVariantList TableDisplay::chartTrend(const QString &metric, const QString &category,
                                      const QString &name, const QString &scale,
                                      const QString &startDate, const QString &endDate)
{
    const QString format = scale == QStringLiteral("year") ? QStringLiteral("%Y")
                         : scale == QStringLiteral("month") ? QStringLiteral("%Y-%m")
                         : QStringLiteral("%Y-%m-%d");
    QMap<QString, double> values;
    const QStringList metrics = metric == QStringLiteral("profit")
                                    ? QStringList{QStringLiteral("sales"), QStringLiteral("cost")}
                                    : QStringList{metric};

    for (const QString &currentMetric : metrics) {
        QStringList filters;
        QVariantList bindings;
        if (!appendRecordFilters(filters, bindings, category, name, startDate, endDate))
            return {};
        QSqlQuery query(db());
        query.prepare(QStringLiteral("SELECT DATE_FORMAT(t_time, ?), COALESCE(SUM(%1),0) FROM %2%3 GROUP BY 1 ORDER BY 1")
                          .arg(amountColumnForMetric(currentMetric), tableForMetric(currentMetric),
                               filters.isEmpty() ? QString() : QStringLiteral(" WHERE ") + filters.join(QStringLiteral(" AND "))));
        query.addBindValue(format);
        for (const QVariant &binding : bindings)
            query.addBindValue(binding);
        if (!query.exec())
            return {};
        while (query.next()) {
            const double signedValue = query.value(1).toDouble() * (currentMetric == QStringLiteral("cost") && metric == QStringLiteral("profit") ? -1.0 : 1.0);
            values[query.value(0).toString()] += signedValue;
        }
    }

    QVariantList result;
    for (auto it = values.cbegin(); it != values.cend(); ++it)
        result << QVariantMap{{QStringLiteral("label"), it.key()}, {QStringLiteral("value"), it.value()}};
    return result;
}
