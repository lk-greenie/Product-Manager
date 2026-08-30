import QtQuick 2.15

RecordPage {
    recordFlag: "expense"
    recordModel: TableDisplay.proxyModel2
    summaryLabel: qsTr("总支出：")
}
