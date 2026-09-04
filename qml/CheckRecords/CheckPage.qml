import QtQuick 2.15

RecordPage {
    recordFlag: "check"
    pageTitle: qsTr("总交易记录")
    recordModel: TableDisplay.proxyModel1
    summaryLabel: qsTr("总额：")
}
