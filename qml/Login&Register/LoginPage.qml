import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtCore
import "../Components"
import ".." as App

// 登录页：复用 AuthPage 外壳、StyledTextField 输入框、PrimaryButton/SecondaryButton 按钮。
// 保留 Settings 记住密码、loginUser 流程、登录成功后 openDatabase()/init_Cat()。
AuthPage {
    id: loginPage

    // 使用Settings组件持久化存储
    Settings {
        id: settings
        category: "qmlProductManager"
        property string username: ""
        property string password: ""
        property bool rememberMe: false
    }

    // 加密函数
    function encrypt(text) {
        // 这里使用简单的Base64加密，实际项目中应使用更安全的加密方式
        return Qt.btoa(text)
    }

    // 解密函数
    function decrypt(text) {
        return Qt.atob(text)
    }

    property alias username: usernameField.text
    property alias password: passwordField.text
    property var mainMenuWindow: null

    signal registerClicked()
    signal loginSuccess()

    Component {
        id: mainMenuComponent
        App.MainMenu {}
    }

    // 登录处理：验证 -> 打开业务库/初始化分类 -> 记住密码 -> 关闭登录窗并打开主菜单
    function doLogin() {
        if (loginManager.loginUser(usernameField.text, passwordField.text)) {
            if (!TableDisplay.openDatabase() || !TableDisplay.init_Cat()) {
                errorLabel.text = qsTr("业务数据库初始化失败，请检查数据库连接和表结构！")
                return
            }
            TableDisplay.setCurrentPermission(loginManager.per)
            serverSettings.refreshConnectionState()
            if (rememberMeBox.checked) {
                settings.username = usernameField.text
                settings.password = encrypt(passwordField.text) // 加密存储
                settings.rememberMe = true
            } else {
                settings.username = ""
                settings.password = ""
                settings.rememberMe = false
            }
            loginSuccess()
            mainMenuWindow = mainMenuComponent.createObject(null)
            if (mainMenuWindow) {
                mainMenuWindow.x = Math.round((Screen.width - mainMenuWindow.width) / 2)
                mainMenuWindow.y = Math.round((Screen.height - mainMenuWindow.height) / 2)
                mainMenuWindow.loginWindow = enter
                mainMenuWindow.show()
                enter.hide()
            } else {
                errorLabel.text = qsTr("主界面创建失败！")
            }
        } else {
            errorLabel.text = loginManager.getLastError()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        height: parent.height
        width: parent.width * 0.8

        Label {
            text: "登录"
            font.pixelSize: Theme.fontTitle
            color: Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 80
        }

        StyledTextField {
            id: usernameField
            placeholderText: "用户名"
            text: settings.username
            Layout.topMargin: 30
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        PasswordField {
            id: passwordField
            placeholderText: "密码"
            text: loginPage.decrypt(settings.password)
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight

            // 捕获回车键事件（大键盘 Return 与小键盘 Enter 均触发登录）
            Keys.onReturnPressed: (event) => {
                if (event.modifiers === Qt.NoModifier) {  // 避免组合键误触发
                    loginPage.doLogin()
                }
            }
            Keys.onEnterPressed: (event) => {
                if (event.modifiers === Qt.NoModifier) {
                    loginPage.doLogin()
                }
            }
        }

        Label {
            id: errorLabel
            color: Theme.danger
            Layout.fillWidth: true
            wrapMode: Text.Wrap

            Timer {
                id: errorTimer
                interval: 3000
                repeat: false
                onTriggered: errorLabel.text = ""
            }

            onTextChanged: {
                if (text.length > 0)
                    errorTimer.restart()
                else
                    errorTimer.stop()
            }
        }

        CheckBox {
            id: rememberMeBox
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("记住密码")
            checked: settings.rememberMe
        }

        RowLayout {
            Layout.preferredWidth: parent.width * 0.8
            Layout.preferredHeight: Theme.controlHeight
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 80

            PrimaryButton {
                id: login
                text: "登录"
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: 80
                Layout.preferredHeight: Theme.controlHeight
                onClicked: loginPage.doLogin()
            }

            SecondaryButton {
                text: "注册"
                Layout.preferredWidth: 80
                Layout.preferredHeight: Theme.controlHeight
                Layout.alignment: Qt.AlignRight
                onClicked: loginPage.registerClicked()
            }
        }
    }
}
