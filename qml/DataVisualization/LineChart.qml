pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Components"

// 轻量折线图：使用 QML 图元绘制，避免 ChartView 在软件渲染或 Flickable
// 嵌套场景中出现空白，同时把悬浮高亮、参考线和提示信息交给同一套状态管理。
Item {
    id: root

    // Item 的 data 是默认子项容器，不能复用为业务数据，否则会清空图表内部图元。
    property var points: []
    property int hoverIndex: -1
    property int leftInset: 54
    // 首尾标签以数据点为中心显示，右侧需保留半个标签宽度避免被裁切。
    property int rightInset: 50
    property int topInset: 18
    property int bottomInset: 38
    // 长时间序列中，每个时间点至少保留一段完整日期标签所需的水平空间。
    property int minimumPointSpacing: 92
    readonly property bool hasData: points.length > 0
    readonly property real minimumContentWidth: leftInset + rightInset
                                                + Math.max(0, points.length - 1) * minimumPointSpacing
    readonly property real plotWidth: Math.max(1, width - leftInset - rightInset)
    readonly property real plotHeight: Math.max(1, height - topInset - bottomInset)
    readonly property real minValue: {
        if (points.length === 0)
            return 0
        let value = Number(points[0].value || 0)
        for (let i = 1; i < points.length; ++i)
            value = Math.min(value, Number(points[i].value || 0))
        return value
    }
    readonly property real maxValue: {
        if (points.length === 0)
            return 1
        let value = Number(points[0].value || 0)
        for (let i = 1; i < points.length; ++i)
            value = Math.max(value, Number(points[i].value || 0))
        return value
    }
    readonly property real valueRange: Math.max(1, maxValue - minValue)

    signal hovered(string label, real value, real localX, real localY)
    signal hoverOff()

    function pointX(index) {
        return leftInset + (points.length > 1 ? index / (points.length - 1) * plotWidth : plotWidth / 2)
    }

    function pointY(index) {
        const value = Number(points[index].value || 0)
        return topInset + (maxValue - value) / valueRange * plotHeight
    }

    function nearestIndex(mouseX) {
        if (points.length === 0)
            return -1
        const clamped = Math.max(leftInset, Math.min(width - rightInset, mouseX))
        return points.length > 1
                ? Math.max(0, Math.min(points.length - 1,
                                       Math.round((clamped - leftInset) / plotWidth * (points.length - 1))))
                : 0
    }

    Rectangle {
        // 直属子项锚定到 parent，避免在 Bound 组件模式中按 id 解析时丢失锚点目标。
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusMedium
    }

    // 背景参考线和数值刻度。
    Repeater {
        model: 5
        delegate: Item {
            id: gridRow
            required property int index
            readonly property real yPos: root.topInset + index / 4 * root.plotHeight

            Rectangle {
                x: root.leftInset
                y: gridRow.yPos
                width: root.plotWidth
                height: 1
                color: Theme.border
                opacity: 0.8
            }

            Label {
                x: 8
                y: gridRow.yPos - height / 2
                width: root.leftInset - 14
                text: {
                    const value = root.maxValue - gridRow.index / 4 * root.valueRange
                    return Number(value).toFixed(0)
                }
                color: Theme.textSecondary
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // 相邻点之间的线段。每个线段是一个旋转矩形，绘制成本低且兼容软件渲染。
    Repeater {
        model: Math.max(0, root.points.length - 1)
        delegate: Rectangle {
            required property int index
            readonly property real x1: root.pointX(index)
            readonly property real y1: root.pointY(index)
            readonly property real x2: root.pointX(index + 1)
            readonly property real y2: root.pointY(index + 1)
            readonly property real dx: x2 - x1
            readonly property real dy: y2 - y1

            x: x1
            y: y1 - height / 2
            width: Math.max(1, Math.sqrt(dx * dx + dy * dy))
            height: root.hoverIndex === index || root.hoverIndex === index + 1 ? 4 : 3
            color: root.hoverIndex >= 0 && root.hoverIndex !== index && root.hoverIndex !== index + 1
                   ? Theme.primarySoft : Theme.primary
            transformOrigin: Item.Left
            rotation: Math.atan2(dy, dx) * 180 / Math.PI
            radius: height / 2
        }
    }

    // 鼠标悬浮时显示垂直指引线和当前点，帮助用户准确定位时间桶。
    Rectangle {
        visible: root.hoverIndex >= 0
        x: root.hoverIndex >= 0 ? root.pointX(root.hoverIndex) - 1 : 0
        y: root.topInset
        width: 2
        height: root.plotHeight
        color: Theme.primarySoft
        opacity: 0.8
    }

    Repeater {
        model: root.points
        delegate: Rectangle {
            required property int index
            readonly property bool highlighted: root.hoverIndex === index
            x: root.pointX(index) - (highlighted ? 6 : 4)
            y: root.pointY(index) - (highlighted ? 6 : 4)
            width: highlighted ? 12 : 8
            height: width
            radius: width / 2
            color: highlighted ? Theme.surface : Theme.primary
            border.color: Theme.primary
            border.width: highlighted ? 3 : 1
        }
    }

    Item {
        x: 0
        y: root.height - root.bottomInset + 8
        width: root.width
        height: 24

        Repeater {
            model: root.points
            delegate: Label {
                required property int index
                required property var modelData
                // 标签中心与同序号数据点的 pointX(index) 完全一致，滚动后仍保持对齐。
                x: root.pointX(index) - width / 2
                width: root.minimumPointSpacing
                height: 24
                text: modelData.label
                color: Theme.textSecondary
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideNone
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onPositionChanged: {
            const index = root.nearestIndex(mouseX)
            if (index < 0) {
                root.hoverIndex = -1
                root.hoverOff()
                return
            }
            root.hoverIndex = index
            root.hovered(root.points[index].label, Number(root.points[index].value || 0),
                         root.pointX(index), root.pointY(index))
        }

        onExited: {
            root.hoverIndex = -1
            root.hoverOff()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 220
        height: 42
        visible: !root.hasData
        color: Theme.surfaceMuted
        radius: Theme.radiusSmall
        border.color: Theme.border
        border.width: 1

        Label {
            anchors.fill: parent
            text: qsTr("暂无趋势数据")
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSmall
        }
    }
}
