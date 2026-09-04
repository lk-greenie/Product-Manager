import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

// 横向柱状图（用核心 QML Rectangle 绘制，保证能渲染；不含 QtCharts/Canvas）。
// 对外 data: [{label, value}]
Item {
    id: root

    property var data: []
    readonly property bool hasData: data.length > 0

    readonly property real maxV: {
        let m = 0
        for (let i = 0; i < data.length; ++i)
            m = Math.max(m, Number(data[i].value || 0))
        return m
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Repeater {
            model: root.data
            delegate: RowLayout {
                spacing: 6

                Label {
                    text: modelData.label
                    Layout.preferredWidth: 110
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSmall
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    color: "#e2e8f0"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: root.maxV > 0 ? parent.width * (Math.max(0, Number(modelData.value || 0)) / root.maxV) : 0
                        color: Theme.chartColors[index % Theme.chartColors.length]
                    }
                }

                Label {
                    text: String(Math.round(Number(modelData.value)))
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSmall
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
