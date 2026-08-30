import QtQuick 2.15

RecordPage {
    recordFlag: "income"
    recordModel: TableDisplay.proxyModel3
    summaryLabel: qsTr("总收入：")
}
