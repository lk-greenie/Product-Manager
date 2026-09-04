import QtQuick 2.15
import QtQuick.Controls 2.15
import "."   // 导入同目录的 Components 模块，使 Theme 单例可见

// 登录类页面外壳：浅色表面 + 顶部强调条，保持登录、注册和错误页的统一层级。
// LoginPage / RegisterPage / ErrorPage 复用。
//
// 用法：将页面内容作为默认子元素放入本组件，会被塞进渐变面板内居中区域。
//   AuthPage { ColumnLayout { ... } }
//
// 对外属性：
//   default property alias content —— 默认内容（放入渐变面板内）
Page {
    id: authPage
    implicitWidth: 420
    implicitHeight: 430

    // 默认子元素放入统一的浅色内容面板
    default property alias content: contentHolder.data

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusLarge
        border.color: Theme.border
        border.width: 1
    }

    // 仅保留很窄的浅蓝分隔线，让深色标题栏到内容区过渡更柔和。
    Rectangle {
        width: parent.width - 2
        height: 3
        color: Theme.primarySoft
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        z: 1
    }

    // 内容承载区，页面内容负责自己的布局和内边距。
    Item {
        anchors.fill: parent
        anchors.margins: 1

        Item {
            id: contentHolder
            anchors.fill: parent
        }
    }
}
