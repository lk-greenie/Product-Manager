import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool showHeading: true
    property bool compact: false
    property var popupHost: null
    readonly property real generatorDialogWidth: Math.max(360, Math.min(470,
        popupHost ? popupHost.width - 24 : 470))
    readonly property real generatorDialogHeight: Math.max(300, Math.min(580,
        popupHost ? popupHost.height - 24 : 580))

    function resetGeneratorFields() {
        serverHostField.clear()
        serverPortField.text = "3306"
        serverUsernameField.clear()
        serverPasswordField.clear()
        userDatabaseNameField.text = "user_management"
        businessDatabaseNameField.text = "warehouse"
    }

    spacing: compact ? 8 : 10

    Label {
        visible: root.showHeading
        text: qsTr("数据库服务器加密配置")
        font.pixelSize: Theme.fontSection
        font.bold: true
        color: Theme.textPrimary
    }

    Label {
        visible: root.showHeading
        text: serverSettings.connected ? qsTr("当前已连接") : qsTr("当前未连接")
        color: serverSettings.connected ? Theme.success : Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        color: Theme.surfaceMuted
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusSmall

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Label {
                text: qsTr("已导入的加密配置文件")
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
            }
            Label {
                Layout.fillWidth: true
                text: serverSettings.encryptedConfigPath === ""
                      ? qsTr("未导入") : serverSettings.encryptedConfigPath
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideMiddle
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.compact ? 1 : 2
        columnSpacing: 8
        rowSpacing: 8

        SecondaryButton {
            text: qsTr("导入加密配置")
            Layout.fillWidth: true
            onClicked: importDialog.open()
        }
        SecondaryButton {
            text: qsTr("生成加密配置")
            Layout.fillWidth: true
            onClicked: {
                root.resetGeneratorFields()
                generateDialog.open()
            }
        }
        PrimaryButton {
            text: qsTr("手动连接")
            Layout.fillWidth: true
            enabled: serverSettings.encryptedConfigPath !== "" && !serverSettings.connected
            onClicked: serverSettings.connectServer()
        }
        SecondaryButton {
            text: qsTr("手动断开")
            Layout.fillWidth: true
            enabled: serverSettings.connected
            onClicked: serverSettings.disconnectServer()
        }
    }

    Label {
        Layout.fillWidth: true
        text: serverSettings.statusMessage
        wrapMode: Text.Wrap
        color: serverSettings.connected ? Theme.success : Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }

    FileDialog {
        id: importDialog
        title: qsTr("选择加密数据库服务器配置文件")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTr("加密数据库服务器配置 (*.enc)"), qsTr("所有文件 (*)")]
        onAccepted: serverSettings.importEncryptedConfig(selectedFile)
    }

    Dialog {
        id: generateDialog
        modal: true
        title: qsTr("生成加密数据库服务器配置")
        implicitWidth: root.generatorDialogWidth
        implicitHeight: root.generatorDialogHeight
        closePolicy: Popup.CloseOnEscape

        onClosed: root.resetGeneratorFields()

        contentItem: ScrollView {
            id: generatorScroll
            clip: true
            contentWidth: availableWidth
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                width: generatorScroll.availableWidth
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: qsTr("确认后将加密保存到 config/database_server_config.enc，并立即导入。")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.Wrap
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 6

                    Label { text: qsTr("服务器地址"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField {
                        id: serverHostField
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.compactControlHeight
                        placeholderText: qsTr("例如 127.0.0.1")
                    }

                    Label { text: qsTr("端口"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField {
                        id: serverPortField
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.compactControlHeight
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 65535 }
                    }

                    Label { text: qsTr("服务器账号"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField {
                        id: serverUsernameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.compactControlHeight
                    }

                    Label { text: qsTr("服务器密码"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    PasswordField {
                        id: serverPasswordField
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.compactControlHeight
                    }

                    Label { text: qsTr("用户数据库名"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField {
                        id: userDatabaseNameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.compactControlHeight
                    }

                    Label { text: qsTr("业务数据库名"); color: Theme.textSecondary; font.pixelSize: Theme.fontSmall }
                    StyledTextField {
                        id: businessDatabaseNameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.compactControlHeight
                    }
                }
            }
        }

        footer: Rectangle {
            implicitHeight: Theme.controlHeight + 16
            color: Theme.surface
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                SecondaryButton {
                    text: qsTr("取消")
                    Layout.fillWidth: true
                    onClicked: generateDialog.close()
                }
                PrimaryButton {
                    text: qsTr("确认生成")
                    Layout.fillWidth: true
                    onClicked: {
                        if (serverSettings.generateEncryptedConfig(serverHostField.text,
                                                                   Number(serverPortField.text),
                                                                   serverUsernameField.text,
                                                                   serverPasswordField.text,
                                                                   userDatabaseNameField.text,
                                                                   businessDatabaseNameField.text)) {
                            generateDialog.close()
                        }
                    }
                }
            }
        }
    }
}
