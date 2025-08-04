import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Window {
    id: mainmenu
    visible: true
    width: 800
    height: 600
    title: "华东交通大学南区超市管理系统"

    property bool isNavOpen: true  // 默认展开

    ListModel{
        id:navModel
        ListElement{name:"库存管理"}
        ListElement{name:"收支记录"}
        ListElement{name:"可视化数据"}
        ListElement{name:"沟通协商"}
        ListElement{name:"AI小助手"}
    }

    //左侧导航栏
    Rectangle {
        id:nav
        height:parent.height
        width: isNavOpen? 150:5
        z:10

        Behavior on x {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        // 左侧弹窗组件
        Popup {
            id: leftPopup
            width: 300
            height: parent.height
            modal: true
            closePolicy: Popup.CloseOnPressOutside

            // 弹窗内容
            Rectangle {
                anchors.fill: parent
                color: "lightgray"
                Text {
                    anchors.centerIn: parent
                    text: "左侧弹窗内容"
                }
            }

            // 动画效果
            Behavior on x {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
        }

        RowLayout{
            id:bar
            width:nav.width
            height: nav.height
            Column {
                id:button
                Layout.fillHeight: parent
                width: bar.width-drawer.width
                spacing: 10

                ToolButton {
                    text:"我的"
                    width: button.width
                    height: 60
                    font.pixelSize: 14
                    onClicked:{
                        leftPopup.open()
                    }
                }

                Repeater {

                    model: navModel
                    ToolButton {
                        width: button.width
                        height: 60
                        font.pixelSize: 14

                        contentItem: Text {
                            text:isNavOpen?name:""
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            stackview.pop()
                            if(name=="库存管理")stackview.push(displayPage)
                            if(name=="收支记录")stackview.push(checkPage)
                            if(name=="可视化数据")stackview.push(visualizationPage)
                            if(name=="沟通协商")stackview.push(chatPage)
                            if(name=="AI小助手")stackview.push(aiPage)
                        }
                    }
                }
            }
            ToolButton {
                id:drawer
                width:1
                Layout.fillHeight: bar
                Layout.alignment: Qt.AlignRight
                onClicked: isNavOpen = !isNavOpen
            }
        }


    }

    //右侧操作展示界面
    StackView {
        id: stackview
        anchors.right: parent.right
        height:parent.height
        width:parent.width-nav.width
        initialItem:displayPage
    }

    Component {
        id: displayPage
        DisplayPage {

        }
    }

    Component {
        id: checkPage
        CheckPage {

        }
    }

    Component {
        id: visualizationPage
        VisualizationPage {

        }
    }

    Component {
        id: chatPage
        ChatPage {

        }
    }

    Component {
        id: aiPage
        AIPage {

        }
    }

}
