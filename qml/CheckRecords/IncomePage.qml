import QtQuick 2.15

RecordPage {
    recordFlag: "income"
    pageTitle: qsTr("收入记录")
    recordModel: TableDisplay.proxyModel3
    summaryLabel: qsTr("总收入：")
}
