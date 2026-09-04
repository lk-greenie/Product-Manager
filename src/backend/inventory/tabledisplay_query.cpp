#include "tabledisplay.h"

#include <QDebug>
#include <QMap>

namespace {
const QString kConnectionName = QStringLiteral("warehouse_connection");

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

    // “全部”只表示“不过滤”（cat_id=0）的语义，不应作为真实分类出现在分类表里。
    // 历史上该伪分类可能被插入过，这里顺带把遗留行清理掉，再刷新分类模型。
    QSqlQuery clean(db());
    clean.prepare("DELETE FROM category WHERE cat_name=?");
    clean.addBindValue(QStringLiteral("全部"));
    if (!clean.exec())
        qDebug() << "清理“全部”分类失败:" << clean.lastError().text();

    catModel->select();
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
    emit dataChanged();
    return QString();
}

QStringList TableDisplay::allCategories()
{
    QStringList names;
    names << QStringLiteral("全部");
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return names;

    QSqlQuery query(db());
    query.prepare("SELECT cat_name FROM category WHERE cat_name<>? ORDER BY cat_name");
    query.addBindValue(QStringLiteral("全部"));
    if (query.exec()) {
        while (query.next())
            names << query.value(0).toString();
    }
    return names;
}

QStringList TableDisplay::allProducts(const QString &category)
{
    QStringList names;
    names << QStringLiteral("全部");
    const int catId = getcat_id(category);
    if (catId < 0)
        return names;

    QSqlQuery query(db());
    query.prepare("SELECT DISTINCT cname FROM stock WHERE cat_id=? ORDER BY cname");
    query.addBindValue(catId);
    if (query.exec()) {
        while (query.next())
            names << query.value(0).toString();
    }
    return names;
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

    // 关系模型在 cat_id 上做了 LEFT JOIN(分类表)，裸用 cat_id 会产生歧义，
    // 必须用所属表名限定（record/expense/income），否则按具体分类过滤会查不到数据。
    QString table;
    if (flag == QStringLiteral("check"))
        table = QStringLiteral("record");
    else if (flag == QStringLiteral("expense"))
        table = QStringLiteral("expense");
    else if (flag == QStringLiteral("income"))
        table = QStringLiteral("income");

    QStringList filters;
    if (catId > 0)
        filters << QStringLiteral("%1.cat_id=%2").arg(table).arg(catId);
    if (!name.trimmed().isEmpty())
        filters << QStringLiteral("%1.cname LIKE %2").arg(table).arg(sqlQuote(QStringLiteral("%%1%").arg(name.trimmed())));
    if (start.isValid())
        filters << QStringLiteral("%1.t_time >= %2").arg(table).arg(sqlQuote(start.toString(Qt::ISODate)));
    if (end.isValid())
        filters << QStringLiteral("%1.t_time < %2").arg(table).arg(sqlQuote(end.addDays(1).toString(Qt::ISODate)));

    model->setFilter(filters.join(QStringLiteral(" AND ")));
    model->select();
    return true;
}

bool TableDisplay::sortRecords(const QString &flag, const QString &order)
{
    QSqlRelationalTableModel *model = modelForFlag(flag);
    if (!model || (order != QStringLiteral("升序") && order != QStringLiteral("降序")))
        return false;
    model->setSort(model->fieldIndex(QStringLiteral("t_time")),
                   order == QStringLiteral("升序") ? Qt::AscendingOrder : Qt::DescendingOrder);
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
                                          const QString &name, const QString &startDate,
                                          const QString &endDate)
{
    QMap<QString, double> values;

    QStringList filters;
    QVariantList bindings;
    if (!appendRecordFilters(filters, bindings, category, name, startDate, endDate))
        return {};
    const QString where = filters.isEmpty() ? QString()
                                            : QStringLiteral(" WHERE ") + filters.join(QStringLiteral(" AND "));

    const auto collectByProduct = [this, &values, &where, &bindings](const QString &table,
                                                                      const QString &amountColumn,
                                                                      double multiplier) {
        QSqlQuery query(db());
        query.prepare(QStringLiteral("SELECT cname, COALESCE(SUM(%1),0) FROM %2%3 GROUP BY cname")
                          .arg(amountColumn, table, where));
        for (const QVariant &binding : bindings)
            query.addBindValue(binding);
        if (!query.exec())
            return false;
        while (query.next())
            values[query.value(0).toString()] += multiplier * query.value(1).toDouble();
        return true;
    };

    if (metric == QStringLiteral("profit")) {
        // 利润以已售记录为口径：销售额 - 已售数量 × 商品进货成本。
        // 筛选条件只作用于 income，避免把同一时间范围内的新入库支出误当作销售成本。
        QStringList incomeFilters = filters;
        for (QString &filter : incomeFilters) {
            filter.replace(QStringLiteral("cat_id"), QStringLiteral("income.cat_id"));
            filter.replace(QStringLiteral("cname"), QStringLiteral("income.cname"));
            filter.replace(QStringLiteral("t_time"), QStringLiteral("income.t_time"));
        }
        const QString incomeWhere = incomeFilters.isEmpty() ? QString()
                : QStringLiteral(" WHERE ") + incomeFilters.join(QStringLiteral(" AND "));
        QSqlQuery query(db());
        query.prepare(QStringLiteral(
            "SELECT income.cname, COALESCE(SUM(income.i),0) "
            "- COALESCE(SUM(income.`sum` * costs.avg_bid),0) "
            "FROM income "
            "LEFT JOIN (SELECT cat_id, cname, AVG(bid) AS avg_bid "
            "FROM stock GROUP BY cat_id, cname) costs "
            "ON costs.cat_id=income.cat_id AND costs.cname=income.cname%1 "
            "GROUP BY income.cat_id, income.cname")
            .arg(incomeWhere));
        for (const QVariant &binding : bindings)
            query.addBindValue(binding);
        if (!query.exec())
            return {};
        while (query.next())
            values[query.value(0).toString()] = query.value(1).toDouble();
    } else {
        if (!collectByProduct(tableForMetric(metric), amountColumnForMetric(metric), 1.0))
            return {};
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

    QStringList filters;
    QVariantList bindings;
    if (!appendRecordFilters(filters, bindings, category, name, startDate, endDate))
        return {};
    const QString where = filters.isEmpty() ? QString()
                                            : QStringLiteral(" WHERE ") + filters.join(QStringLiteral(" AND "));

    const auto collectByTime = [this, &values, &format, &where, &bindings](const QString &table,
                                                                             const QString &amountColumn,
                                                                             double multiplier) {
        QSqlQuery query(db());
        query.prepare(QStringLiteral("SELECT DATE_FORMAT(t_time, '%1'), COALESCE(SUM(%2),0) FROM %3%4 GROUP BY 1 ORDER BY 1")
                          .arg(format, amountColumn, table, where));
        for (const QVariant &binding : bindings)
            query.addBindValue(binding);
        if (!query.exec())
            return false;
        while (query.next())
            values[query.value(0).toString()] += multiplier * query.value(1).toDouble();
        return true;
    };

    if (metric == QStringLiteral("profit")) {
        // 每个时间桶的利润使用该桶内已售商品的销售额减去销售成本。
        QStringList incomeFilters = filters;
        for (QString &filter : incomeFilters) {
            filter.replace(QStringLiteral("cat_id"), QStringLiteral("income.cat_id"));
            filter.replace(QStringLiteral("cname"), QStringLiteral("income.cname"));
            filter.replace(QStringLiteral("t_time"), QStringLiteral("income.t_time"));
        }
        const QString incomeWhere = incomeFilters.isEmpty() ? QString()
                : QStringLiteral(" WHERE ") + incomeFilters.join(QStringLiteral(" AND "));
        QSqlQuery query(db());
        query.prepare(QStringLiteral(
            "SELECT DATE_FORMAT(income.t_time, '%1'), COALESCE(SUM(income.i),0) "
            "- COALESCE(SUM(income.`sum` * costs.avg_bid),0) "
            "FROM income "
            "LEFT JOIN (SELECT cat_id, cname, AVG(bid) AS avg_bid "
            "FROM stock GROUP BY cat_id, cname) costs "
            "ON costs.cat_id=income.cat_id AND costs.cname=income.cname%2 "
            "GROUP BY 1 ORDER BY 1")
            .arg(format, incomeWhere));
        for (const QVariant &binding : bindings)
            query.addBindValue(binding);
        if (!query.exec())
            return {};
        while (query.next())
            values[query.value(0).toString()] = query.value(1).toDouble();
    } else {
        if (!collectByTime(tableForMetric(metric), amountColumnForMetric(metric), 1.0))
            return {};
    }

    QVariantList result;
    for (auto it = values.cbegin(); it != values.cend(); ++it)
        result << QVariantMap{{QStringLiteral("label"), it.key()}, {QStringLiteral("value"), it.value()}};
    return result;
}
