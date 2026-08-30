import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

Page {
    title: qsTr("个人信息")

    ColumnLayout {
        anchors.centerIn: parent
        Layout.preferredWidth: Math.min(parent.width * 0.7, 360)
        spacing: 16

        Label { text: qsTr("个人信息"); font.pixelSize: 24; font.bold: true }
        Label { text: qsTr("用户名：%1").arg(loginManager.username) }
        Label { text: qsTr("邮箱：%1").arg(loginManager.email === "" ? qsTr("未填写") : loginManager.email) }
        Label { text: qsTr("角色：%1").arg(loginManager.roleName) }
    }
}
