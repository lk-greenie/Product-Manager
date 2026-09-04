import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Components"
import "../Services"

Page {
    id: root

    background: Rectangle {
        color: Theme.appBackground
    }

    property string recordFlag
    property string pageTitle
    property string summaryLabel
    property var recordModel
    property string summary: "0"
    property bool timeAscending: false

    function applyTimeSort() {
        TableDisplay.sortRecords(root.recordFlag,
                                 root.timeAscending ? BackendContract.ascending : BackendContract.descending)
    }

    function refresh(category, name, startDate, endDate) {
        const selectedCategory = category === "" ? qsTr("全部") : category
        if (!TableDisplay.filterRecords(recordFlag, selectedCategory, name, startDate, endDate))
            return
        summary = TableDisplay.sumFilteredRecords(recordFlag, selectedCategory, name, startDate, endDate)
        applyTimeSort()
    }

    Component.onCompleted: refresh(qsTr("全部"), "", "", "")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

        PageTitle {
            title: root.pageTitle
            subtitle: qsTr("按分类、商品和日期范围筛选记录")
        }

        FilterBar {
            id: filter
            Layout.fillWidth: true
            categoryModel: TableDisplay.allCategories()
            showDates: true
            showSummary: true
            summaryLabel: root.summaryLabel
            summaryText: Number(root.summary).toFixed(2) + qsTr("￥")
            showOrderButton: true
            orderAscending: root.timeAscending
            orderToolTip: root.timeAscending ? qsTr("交易时间从前到后") : qsTr("交易时间从后到前")
            onFilterRequested: function(category, name, startDate, endDate) {
                root.refresh(category, name, startDate, endDate)
            }
            onFilterReset: root.refresh(qsTr("全部"), "", "", "")
            onOrderToggled: {
                root.timeAscending = !root.timeAscending
                root.applyTimeSort()
            }
        }

        Connections {
            target: TableDisplay
            function onDataChanged() {
                filter.categoryModel = TableDisplay.allCategories()
                root.refresh(filter.currentCategory, filter.currentName, filter.startDate, filter.endDate)
            }
        }

        DataTable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.recordModel
            // 关系模型实际列顺序为 num,cat_name,cname,价格,sum,金额,t_time。
            // 分类编号只作为关联查询内部字段，不会出现在模型记录中，因此不再隐藏第 2 列。
            hiddenColumns: []
            dateColumns: [6]
            datetimeColumns: [6]
            moneyColumns: [3, 5]
            recordAmountColumn: root.recordFlag === "check" ? 5 : -1
            columnCount: 7
        }
    }
}
