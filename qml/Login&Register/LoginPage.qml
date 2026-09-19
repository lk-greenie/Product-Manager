import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "../Components"
import ".." as App

// 登录页：复用 AuthPage 外壳、StyledTextField 输入框、PrimaryButton/SecondaryButton 按钮。
// 记住状态由 C++ 写入 Windows 加密文件，登录成功后再进入业务库初始化流程。
AuthPage {
    id: loginPage

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
            serverSettings.saveRememberedLogin(usernameField.text, passwordField.text,
                                               rememberMeBox.checked)
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
            text: serverSettings.rememberedUsername
            Layout.topMargin: 30
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
        }

        PasswordField {
            id: passwordField
            placeholderText: "密码"
            text: serverSettings.rememberedPassword
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
            checked: serverSettings.rememberLogin
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
