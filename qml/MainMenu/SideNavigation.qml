pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"
import "../Services"

// 自适应侧栏：展开时显示图标、文字和分组层级；收起时保留图标和全部入口。
// 使用 ScrollView 承载导航项，窗口较矮时不会挤压页面内容或裁掉底部按钮。
Pane {
    id: root

    property string currentRoute: "stock"
    property bool expanded: true
    signal navigate(string route)

    property bool recordsOpen: false
    property bool visualOpen: false

    function syncExpandedGroups() {
        if (currentRoute.indexOf("records.") === 0)
            recordsOpen = true
        if (currentRoute.indexOf("visual.") === 0)
            visualOpen = true
    }

    onCurrentRouteChanged: syncExpandedGroups()
    Component.onCompleted: syncExpandedGroups()

    // 显式覆盖 Pane 默认的内容隐式宽度，保证收起时外层 Layout 能真正压缩。
    implicitWidth: expanded ? Theme.navExpandedWidth : Theme.navCollapsedWidth
    padding: 0

    Behavior on width {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    background: Rectangle {
        color: Theme.sidebar
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: brandBar
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            color: Theme.sidebar

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.expanded ? 16 : 8
                anchors.rightMargin: root.expanded ? 16 : 8
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 9
                    color: Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("仓")
                        color: Theme.textOnPrimary
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.expanded
                    spacing: 1

                    Label {
                        text: qsTr("产品进销存")
                        color: Theme.textOnPrimary
                        font.pixelSize: Theme.fontNormal
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: qsTr("管理工作台")
                        color: "#a9b8cc"
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#2b3b55"
        }

        ScrollView {
            id: navScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: navColumn
                x: root.expanded ? 10 : 6
                width: navScroll.availableWidth - (root.expanded ? 20 : 12)
                spacing: 6

                Item { Layout.fillWidth: true; Layout.preferredHeight: 14 }

                NavButton {
                    text: BackendContract.isVisitor(loginManager.per) ? qsTr("库存商品") : qsTr("库存管理")
                    iconKind: "inventory"
                    expanded: root.expanded
                    active: root.currentRoute === "stock"
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.expanded ? 44 : 42
                    onClicked: root.navigate("stock")
                }

                NavButton {
                    text: qsTr("收支记录")
                    iconKind: "records"
                    expanded: root.expanded
                    toggleStyle: true
                    sectionOpen: root.recordsOpen
                    visible: BackendContract.canViewRecords(loginManager.per)
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.expanded ? 44 : 42
                    onClicked: root.recordsOpen = !root.recordsOpen
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: root.recordsOpen && BackendContract.canViewRecords(loginManager.per)
                    spacing: 4

                    NavButton {
                        text: qsTr("总交易记录")
                        iconKind: "recordsAll"
                        expanded: root.expanded
                        subItem: true
                        active: root.currentRoute === "records.all"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.expanded ? 36 : 32
                        onClicked: root.navigate("records.all")
                    }
                    NavButton {
                        text: qsTr("支出记录")
                        iconKind: "expense"
                        expanded: root.expanded
                        subItem: true
                        active: root.currentRoute === "records.expense"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.expanded ? 36 : 32
                        onClicked: root.navigate("records.expense")
                    }
                    NavButton {
                        text: qsTr("收入记录")
                        iconKind: "income"
                        expanded: root.expanded
                        subItem: true
                        active: root.currentRoute === "records.income"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.expanded ? 36 : 32
                        onClicked: root.navigate("records.income")
                    }
                }

                NavButton {
                    text: qsTr("数据可视化")
                    iconKind: "visual"
                    expanded: root.expanded
                    toggleStyle: true
                    sectionOpen: root.visualOpen
                    visible: BackendContract.canViewVisualization(loginManager.per)
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.expanded ? 44 : 42
                    onClicked: root.visualOpen = !root.visualOpen
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: root.visualOpen && BackendContract.canViewVisualization(loginManager.per)
                    spacing: 4

                    NavButton {
                        text: qsTr("利润统计")
                        iconKind: "profit"
                        expanded: root.expanded
                        subItem: true
                        active: root.currentRoute === "visual.profit"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.expanded ? 36 : 32
                        onClicked: root.navigate("visual.profit")
                    }
                    NavButton {
                        text: qsTr("成本统计")
                        iconKind: "cost"
                        expanded: root.expanded
                        subItem: true
                        active: root.currentRoute === "visual.cost"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.expanded ? 36 : 32
                        onClicked: root.navigate("visual.cost")
                    }
                    NavButton {
                        text: qsTr("销售额统计")
                        iconKind: "sales"
                        expanded: root.expanded
                        subItem: true
                        active: root.currentRoute === "visual.sales"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.expanded ? 36 : 32
                        onClicked: root.navigate("visual.sales")
                    }
                }

                NavButton {
                    text: qsTr("AI小助手")
                    iconKind: "assistant"
                    expanded: root.expanded
                    active: root.currentRoute === "assistant"
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.expanded ? 44 : 42
                    onClicked: root.navigate("assistant")
                }

                NavButton {
                    text: qsTr("我的")
                    iconKind: "profile"
                    expanded: root.expanded
                    active: root.currentRoute === "profile"
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.expanded ? 44 : 42
                    onClicked: root.navigate("profile")
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 14 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#2b3b55"
        }

        ToolButton {
            id: collapseButton
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            padding: 0
            text: root.expanded ? qsTr("‹") : qsTr("›")
            Accessible.name: root.expanded ? qsTr("收起导航栏") : qsTr("展开导航栏")
            ToolTip.visible: hovered
            ToolTip.text: Accessible.name

            contentItem: Text {
                text: collapseButton.text
                color: collapseButton.hovered ? Theme.textOnPrimary : "#a9b8cc"
                font.pixelSize: 25
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: collapseButton.pressed ? Theme.sidebarHover
                       : collapseButton.hovered ? "#1d2e4a" : "transparent"
            }

            onClicked: root.expanded = !root.expanded
        }
    }

}
