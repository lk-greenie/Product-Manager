import QtQuick 2.15
import QtQuick.Controls 2.15
import QtCharts 6.0
import "../Components"

// 复用饼图：items = [{label,value}]。数据变化自动重绘；悬停按角度识别扇区并跟随鼠标返回信息。
Item {
    id: root

    property var items: []
    property string emptyText: qsTr("暂无数据")
    signal hovered(string label, real value, real localX, real localY)
    signal hoverOff()

    readonly property real total: {
        let t = 0
        for (let i = 0; i < items.length; ++i)
            t += Math.abs(Number(items[i].value || 0))
        return t
    }

    function fill() {
        pie.clear()
        for (let i = 0; i < items.length; ++i) {
            const s = pie.append(items[i].label, Math.abs(Number(items[i].value || 0)))
            s.color = Theme.chartColors[i % Theme.chartColors.length]
            s.labelVisible = false
        }
    }

    function resetHover() {
        for (let j = 0; j < pie.count; ++j) {
            pie.at(j).opacity = 1.0
            pie.at(j).explodeDistance = 0
            pie.at(j).borderWidth = 0
        }
    }

    onItemsChanged: fill()
    Component.onCompleted: fill()

    ChartView {
        id: chart
        anchors.fill: parent
        antialiasing: true
        legend.visible: false
        PieSeries { id: pie }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 24, 160)
        height: 38
        visible: root.items.length === 0 || root.total <= 0
        color: Theme.surfaceMuted
        radius: Theme.radiusSmall
        border.color: Theme.border
        border.width: 1

        Label {
            anchors.fill: parent
            text: root.emptyText
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSmall
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: {
            const arr = root.items
            const t = root.total
            if (arr.length === 0 || t <= 0)
                return
            const cx = chart.width / 2, cy = chart.height / 2
            const dx = mouseX - cx, dy = mouseY - cy
            if (Math.sqrt(dx * dx + dy * dy) < 8)
                return
            let a = Math.atan2(dy, dx)
            a = (a + 2 * Math.PI) % (2 * Math.PI)
            const aa = (a + Math.PI / 2) % (2 * Math.PI)
            const frac = aa / (2 * Math.PI)
            let cum = 0
            for (let i = 0; i < arr.length; ++i) {
                cum += Math.abs(Number(arr[i].value || 0)) / t
                if (frac <= cum) {
                    for (let j = 0; j < pie.count; ++j)
                        pie.at(j).opacity = 0.6
                    pie.at(i).opacity = 1.0
                    pie.at(i).explodeDistance = 10
                    pie.at(i).borderWidth = 3
                    pie.at(i).borderColor = "#ffffff"
                    root.hovered(arr[i].label, Number(arr[i].value), mouseX, mouseY)
                    return
                }
            }
        }
        onExited: {
            root.resetHover()
            root.hoverOff()
        }
    }
}
