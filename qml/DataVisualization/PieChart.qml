import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

// 占比可视化（用核心 QML Rectangle 绘制，保证能渲染；不含 QtCharts/Canvas）。
// 对外 data: [{label, value}]
Item {
    id: root

    property var data: []
    readonly property bool hasData: data.length > 0

    readonly property real totalV: {
        let t = 0
        for (let i = 0; i < data.length; ++i)
            t += Math.max(0, Number(data[i].value || 0))
        return t
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Label { text: qsTr("占比（按数值比例堆叠）"); font.pixelSize: Theme.fontSmall; font.bold: true }

        // 堆叠条
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: "#f1f5f9"
            clip: true

            Row {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.data
                    delegate: Rectangle {
                        width: root.totalV > 0 ? parent.width * (Math.max(0, Number(modelData.value || 0)) / root.totalV) : 0
                        height: parent.height
                        color: Theme.chartColors[index % Theme.chartColors.length]
                    }
                }
            }
        }

        // 图例
        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.hasData

            Repeater {
                model: root.data
                delegate: RowLayout {
                    spacing: 3
                    Rectangle {
                        width: 12; height: 12; radius: 2
                        color: Theme.chartColors[index % Theme.chartColors.length]
                    }
                    Label {
                        text: modelData.label
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.hasData
        text: qsTr("暂无数据")
    }
}
