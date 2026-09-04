#include "tabledisplay.h"

#include <QDebug>

namespace {
const QString kConnectionName = QStringLiteral("warehouse_connection");
const QString kNoAccess = QStringLiteral("当前角色无权限查看该数据。");
}

// 商品分类列表。所有角色均可查看（库存管理页分类筛选对所有角色可见）。
QString TableDisplay::aiCategories() const
{
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return QString();

    QStringList names;
    QSqlQuery query(db());
    query.prepare("SELECT cat_name FROM category WHERE cat_name<>? ORDER BY cat_name");
    query.addBindValue(QStringLiteral("全部"));
    if (query.exec()) {
        while (query.next())
            names << query.value(0).toString();
    }
    if (names.isEmpty())
        return QStringLiteral("暂无商品分类。");
    return QStringLiteral("商品分类：%1。").arg(names.join(QStringLiteral("、")));
}

// 库存数据。
//   - 顾客访客：仅返回库存管理页面展示的公开列（分类/商品名/生产日期/保质日期/售价/数量）。
//   - 店主/店员：返回完整数据（分类汇总、库存明细含进价与上下限、低库存提醒）。
QString TableDisplay::aiInventory() const
{
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return QString();

    const bool isVisitor = (m_currentPermission == 3);
    QStringList lines;
    int totalQty = 0;

    if (isVisitor) {
        lines << QStringLiteral("库存商品（分类 / 商品名 / 生产日期 / 保质日期 / 售价 / 数量）：");
        QSqlQuery stock(db());
        stock.prepare("SELECT c.cat_name, s.cname, "
                      "DATE_FORMAT(s.m_date,'%Y-%m-%d'), DATE_FORMAT(s.e_date,'%Y-%m-%d'), "
                      "s.price, s.sum "
                      "FROM stock s LEFT JOIN category c ON s.cat_id=c.cat_id "
                      "ORDER BY c.cat_name, s.cname");
        bool any = false;
        if (stock.exec()) {
            while (stock.next()) {
                any = true;
                totalQty += stock.value(5).toInt();
                lines << QStringLiteral("  - %1 | %2 | 生产%3 | 保质%4 | 售价%5 | 数量%6")
                         .arg(stock.value(0).toString())
                         .arg(stock.value(1).toString())
                         .arg(stock.value(2).toString())
                         .arg(stock.value(3).toString())
                         .arg(stock.value(4).toString())
                         .arg(stock.value(5).toString());
            }
        }
        if (!any)
            lines << QStringLiteral("  暂无商品。");
        lines << QStringLiteral("商品总数量：%1。").arg(totalQty);
        return lines.join(QLatin1Char('\n'));
    }

    // 一、按分类汇总
    lines << QStringLiteral("一、库存汇总（按分类：商品种数 / 总数量 / 总进价成本）：");
    {
        QSqlQuery stock(db());
        stock.prepare("SELECT c.cat_name, COUNT(DISTINCT s.cname), COALESCE(SUM(s.sum),0), "
                      "COALESCE(SUM(s.bid*s.sum),0) "
                      "FROM stock s LEFT JOIN category c ON s.cat_id=c.cat_id "
                      "GROUP BY c.cat_name ORDER BY c.cat_name");
        bool any = false;
        if (stock.exec()) {
            while (stock.next()) {
                any = true;
                totalQty += stock.value(2).toInt();
                lines << QStringLiteral("  - 分类[%1]：商品 %2 种，数量 %3，进价成本 %4")
                         .arg(stock.value(0).toString())
                         .arg(stock.value(1).toString())
                         .arg(stock.value(2).toString())
                         .arg(stock.value(3).toString());
            }
        }
        if (!any)
            lines << QStringLiteral("  暂无库存。");
    }

    // 二、库存明细
    lines << QStringLiteral("二、库存明细（分类 / 商品名 / 进价 / 售价 / 数量 / 生产日期 / 保质日期 / 上限 / 下限）：");
    {
        QSqlQuery stock(db());
        stock.prepare("SELECT c.cat_name, s.cname, s.bid, s.price, s.sum, "
                      "DATE_FORMAT(s.m_date,'%Y-%m-%d'), DATE_FORMAT(s.e_date,'%Y-%m-%d'), "
                      "s.up_sum, s.down_sum "
                      "FROM stock s LEFT JOIN category c ON s.cat_id=c.cat_id "
                      "ORDER BY c.cat_name, s.cname");
        bool any = false;
        if (stock.exec()) {
            while (stock.next()) {
                any = true;
                totalQty += stock.value(4).toInt();
                lines << QStringLiteral("  - %1 | %2 | 进价%3 | 售价%4 | 数量%5 | 生产%6 | 保质%7 | 上限%8 | 下限%9")
                         .arg(stock.value(0).toString())
                         .arg(stock.value(1).toString())
                         .arg(stock.value(2).toString())
                         .arg(stock.value(3).toString())
                         .arg(stock.value(4).toString())
                         .arg(stock.value(5).toString())
                         .arg(stock.value(6).toString())
                         .arg(stock.value(7).toString())
                         .arg(stock.value(8).toString());
            }
        }
        if (!any)
            lines << QStringLiteral("  暂无库存记录。");
    }

    // 三、低库存提醒
    lines << QStringLiteral("三、低库存提醒（数量小于下限值）：");
    bool anyLow = false;
    {
        QSqlQuery low(db());
        low.prepare("SELECT c.cat_name, s.cname, s.sum, s.down_sum "
                    "FROM stock s LEFT JOIN category c ON s.cat_id=c.cat_id "
                    "WHERE s.down_sum > 0 AND s.sum < s.down_sum ORDER BY s.sum");
        if (low.exec()) {
            while (low.next()) {
                anyLow = true;
                lines << QStringLiteral("  - %1 | %2 | 当前数量 %3，低于下限 %4")
                         .arg(low.value(0).toString())
                         .arg(low.value(1).toString())
                         .arg(low.value(2).toString())
                         .arg(low.value(3).toString());
            }
        }
    }
    if (!anyLow)
        lines << QStringLiteral("  暂无低于下限的商品。");

    lines << QStringLiteral("商品总数量：%1。").arg(totalQty);
    return lines.join(QLatin1Char('\n'));
}

// 全部交易/收支记录（record 表）。仅店主/店员可用；顾客访客返回无权限提示。
QString TableDisplay::aiTransactions() const
{
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return QString();
    if (m_currentPermission == 3)
        return kNoAccess;

    QStringList lines;
    int total = 0;
    lines << QStringLiteral("交易记录（分类 / 商品名 / 单价 / 数量 / 金额 / 时间）：");
    QSqlQuery query(db());
    query.prepare("SELECT c.cat_name, r.cname, r.b_p, r.sum, r.e_i, "
                  "DATE_FORMAT(r.t_time,'%Y-%m-%d %H:%i:%s') "
                  "FROM record r LEFT JOIN category c ON r.cat_id=c.cat_id "
                  "ORDER BY r.t_time, r.e_i");
    if (query.exec()) {
        while (query.next()) {
            ++total;
            lines << QStringLiteral("  - %1 | %2 | 单价%3 | 数量%4 | 金额%5 | %6")
                     .arg(query.value(0).toString())
                     .arg(query.value(1).toString())
                     .arg(query.value(2).toString())
                     .arg(query.value(3).toString())
                     .arg(query.value(4).toString())
                     .arg(query.value(5).toString());
        }
    }
    lines << QStringLiteral("共 %1 条交易记录。").arg(total);
    return lines.join(QLatin1Char('\n'));
}

// 收入/支出/净收入汇总。仅店主/店员可用。
QString TableDisplay::aiFinancialSummary() const
{
    if (!QSqlDatabase::contains(kConnectionName) || !db().isOpen())
        return QString();
    if (m_currentPermission == 3)
        return kNoAccess;

    double grossIncome = 0.0;
    double grossExpense = 0.0;
    {
        QSqlQuery income(db());
        income.prepare("SELECT COALESCE(SUM(i),0) FROM income");
        if (income.exec() && income.next())
            grossIncome = income.value(0).toDouble();
        QSqlQuery expense(db());
        expense.prepare("SELECT COALESCE(SUM(e),0) FROM expense");
        if (expense.exec() && expense.next())
            grossExpense = expense.value(0).toDouble();
    }
    return QStringLiteral("总收入：%1；总支出：%2；净收入：%3。")
        .arg(QString::number(grossIncome))
        .arg(QString::number(grossExpense))
        .arg(QString::number(grossIncome - grossExpense));
}
