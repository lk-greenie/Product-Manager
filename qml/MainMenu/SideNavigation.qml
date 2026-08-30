pragma ComponentBehavior: Bound

import QtQuick 2.15
import "../Components"
import "../Services"

Rectangle {
    id: root

    property string currentRoute: "stock"
    property bool expanded: true
    signal navigate(string route)
    signal profileRequested()

    color: Theme.primary

    ListModel {
        id: navigationModel
        ListElement { title: "库存情况"; route: "stock"; section: "main" }
        ListElement { title: "总交易记录"; route: "records.all"; section: "records" }
        ListElement { title: "支出记录"; route: "records.expense"; section: "records" }
        ListElement { title: "收入记录"; route: "records.income"; section: "records" }
        ListElement { title: "利润统计"; route: "visual.profit"; section: "visual" }
        ListElement { title: "成本统计"; route: "visual.cost"; section: "visual" }
        ListElement { title: "销售额统计"; route: "visual.sales"; section: "visual" }
        ListElement { title: "AI小助手"; route: "assistant"; section: "main" }
    }

    property bool recordsOpen: false
    property bool visualOpen: false

    Column {
        width: parent.width * 0.92
        height: parent.height
        spacing: 10
        visible: root.expanded

        NavButton {
            text: qsTr("我的")
            expanded: root.expanded
            width: parent.width * 0.9
            height: parent.height / 12
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.profileRequested()
        }

        NavButton {
            text: qsTr("库存管理")
            expanded: root.expanded
            active: root.currentRoute === "stock"
            width: parent.width * 0.9
            height: parent.height / 12
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.navigate("stock")
        }

        NavButton {
            visible: BackendContract.canViewRecords(loginManager.per)
            text: qsTr("收支记录")
            expanded: root.expanded
            toggleStyle: true
            active: root.recordsOpen
            width: parent.width * 0.9
            height: parent.height / 12
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.recordsOpen = !root.recordsOpen
        }

        Column {
            id: recordsMenu

            width: parent.width * 0.9
            height: root.recordsOpen ? implicitHeight : 0
            visible: root.recordsOpen
            anchors.right: parent.right

            Repeater {
                model: navigationModel
                delegate: NavButton {
                    required property string title
                    required property string route
                    required property string section
                    visible: section === "records" && BackendContract.canViewRecords(loginManager.per)
                    text: title
                    expanded: root.expanded
                    subItem: true
                    active: root.currentRoute === route
                    width: recordsMenu.width * 0.7
                    height: visible ? root.height / 15 : 0
                    anchors.right: recordsMenu.right
                    onClicked: root.navigate(route)
                }
            }
        }

        NavButton {
            visible: BackendContract.canViewVisualization(loginManager.per)
            text: qsTr("数据可视化")
            expanded: root.expanded
            toggleStyle: true
            active: root.visualOpen
            width: parent.width * 0.9
            height: parent.height / 12
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.visualOpen = !root.visualOpen
        }

        Column {
            id: visualMenu

            width: parent.width * 0.9
            height: root.visualOpen ? implicitHeight : 0
            visible: root.visualOpen
            anchors.right: parent.right

            Repeater {
                model: navigationModel
                delegate: NavButton {
                    required property string title
                    required property string route
                    required property string section
                    visible: section === "visual" && BackendContract.canViewVisualization(loginManager.per)
                    text: title
                    expanded: root.expanded
                    subItem: true
                    active: root.currentRoute === route
                    width: visualMenu.width * 0.7
                    height: visible ? root.height / 15 : 0
                    anchors.right: visualMenu.right
                    onClicked: root.navigate(route)
                }
            }
        }

        NavButton {
            text: qsTr("AI小助手")
            expanded: root.expanded
            active: root.currentRoute === "assistant"
            width: parent.width * 0.9
            height: parent.height / 12
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.navigate("assistant")
        }
    }

    Rectangle {
        width: root.expanded ? parent.width * 0.08 : parent.width
        height: parent.height
        anchors.right: parent.right
        color: toggleArea.pressed || toggleArea.containsMouse ? Theme.primaryDark : Theme.primary

        Text {
            anchors.centerIn: parent
            text: ">"
            color: Theme.textOnPrimary
            rotation: root.expanded ? 0 : 180
            Behavior on rotation { NumberAnimation { duration: 300 } }
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }
}
