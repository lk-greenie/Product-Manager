import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Components"

// 注册页：复用 AuthPage 外壳、StyledTextField 输入框、PrimaryButton/SecondaryButton 按钮。
AuthPage {
    id: registerPage

    signal backClicked()
    signal registerSuccess()

    ColumnLayout {
        anchors.centerIn: parent
        height: parent.height
        width: parent.width * 0.8

        Label {
            text: "注册"
            font.pixelSize: Theme.fontTitle
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 80
        }

        StyledTextField {
            id: usernameField
            placeholderText: "用户名"
            Layout.topMargin: 30
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        StyledTextField {
            id: passwordField
            placeholderText: "密码"
            echoMode: TextInput.Password
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight

            // 捕获回车键事件（大键盘 Return 与小键盘 Enter 均触发注册）
            Keys.onReturnPressed: (event) => {
                if (event.modifiers === Qt.NoModifier) {  // 避免组合键误触发
                    registerButton.clicked()
                }
            }
            Keys.onEnterPressed: (event) => {
                if (event.modifiers === Qt.NoModifier) {
                    registerButton.clicked()
                }
            }
        }

        StyledTextField {
            id: emailField
            placeholderText: "邮件（可选）"
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight

            // 捕获回车键事件（大键盘 Return 与小键盘 Enter 均触发注册）
            Keys.onReturnPressed: (event) => {
                if (event.modifiers === Qt.NoModifier) {  // 避免组合键误触发
                    registerButton.clicked()
                }
            }
            Keys.onEnterPressed: (event) => {
                if (event.modifiers === Qt.NoModifier) {
                    registerButton.clicked()
                }
            }
        }

        Label {
            id: errorLabel
            color: "red"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.preferredWidth: parent.width * 0.8
            Layout.preferredHeight: Theme.controlHeight
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 80

            PrimaryButton {
                id: registerButton
                text: "注册"
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: 80
                Layout.preferredHeight: Theme.controlHeight
                onClicked: {
                    if (loginManager.registerUser(usernameField.text, passwordField.text, emailField.text)) {
                        registerPage.registerSuccess()
                    } else {
                        errorLabel.text = loginManager.getLastError()
                    }
                }
            }

            SecondaryButton {
                text: "返回登录"
                Layout.preferredWidth: 80
                Layout.preferredHeight: Theme.controlHeight
                Layout.alignment: Qt.AlignRight
                onClicked: registerPage.backClicked()
            }
        }
    }
}
