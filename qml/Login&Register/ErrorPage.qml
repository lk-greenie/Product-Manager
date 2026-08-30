import QtQuick 2.15
import "../Components"

// 数据库连接失败提示页：复用 AuthPage 外壳（顶部主色条 + 三段渐变背景）。
AuthPage {
    id: errPage
    property string errorMessage: qsTr("无法连接数据库服务器")

    Text {
        anchors.centerIn: parent
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: errPage.errorMessage
        font.pixelSize: 28
        color: "grey"
    }
}
