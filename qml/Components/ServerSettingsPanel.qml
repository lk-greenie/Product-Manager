import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool showHeading: true
    property bool compact: false

    function syncFields() {
        hostField.text = serverSettings.host
        portField.text = String(serverSettings.port)
        usernameField.text = serverSettings.username
        passwordField.clear()
    }

    spacing: compact ? 8 : 10

    Component.onCompleted: syncFields()

    Connections {
        target: serverSettings
        function onSettingsChanged() { root.syncFields() }
    }

    Label {
        visible: root.showHeading
        text: qsTr("数据库服务器")
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

    GridLayout {
        Layout.fillWidth: true
        columns: root.compact ? 1 : 2
        columnSpacing: 10
        rowSpacing: 6

        Label {
            text: qsTr("服务器地址")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall
        }
        StyledTextField {
            id: hostField
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.compactControlHeight
            placeholderText: qsTr("请输入服务器地址")
        }

        Label {
            text: qsTr("服务器账号")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall
        }
        StyledTextField {
            id: usernameField
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.compactControlHeight
            placeholderText: qsTr("请输入服务器账号")
        }

        Label {
            text: qsTr("服务器密码")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall
        }
        PasswordField {
            id: passwordField
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.compactControlHeight
            placeholderText: qsTr("留空则保持原密码")
        }

        Label {
            text: qsTr("端口")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall
        }
        StyledTextField {
            id: portField
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.compactControlHeight
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 1; top: 65535 }
            placeholderText: qsTr("请输入端口")
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        SecondaryButton {
            text: qsTr("保存设置")
            Layout.fillWidth: true
            onClicked: serverSettings.saveSettings(hostField.text, Number(portField.text),
                                                   usernameField.text, passwordField.text)
        }
        PrimaryButton {
            text: qsTr("连接")
            Layout.fillWidth: true
            onClicked: {
                if (serverSettings.saveSettings(hostField.text, Number(portField.text),
                                               usernameField.text, passwordField.text))
                    serverSettings.connectServer()
            }
        }
        SecondaryButton {
            text: qsTr("断开")
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
}
