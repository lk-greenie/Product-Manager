pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "../Components"

Window {
    id: enter
    visible: true
    width: 420
    height: 540
    minimumWidth: 380
    minimumHeight: 500
    color: "transparent" // 关键：设置窗口背景透明
    flags: Qt.FramelessWindowHint | Qt.Window // 无边框并提示系统支持透明背景


    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.appBackground
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            spacing: 0

            // 自定义标题栏
            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                Layout.alignment: Qt.AlignCenter
                color: Theme.sidebar
                radius: Theme.radiusLarge

                // 仅标题栏空白区域可拖动窗口，内容区和右侧控制按钮不会触发移动。
                Item {
                    z: 2
                    anchors.left: parent.left
                    anchors.right: windowButtons.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    DragHandler {
                        grabPermissions: TapHandler.CanTakeOverFromAnything
                        onActiveChanged: if (active) enter.startSystemMove()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 10
                    color: Theme.sidebar
                    anchors.bottom: parent.bottom
                }

                // 窗口标题
                Text {
                    text: qsTr("产品进销存管理系统")
                    color: Theme.textOnPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.Medium
                }

                // 控制按钮
                Row {
                    id: windowButtons
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    rightPadding: 5

                    Button {
                        id: serverSettingsButton
                        width: 34; height: 30
                        text: "⚙"
                        flat: true
                        padding: 0
                        Accessible.name: qsTr("数据库服务器设置")
                        ToolTip.visible: hovered
                        ToolTip.text: Accessible.name
                        onClicked: serverSettingsWindow.showFor(enter)

                        contentItem: Text {
                            text: serverSettingsButton.text
                            color: serverSettingsButton.hovered ? Theme.textOnPrimary : Theme.textSecondary
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: serverSettingsButton.hovered ? Theme.sidebarHover : "transparent"
                            radius: 3
                        }
                    }

                    // 最小化按钮
                    Button {
                        id: minButton
                        width: 34; height: 30
                        text: "_"
                        flat: true
                        padding: 0
                        Accessible.name: qsTr("最小化")
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("最小化")
                        contentItem: Text {
                            text: minButton.text
                            color: minButton.hovered ? Theme.textOnPrimary : Theme.textSecondary
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: enter.showMinimized()
                        background: Rectangle {
                            color: minButton.hovered ? Theme.sidebarHover : "transparent"
                            radius: 3
                        }
                    }

                    // 关闭按钮
                    Button {
                        id: closeButton
                        width: 34; height: 30
                        text: "×"
                        flat: true
                        padding: 0
                        Accessible.name: qsTr("关闭")
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("关闭")
                        contentItem: Text {
                            text: closeButton.text
                            color: closeButton.hovered ? Theme.textOnPrimary : Theme.textSecondary
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: Qt.quit()
                        background: Rectangle {
                            color: closeButton.hovered ? Theme.danger : "transparent"
                            radius: 3
                        }
                    }
                }
            }

            ConnectionSettingsWindow {
                id: serverSettingsWindow
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusLarge
                color: Theme.surface

                StackView {
                    id: stackView
                    anchors.fill: parent
                    // 即使启动时服务器暂不可达，也保留登录页和顶部设置按钮，
                    // 用户修改地址并手动连接后无需重启程序即可继续登录。
                    initialItem: loginPage
                }

                Component {
                    id: loginPage
                    LoginPage {
                        onRegisterClicked: stackView.push(registerPage, StackView.Immediate)
                        onLoginSuccess: console.log(qsTr("登录成功"))
                    }
                }

                Component {
                    id: registerPage
                    RegisterPage {
                        onBackClicked: stackView.pop(StackView.Immediate)
                        onRegisterSuccess: {
                            stackView.pop()
                            console.log(qsTr("注册成功"))
                        }
                    }
                }

                Component {
                    id: errPage
                    ErrorPage {
                        errorMessage: loginManager.getLastError()
                    }
                }
            }
        }
    }
}
