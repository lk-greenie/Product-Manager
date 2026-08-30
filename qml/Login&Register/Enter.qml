pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "../Components"

Window {
    id: enter
    visible: true
    width: 300
    height: 400
    color: "transparent" // 关键：设置窗口背景透明
    flags: Qt.FramelessWindowHint | Qt.Window // 无边框并提示系统支持透明背景

    // 启动时用户数据库连接失败即展示错误页；错误文字由后端提供具体原因。
    readonly property bool databaseUnavailable: loginManager.getLastError() !== ""

    // 窗口拖动区域
    DragHandler {
        grabPermissions: TapHandler.CanTakeOverFromAnything
        onActiveChanged: if (active) { enter.startSystemMove() }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLarge

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            spacing: 0

            // 自定义标题栏
            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignCenter
                color: Theme.primary
                radius: Theme.radiusLarge

                Rectangle {
                    width: parent.width
                    height: 10 // 高度建议与圆角半径值相同或略大
                    color: Theme.primary // 颜色与底层矩形相同
                    anchors.bottom: parent.bottom
                }

                // 窗口标题
                Text {
                    text: ""
                    color: Theme.textOnPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    font.pixelSize: Theme.fontSmall
                }

                // 控制按钮
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    rightPadding: 5

                    // 最小化按钮
                    Button {
                        id: minButton
                        width: 30; height: 30
                        text: "_"
                        flat: true
                        onClicked: enter.showMinimized()
                        background: Rectangle {
                            color: minButton.hovered ? "#2980b9" : "transparent"
                            radius: 3
                        }
                    }

                    // 关闭按钮
                    Button {
                        id: closeButton
                        width: 30; height: 30
                        text: "×"
                        flat: true
                        onClicked: Qt.quit()
                        background: Rectangle {
                            color: closeButton.hovered ? Theme.primaryDark : "transparent"
                            radius: 3
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusLarge

                StackView {
                    id: stackView
                    anchors.fill: parent
                    initialItem: enter.databaseUnavailable ? errPage : loginPage
                }

                Component {
                    id: loginPage
                    LoginPage {
                        onRegisterClicked: stackView.push(registerPage, StackView.Immediate)
                        onLoginSuccess: console.log("Login successful")
                    }
                }

                Component {
                    id: registerPage
                    RegisterPage {
                        onBackClicked: stackView.pop(StackView.Immediate)
                        onRegisterSuccess: {
                            stackView.pop()
                            console.log("Registration successful")
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
