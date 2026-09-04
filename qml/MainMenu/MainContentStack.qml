import QtQuick 2.15
import QtQuick.Controls 2.15
import "../StockManagement" as StockManagement
import "../CheckRecords" as CheckRecords
import "../DataVisualization" as DataVisualization
import "../AIAssistant" as AIAssistant
import "../Person" as Person
import "../Services"

Item {
    id: root

    property string route: "stock"
    readonly property var routes: [
        "stock",
        "records.all",
        "records.expense",
        "records.income",
        "visual.profit",
        "visual.cost",
        "visual.sales",
        "assistant",
        "profile"
    ]

    function routeToIndex(value) {
        const index = routes.indexOf(value)
        return index >= 0 ? index : 0
    }

    function componentForRoute(value) {
        switch (value) {
        case "records.all": return recordsComponent
        case "records.expense": return expenseComponent
        case "records.income": return incomeComponent
        case "visual.profit": return profitComponent
        case "visual.cost": return costComponent
        case "visual.sales": return salesComponent
        case "assistant": return assistantComponent
        case "profile": return profileComponent
        default: return stockComponent
        }
    }

    // 页面首次访问时才实例化；访问过的页面保持 Loader.item，切换回来时保留筛选、滚动和展开状态。
    Component { id: stockComponent; StockManagement.DisplayPage {} }
    Component { id: recordsComponent; CheckRecords.CheckPage {} }
    Component { id: expenseComponent; CheckRecords.ExpensePage {} }
    Component { id: incomeComponent; CheckRecords.IncomePage {} }
    Component { id: profitComponent; DataVisualization.ProfitVisualization {} }
    Component { id: costComponent; DataVisualization.CostVisualization {} }
    Component { id: salesComponent; DataVisualization.SalesVisualization {} }
    Component { id: assistantComponent; AIAssistant.AIPage {} }
    Component { id: profileComponent; Person.Me { onLogoutRequested: root.logoutRequested() } }

    signal logoutRequested()

    property string effectiveRoute: BackendContract.canViewRoute(loginManager.per, root.route)
                                    ? root.route : "stock"

    Loader { id: stockLoader; anchors.fill: parent; asynchronous: true; active: stockLoader.loaded || root.effectiveRoute === "stock"; sourceComponent: stockComponent; visible: root.effectiveRoute === "stock"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: recordsLoader; anchors.fill: parent; asynchronous: true; active: recordsLoader.loaded || root.effectiveRoute === "records.all"; sourceComponent: recordsComponent; visible: root.effectiveRoute === "records.all"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: expenseLoader; anchors.fill: parent; asynchronous: true; active: expenseLoader.loaded || root.effectiveRoute === "records.expense"; sourceComponent: expenseComponent; visible: root.effectiveRoute === "records.expense"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: incomeLoader; anchors.fill: parent; asynchronous: true; active: incomeLoader.loaded || root.effectiveRoute === "records.income"; sourceComponent: incomeComponent; visible: root.effectiveRoute === "records.income"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: profitLoader; anchors.fill: parent; asynchronous: true; active: profitLoader.loaded || root.effectiveRoute === "visual.profit"; sourceComponent: profitComponent; visible: root.effectiveRoute === "visual.profit"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: costLoader; anchors.fill: parent; asynchronous: true; active: costLoader.loaded || root.effectiveRoute === "visual.cost"; sourceComponent: costComponent; visible: root.effectiveRoute === "visual.cost"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: salesLoader; anchors.fill: parent; asynchronous: true; active: salesLoader.loaded || root.effectiveRoute === "visual.sales"; sourceComponent: salesComponent; visible: root.effectiveRoute === "visual.sales"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: assistantLoader; anchors.fill: parent; asynchronous: true; active: assistantLoader.loaded || root.effectiveRoute === "assistant"; sourceComponent: assistantComponent; visible: root.effectiveRoute === "assistant"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }
    Loader { id: profileLoader; anchors.fill: parent; asynchronous: true; active: profileLoader.loaded || root.effectiveRoute === "profile"; sourceComponent: profileComponent; visible: root.effectiveRoute === "profile"; property bool loaded: false; onStatusChanged: if (status === Loader.Ready) loaded = true }

    BusyIndicator {
        anchors.centerIn: parent
        running: [stockLoader, recordsLoader, expenseLoader, incomeLoader, profitLoader, costLoader, salesLoader, assistantLoader, profileLoader].some(function(loader) {
                     return loader.visible && loader.status === Loader.Loading
                 })
        visible: running
    }
}
