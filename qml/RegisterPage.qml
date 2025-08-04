import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: registerPage

    signal backClicked()
    signal registerSuccess()

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8

        Label {
            text: "注册"
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: usernameField
            placeholderText: "用户名"
            Layout.fillWidth: true
        }

        TextField {
            id: passwordField
            placeholderText: "密码"
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        TextField {
            id: emailField
            placeholderText: "邮件（可选）"
            Layout.fillWidth: true
        }

        Button {
            text: "注册"
            Layout.fillWidth: true
            onClicked: {
                if (loginManager.registerUser(usernameField.text, passwordField.text, emailField.text)) {
                    registerSuccess()
                } else {
                    errorLabel.text = loginManager.getLastError()
                }
            }
        }

        Label {
            id: errorLabel
            color: "red"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        Button {
            text: "返回登录"
            Layout.fillWidth: true
            flat: true
            onClicked: backClicked()
        }
    }
}
