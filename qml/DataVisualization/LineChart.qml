import QtQuick 2.15
import QtQuick.Controls 2.15
import QtCharts 6.0
import "../Components"

Item {
    id: root

    property var data: []
    readonly property bool hasData: data.length > 0

    function updateSeries() {
        trendSeries.clear()
        categoriesAxis.categories = []
        let minimum = 0
        let maximum = 0
        for (let i = 0; i < data.length; ++i) {
            const value = Number(data[i].value)
            categoriesAxis.append(data[i].label)
            trendSeries.append(i, value)
            minimum = Math.min(minimum, value)
            maximum = Math.max(maximum, value)
        }
        valuesAxis.min = minimum === maximum ? minimum - 1 : minimum
        valuesAxis.max = minimum === maximum ? maximum + 1 : maximum
    }

    Component.onCompleted: updateSeries()
    onDataChanged: updateSeries()

    ChartView {
        anchors.fill: parent
        visible: root.hasData
        antialiasing: true
        legend.visible: false

        LineSeries {
            id: trendSeries
            axisX: BarCategoryAxis { id: categoriesAxis }
            axisY: ValueAxis { id: valuesAxis; labelFormat: "%.0f" }
            color: Theme.chartColors[0]
            width: 2
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.hasData
        text: qsTr("暂无数据")
    }
}
