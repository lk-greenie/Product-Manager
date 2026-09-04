pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

// 可弹出日历的日期选择输入框。
// 点击后弹出自绘的日历面板（用标准控件实现，不依赖 QtQuick.Controls 的 Calendar 单例），
// 选中某一天后以 yyyy-MM-dd 显示。
// 对外属性：
//   placeholderText : string —— 未选择时的占位文字
//   selectedDate    : var    —— 当前选中日期（Date 或 null）
// 信号：
//   datePicked(var value) —— 用户在日历中选择日期后触发
Control {
    id: root

    property string placeholderText: ""
    property var selectedDate: null
    signal datePicked(var value)

    // 日历当前查看的年/月（月为 0-11）
    property int viewYear: 2024
    property int viewMonth: 0

    // 固定单元格尺寸，确保整月（最多 6 行）都能铺满显示
    readonly property int cellW: 34
    readonly property int cellH: 32
    readonly property int gridSpacing: 4

    readonly property string displayText: (root.selectedDate && !isNaN(root.selectedDate.getTime()))
                                          ? Qt.formatDateTime(root.selectedDate, "yyyy-MM-dd") : ""

    function syncViewToSelected() {
        const base = root.selectedDate && !isNaN(root.selectedDate.getTime())
                ? root.selectedDate : new Date()
        root.viewYear = base.getFullYear()
        root.viewMonth = base.getMonth()
    }

    function shiftMonth(delta) {
        let y = root.viewYear
        let m = root.viewMonth + delta
        if (m < 0) { m = 11; --y }
        else if (m > 11) { m = 0; ++y }
        root.viewYear = y
        root.viewMonth = m
    }

    function pickDay(day) {
        const chosen = new Date(root.viewYear, root.viewMonth, day)
        root.selectedDate = chosen
        popup.close()
        root.datePicked(chosen)
    }

    function isSelectedDay(day) {
        return root.selectedDate && day !== null && day !== undefined
                && root.selectedDate.getFullYear() === root.viewYear
                && root.selectedDate.getMonth() === root.viewMonth
                && root.selectedDate.getDate() === day
    }

    function isToday(day) {
        const today = new Date()
        return day !== null && day !== undefined
                && today.getFullYear() === root.viewYear
                && today.getMonth() === root.viewMonth
                && today.getDate() === day
    }

    implicitWidth: 130
    implicitHeight: Theme.controlHeight

    TextField {
        id: valueField
        anchors.fill: parent
        readOnly: true
        placeholderText: root.placeholderText
        text: root.displayText
        font.pixelSize: Theme.fontSmall
        horizontalAlignment: TextInput.AlignHCenter
        background: Rectangle {
            radius: Theme.radiusSmall
            color: Theme.surface
            border.color: valueField.activeFocus ? Theme.primary : Theme.border
            border.width: valueField.activeFocus ? 2 : 1
        }
    }

    Item {
        anchors.fill: parent
        TapHandler {
            onTapped: {
                root.syncViewToSelected()
                popup.open()
            }
        }
    }

    Popup {
        id: popup
        parent: Overlay.overlay
        width: 294
        height: 350
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 10

        onOpened: {
            const point = root.mapToItem(Overlay.overlay, 0, root.height + 6)
            x = Math.max(8, Math.min(point.x, Overlay.overlay.width - width - 8))
            y = Math.max(8, Math.min(point.y, Overlay.overlay.height - height - 8))
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.borderStrong
            border.width: 1
            radius: Theme.radiusMedium
        }

        // 日历网格包含最多 42 个按钮，只有弹窗真正打开时才创建，
        // 避免记录页/可视化页首屏为隐藏弹窗付出大量对象创建成本。
        contentItem: Loader {
            anchors.fill: parent
            active: popup.visible
            asynchronous: true
            sourceComponent: calendarContent
        }
    }

    Component {
        id: calendarContent

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ToolButton {
                    text: qsTr("‹")
                    Accessible.name: qsTr("上个月")
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.name
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    onClicked: root.shiftMonth(-1)
                }

                Label {
                    id: monthLabel
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.viewYear + qsTr("年") + (root.viewMonth + 1) + qsTr("月")
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    color: Theme.textPrimary
                }

                ToolButton {
                    text: qsTr("›")
                    Accessible.name: qsTr("下个月")
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.name
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    onClicked: root.shiftMonth(1)
                }
            }

            GridLayout {
                columns: 7
                columnSpacing: root.gridSpacing
                rowSpacing: root.gridSpacing
                Layout.fillWidth: true
                Layout.fillHeight: true

                Repeater {
                    model: ["日", "一", "二", "三", "四", "五", "六"]
                    delegate: Label {
                        required property string modelData
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Layout.preferredWidth: root.cellW
                        Layout.preferredHeight: 22
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        color: "#6b7280"
                    }
                }

                // 日历网格固定为 42 个单元格，切换月份时不会因行数变化而跳动。
                Repeater {
                    id: daysRepeater
                    model: root.daysModel

                    delegate: Button {
                        id: dayButton
                        required property var modelData
                        Layout.preferredWidth: root.cellW
                        Layout.preferredHeight: root.cellH
                        text: modelData === null || modelData === undefined ? "" : String(modelData)
                        enabled: modelData !== null && modelData !== undefined
                        contentItem: Text {
                            text: dayButton.text
                            color: dayButton.selectedDay ? Theme.textOnPrimary : Theme.textPrimary
                            font: dayButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        property bool selectedDay: root.isSelectedDay(modelData)
                        property bool todayDay: root.isToday(modelData)
                        // 去掉默认内边距，避免两位数字被省略号截断
                        padding: 0
                        leftPadding: 0
                        rightPadding: 0
                        flat: true
                        background: Rectangle {
                            radius: Theme.radiusSmall
                            color: dayButton.selectedDay ? Theme.primary
                                   : dayButton.hovered ? Theme.primarySoft : "transparent"
                            border.color: dayButton.todayDay && !dayButton.selectedDay
                                          ? Theme.primary : "transparent"
                            border.width: dayButton.todayDay && !dayButton.selectedDay ? 1 : 0
                        }
                        font.pixelSize: Theme.fontSmall
                        onClicked: {
                            if (modelData !== null && modelData !== undefined)
                                root.pickDay(modelData)
                        }
                    }
                }
            }
        }
    }

    // 当前查看月份的网格数据：前导 null 表示空白，整型表示日期（周日排首位）
    readonly property var daysModel: {
        const first = new Date(root.viewYear, root.viewMonth, 1)
        const startDow = first.getDay()
        const daysInMonth = new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
        const cells = []
        for (let i = 0; i < startDow; ++i)
            cells.push(null)
        for (let d = 1; d <= daysInMonth; ++d)
            cells.push(d)
        while (cells.length < 42)
            cells.push(null)
        return cells
    }
}
