import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

Page {
    id: root

    signal logoutRequested()

    background: Rectangle { color: Theme.appBackground }

    function showStatus(message, color) {
        statusLabel.text = message
        statusLabel.color = color
        statusTimer.restart()
    }

    onVisibleChanged: {
        if (visible && loginManager.per === 1)
            loginManager.refreshUsers()
    }

    ScrollView {
        id: profileScroll
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            width: profileScroll.availableWidth
            spacing: Theme.sectionSpacing

            PageTitle {
                title: qsTr("我的")
                subtitle: qsTr("账户信息、注册用户与数据库服务器加密配置")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusMedium

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 28

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: qsTr("用户名"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                        Label { text: loginManager.username; color: Theme.textPrimary; font.pixelSize: Theme.fontNormal; font.bold: true }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: qsTr("邮箱"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                        Label { text: loginManager.email === "" ? qsTr("未填写") : loginManager.email; color: Theme.textPrimary; font.pixelSize: Theme.fontNormal; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    ColumnLayout {
                        Layout.preferredWidth: 120
                        spacing: 3
                        Label { text: qsTr("角色"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                        Label { text: loginManager.roleName; color: Theme.primary; font.pixelSize: Theme.fontNormal; font.bold: true }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: serverSettingsPanel.implicitHeight + 28
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusMedium

                ServerSettingsPanel {
                    id: serverSettingsPanel
                    anchors.fill: parent
                    anchors.margins: 14
                }
            }

            ColumnLayout {
                visible: loginManager.per === 1
                Layout.fillWidth: true
                spacing: 8

                Label { text: qsTr("注册用户管理"); font.pixelSize: Theme.fontSection; font.bold: true; color: Theme.textPrimary }

                ListView {
                    id: userView
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 232)
                    clip: true
                    spacing: 6
                    model: loginManager.usersModel

                    delegate: Rectangle {
                        id: userDelegate
                        required property int userId
                        required property string display
                        required property string email
                        required property int permission
                        required property string roleName

                        width: userView.width
                        height: 54
                        color: Theme.surface
                        border.color: Theme.border
                        border.width: 1
                        radius: Theme.radiusSmall

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label { text: userDelegate.display; color: Theme.textPrimary; font.pixelSize: Theme.fontSmall; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                Label { text: userDelegate.email === "" ? qsTr("未填写邮箱") : userDelegate.email; color: Theme.textSecondary; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                            }

                            Label {
                                text: userDelegate.roleName
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSmall
                                Layout.preferredWidth: 74
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledComboBox {
                                id: roleBox
                                Layout.preferredWidth: 128
                                Layout.preferredHeight: Theme.compactControlHeight
                                model: [qsTr("店员"), qsTr("顾客访客")]
                                currentIndex: userDelegate.permission === 2 ? 0 : 1
                                displayText: currentText
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
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: accountForm.implicitHeight + 28
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusMedium

                ColumnLayout {
                    id: accountForm
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Label { text: qsTr("修改账户信息"); font.pixelSize: Theme.fontSection; font.bold: true; color: Theme.textPrimary }
                    Label { text: qsTr("原密码"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    PasswordField { id: oldPasswordField; Layout.fillWidth: true; Layout.preferredHeight: Theme.controlHeight; placeholderText: qsTr("请输入当前密码") }
                    Label { text: qsTr("新邮箱"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField { id: emailField; Layout.fillWidth: true; Layout.preferredHeight: Theme.controlHeight; placeholderText: qsTr("留空则不修改") }
                    Label { text: qsTr("新用户名"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField { id: usernameField; Layout.fillWidth: true; Layout.preferredHeight: Theme.controlHeight; placeholderText: qsTr("留空则不修改") }
                    Label { text: qsTr("新密码"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    PasswordField { id: passwordField; Layout.fillWidth: true; Layout.preferredHeight: Theme.controlHeight; placeholderText: qsTr("留空则不修改") }
                }
            }

            Label {
                id: statusLabel
                Layout.fillWidth: true
                visible: text !== ""
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSmall

                Timer {
                    id: statusTimer
                    interval: 3000
                    repeat: false
                    onTriggered: statusLabel.text = ""
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PrimaryButton {
                    text: qsTr("保存账户信息")
                    Layout.fillWidth: true
                    onClicked: {
                        if (loginManager.updateProfile(oldPasswordField.text, emailField.text,
                                                       usernameField.text, passwordField.text)) {
                            root.showStatus(qsTr("账户信息已更新"), Theme.success)
                            oldPasswordField.clear()
                            passwordField.clear()
                        } else {
                            root.showStatus(loginManager.getLastError(), Theme.danger)
                        }
                    }
                }

                SecondaryButton {
                    text: qsTr("退出登录")
                    Layout.fillWidth: true
                    onClicked: {
                        TableDisplay.setCurrentPermission(3)
                        loginManager.clearSession()
                        root.logoutRequested()
                    }
                }
            }
        }
    }
}
