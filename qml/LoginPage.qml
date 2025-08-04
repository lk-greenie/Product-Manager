import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: loginPage

    property alias username: usernameField.text
    property alias password: passwordField.text

    signal registerClicked()
    signal loginSuccess()

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8

        Label {
            text: "登录"
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

        Button {
            text: "登录"
            Layout.fillWidth: true
            onClicked: {
                if (loginManager.loginUser(usernameField.text, passwordField.text)) {
                    loginSuccess()
                    enter.close()
                    var component = Qt.createComponent("MainMenu.qml")
                    var addnew
                    if (component.status === Component.Ready) {
                        addnew=component.createObject(parent)
                    } else {
                        component.statusChanged.connect(() => {
                            if (component.status === Component.Ready) {
                                addnew=component.createObject(parent)
                            }
                        });
                    }
                    addnew.show()
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
            text: "注册"
            Layout.fillWidth: true
            flat: true
            onClicked: registerClicked()
        }
    }
}
