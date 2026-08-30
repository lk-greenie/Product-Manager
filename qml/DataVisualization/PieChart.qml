import QtQuick 2.15
import QtQuick.Controls 2.15
import QtCharts 6.0
import "../Components"

Item {
    id: root

    property var data: []
    readonly property bool hasData: data.length > 0

    function updateSeries() {
        pieSeries.clear()
        for (let i = 0; i < data.length; ++i) {
            const slice = pieSeries.append(data[i].label, Number(data[i].value))
            slice.color = Theme.chartColors[i % Theme.chartColors.length]
            slice.labelVisible = true
        }
    }

    Component.onCompleted: updateSeries()
    onDataChanged: updateSeries()

    ChartView {
        anchors.fill: parent
        visible: root.hasData
        antialiasing: true
        legend.visible: true
        legend.alignment: Qt.AlignBottom

        PieSeries {
            id: pieSeries
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.hasData
        text: qsTr("暂无数据")
    }
}
