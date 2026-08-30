import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

Popup {
    id: root
    width: 320
    height: parent ? parent.height : 600
    modal: true
    closePolicy: Popup.CloseOnPressOutside

    signal logoutRequested()

    background: Rectangle { color: Theme.surface }

    contentItem: ColumnLayout {
        spacing: 16

        Label {
            text: qsTr("个人信息")
            font.pixelSize: Theme.fontLarge
            font.bold: true
        }
        Label { text: qsTr("用户名：%1").arg(loginManager.username) }
        Label { text: qsTr("邮箱：%1").arg(loginManager.email === "" ? qsTr("未填写") : loginManager.email) }
        Label { text: qsTr("角色：%1").arg(loginManager.roleName) }

        Item { Layout.fillHeight: true }

        Button {
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
