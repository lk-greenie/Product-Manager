import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Components"

Page {
    id: root

    property string recordFlag
    property string summaryLabel
    property var recordModel
    property string summary: "0"

    function refresh(category, name, startDate, endDate) {
        const selectedCategory = category === "" ? qsTr("全部") : category
        if (!TableDisplay.filterRecords(recordFlag, selectedCategory, name, startDate, endDate))
            return
        summary = TableDisplay.sumFilteredRecords(recordFlag, selectedCategory, name, startDate, endDate)
    }

    Component.onCompleted: refresh(qsTr("全部"), "", "", "")

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        FilterBar {
            id: filter
            Layout.fillWidth: true
            categoryModel: TableDisplay.catModel
            showDates: true
            showSummary: true
            summaryLabel: root.summaryLabel
            summaryText: root.summary + qsTr("￥")
            onFilterRequested: function(category, name, startDate, endDate) {
                root.refresh(category, name, startDate, endDate)
            }
            onFilterReset: root.refresh(qsTr("全部"), "", "", "")
        }

        DataTable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.recordModel
            dateColumns: [6]
            recordAmountColumn: root.recordFlag === "check" ? 5 : -1
            columnCount: 7
        }
    }
}
