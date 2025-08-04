import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Window {
    id: enter
    visible: true
    width: 400
    height: 400
    title: "登录-注册"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: loginPage
    }

    Component {
        id: loginPage
        LoginPage {
            onRegisterClicked: stackView.push(registerPage)
            onLoginSuccess: console.log("Login successful")
        }
    }

    Component {
        id: registerPage
        RegisterPage {
            onBackClicked: stackView.pop()
            onRegisterSuccess: {
                stackView.pop()
                console.log("Registration successful")
            }
        }
    }
}
