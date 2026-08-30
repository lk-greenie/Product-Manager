import QtQuick 2.15
import QtQuick.Controls 2.15
import QtCharts 6.0
import "../Components"

Item {
    id: root

    property var data: []
    readonly property bool hasData: data.length > 0

    function updateSeries() {
        const categories = []
        const values = []
        for (let i = 0; i < data.length; ++i) {
            categories.push(data[i].label)
            values.push(Number(data[i].value))
        }
        categoriesAxis.categories = categories
        valuesSeries.values = values
    }

    Component.onCompleted: updateSeries()
    onDataChanged: updateSeries()

    ChartView {
        anchors.fill: parent
        visible: root.hasData
        antialiasing: true
        legend.visible: false

        BarSeries {
            axisX: BarCategoryAxis { id: categoriesAxis }
            axisY: ValueAxis { min: 0; labelFormat: "%.0f" }

            BarSet {
                id: valuesSeries
                label: qsTr("金额")
                color: Theme.chartColors[0]
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.hasData
        text: qsTr("暂无数据")
    }
}
