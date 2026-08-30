import QtQuick 2.15
import QtQuick.Layouts
import "../StockManagement" as StockManagement
import "../CheckRecords" as CheckRecords
import "../DataVisualization" as DataVisualization
import "../AIAssistant" as AIAssistant
import "../Services"

StackLayout {
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
        "assistant"
    ]

    function routeToIndex(value) {
        const index = routes.indexOf(value)
        return index >= 0 ? index : 0
    }

    currentIndex: routeToIndex(BackendContract.canViewRoute(loginManager.per, route) ? route : "stock")

    StockManagement.DisplayPage {}
    CheckRecords.CheckPage {}
    CheckRecords.ExpensePage {}
    CheckRecords.IncomePage {}
    DataVisualization.ProfitVisualization {}
    DataVisualization.CostVisualization {}
    DataVisualization.SalesVisualization {}
    AIAssistant.AIPage {}
}
