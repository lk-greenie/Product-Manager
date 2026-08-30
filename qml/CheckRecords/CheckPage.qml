import QtQuick 2.15

RecordPage {
    recordFlag: "check"
    recordModel: TableDisplay.proxyModel1
    summaryLabel: qsTr("总额：")
}
