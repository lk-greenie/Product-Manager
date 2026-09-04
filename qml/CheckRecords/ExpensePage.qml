import QtQuick 2.15

RecordPage {
    recordFlag: "expense"
    pageTitle: qsTr("支出记录")
    recordModel: TableDisplay.proxyModel2
    summaryLabel: qsTr("总支出：")
}
