import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

Page {
    id: root

    property string metric: "cost"
    property string pageTitle: qsTr("成本统计")
    property var breakdown: []
    property var trend: []

    function loadData() {
        if (categoryBox.currentIndex < 0) {
            statusLabel.text = qsTr("请选择分类")
            return
        }
        if ((startField.text !== "" && !/^\d{4}-\d{2}-\d{2}$/.test(startField.text))
                || (endField.text !== "" && !/^\d{4}-\d{2}-\d{2}$/.test(endField.text))) {
            statusLabel.text = qsTr("日期格式应为 yyyy-MM-dd")
            return
        }
        const category = categoryBox.currentText
        const name = productBox.currentIndex < 0 ? "" : productBox.currentText
        breakdown = TableDisplay.chartBreakdown(metric, category, startField.text, endField.text)
        trend = TableDisplay.chartTrend(metric, category, name, scaleBox.currentValue, startField.text, endField.text)
        statusLabel.text = ""
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label { text: root.pageTitle; font.pixelSize: Theme.fontLarge; font.bold: true }

        RowLayout {
            Layout.fillWidth: true

            Label { text: qsTr("分类：") }
            ComboBox {
                id: categoryBox
                Layout.preferredWidth: 130
                model: TableDisplay.catModel
                currentIndex: -1
                displayText: currentIndex >= 0 ? currentText : qsTr("请选择")
                onActivated: {
                    TableDisplay.updatecnameModel(currentText)
                    productBox.currentIndex = -1
                }
            }

            Label { text: qsTr("商品：") }
            ComboBox {
                id: productBox
                Layout.preferredWidth: 130
                model: TableDisplay.cnameModel
                currentIndex: -1
                displayText: currentIndex >= 0 ? currentText : qsTr("全部")
            }

            Label { text: qsTr("尺度：") }
            ComboBox {
                id: scaleBox
                Layout.preferredWidth: 100
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: qsTr("按日"), value: "day" },
                    { text: qsTr("按月"), value: "month" },
                    { text: qsTr("按年"), value: "year" }
                ]
                currentIndex: 0
            }

            TextField { id: startField; Layout.preferredWidth: 120; placeholderText: qsTr("起始 yyyy-MM-dd") }
            TextField { id: endField; Layout.preferredWidth: 120; placeholderText: qsTr("终止 yyyy-MM-dd") }
            Button { text: qsTr("查询"); onClicked: root.loadData() }
        }

        Label { id: statusLabel; color: "#b91c1c" }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: productBox.currentIndex < 0

            PieChart { Layout.fillWidth: true; Layout.fillHeight: true; data: root.breakdown }
            BarChart { Layout.fillWidth: true; Layout.fillHeight: true; data: root.breakdown }
        }

        LineChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            data: root.trend
        }
    }
}
