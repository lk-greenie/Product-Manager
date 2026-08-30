pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property string stockFlag: "stock"
    readonly property string checkFlag: "check"
    readonly property string expenseFlag: "expense"
    readonly property string incomeFlag: "income"

    readonly property string sortByPurchasePrice: "按进价排序"
    readonly property string sortBySalePrice: "按售价排序"
    readonly property string sortByQuantity: "按数量排序"
    readonly property string ascending: "升序"
    readonly property string descending: "降序"

    readonly property int ownerPermission: 1
    readonly property int staffPermission: 2
    readonly property int visitorPermission: 3

    function isOwner(permission) {
        return permission === ownerPermission
    }

    function isStaff(permission) {
        return permission === staffPermission
    }

    function isVisitor(permission) {
        return permission === visitorPermission
    }

    function canAddCategory(permission) {
        return isOwner(permission)
    }

    function canInOutStock(permission) {
        return isOwner(permission) || isStaff(permission)
    }

    function canChangeStockSettings(permission) {
        return isOwner(permission)
    }

    function canViewRecords(permission) {
        return !isVisitor(permission)
    }

    function canViewVisualization(permission) {
        return !isVisitor(permission)
    }

    function canViewPrivateStockColumns(permission) {
        return !isVisitor(permission)
    }

    function canUseAI(permission) {
        return permission >= ownerPermission && permission <= visitorPermission
    }

    function canViewRoute(permission, route) {
        if (route === stockFlag || route === "assistant")
            return true
        if (route.indexOf("records.") === 0)
            return canViewRecords(permission)
        if (route.indexOf("visual.") === 0)
            return canViewVisualization(permission)
        return false
    }
}
