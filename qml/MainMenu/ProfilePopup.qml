import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

Popup {
    id: root
    width: 400
    height: parent ? parent.height : 600
    modal: true
    closePolicy: Popup.CloseOnPressOutside
    padding: Theme.pagePadding

    signal logoutRequested()

    function showStatus(message, color) {
        statusLabel.color = color
        statusLabel.text = message
        statusTimer.restart()
    }

    onOpened: {
        if (loginManager.per === 1)
            loginManager.refreshUsers()
    }

    background: Rectangle {
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusMedium
    }

    contentItem: ScrollView {
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: availableWidth
            spacing: 10

        Label {
            text: qsTr("个人信息")
            font.pixelSize: Theme.fontLarge
            font.bold: true
            color: Theme.textPrimary
        }

        Timer {
            id: statusTimer
            interval: 2600
            repeat: false
            onTriggered: statusLabel.text = ""
        }
        Label { text: qsTr("用户名：%1").arg(loginManager.username); color: Theme.textSecondary }
        Label { text: qsTr("邮箱：%1").arg(loginManager.email === "" ? qsTr("未填写") : loginManager.email); color: Theme.textSecondary }
        Label { text: qsTr("角色：%1").arg(loginManager.roleName); color: Theme.textSecondary }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
        }

        ColumnLayout {
            visible: loginManager.per === 1
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("注册用户管理")
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.textPrimary
            }

            Label {
                text: qsTr("店主可将其他账号设置为店员或顾客访客")
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            ListView {
                id: userView
                Layout.fillWidth: true
                Layout.preferredHeight: 190
                clip: true
                spacing: 6
                model: loginManager.usersModel

                delegate: Rectangle {
                    id: userDelegate
                    required property int userId
                    required property string display
                    required property string email
                    required property int permission

                    width: userView.width
                    height: 50
                    radius: Theme.radiusSmall
                    color: Theme.surfaceMuted
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Label {
                                text: userDelegate.display
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                text: userDelegate.email === "" ? qsTr("未填写邮箱") : userDelegate.email
                                font.pixelSize: 11
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: roleBox
                            Layout.preferredWidth: 132
                            Layout.preferredHeight: Theme.compactControlHeight
                            model: [qsTr("店员"), qsTr("顾客访客")]
                            currentIndex: userDelegate.permission === 2 ? 0
                                          : userDelegate.permission === 3 ? 1 : -1
                            displayText: userDelegate.permission === 1
                                         ? qsTr("店主") : (currentIndex >= 0 ? currentText : qsTr("请选择角色"))
                            onActivated: {
                                const newPermission = currentIndex === 0 ? 2 : 3
                                if (loginManager.updateUserPermission(userDelegate.userId, newPermission))
                                    root.showStatus(qsTr("用户角色已更新"), Theme.success)
                                else {
                                    currentIndex = userDelegate.permission === 2 ? 0 : 1
                                    root.showStatus(loginManager.getLastError(), Theme.danger)
                                }
                            }
                        }
                    }
                }
            }

            Label {
                visible: userView.count === 0
                text: qsTr("暂无其他注册用户")
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Label {
            text: qsTr("修改账户信息")
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: Theme.textPrimary
        }

        Label { text: qsTr("原密码（必填）"); font.pixelSize: Theme.fontSmall }
        PasswordField {
            id: oldPasswordField
            placeholderText: qsTr("请输入当前密码")
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        Label { text: qsTr("新邮箱"); font.pixelSize: Theme.fontSmall }
        StyledTextField {
            id: emailField
            placeholderText: qsTr("新邮箱（留空则不修改）")
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        Label { text: qsTr("新用户名"); font.pixelSize: Theme.fontSmall }
        StyledTextField {
            id: usernameField
            placeholderText: qsTr("新用户名（留空则不修改）")
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        Label { text: qsTr("新密码"); font.pixelSize: Theme.fontSmall }
        PasswordField {
            id: passwordField
            placeholderText: qsTr("新密码（留空则不修改）")
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        Label {
            id: statusLabel
            visible: text !== ""
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            font.pixelSize: Theme.fontSmall
        }

        PrimaryButton {
            text: qsTr("保存修改")
            Layout.fillWidth: true
            onClicked: {
                if (loginManager.updateProfile(oldPasswordField.text, emailField.text,
                                               usernameField.text, passwordField.text)) {
                    statusLabel.color = Theme.success
                    statusLabel.text = qsTr("修改成功")
                    statusTimer.restart()
                    oldPasswordField.clear()
                    passwordField.clear()
                } else {
                    statusLabel.color = Theme.danger
                    statusLabel.text = loginManager.getLastError()
                    statusTimer.restart()
                }
            }
        }

        Item { Layout.fillHeight: true }

        SecondaryButton {
            text: qsTr("退出登录")
            Layout.fillWidth: true
            onClicked: {
                TableDisplay.setCurrentPermission(3)
                loginManager.clearSession()
                root.close()
                root.logoutRequested()
            }
        }
        }
    }
}
