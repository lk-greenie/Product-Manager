import QtQuick 2.15
import QtQuick.Controls 2.15
import "."   // 导入同目录的 Components 模块，使 Theme 单例可见

// 登录类页面外壳：顶部 #0099ff 条 + 垂直三段渐变背景 + 透明背景 Page。
// LoginPage / RegisterPage / ErrorPage 复用。
//
// 用法：将页面内容作为默认子元素放入本组件，会被塞进渐变面板内居中区域。
//   AuthPage { ColumnLayout { ... } }
//
// 对外属性：
//   default property alias content —— 默认内容（放入渐变面板内）
Page {
    id: authPage
    width: 300
    height: 360

    // 默认子元素放入渐变面板
    default property alias content: contentHolder.data

    background: Rectangle {
        color: "transparent" // 背景透明，交由渐变面板呈现
    }

    // 顶部主色条
    Rectangle {
        width: parent.width
        height: 10
        color: Theme.primary
        anchors.top: parent.top
        z: 1
    }

    // 垂直三段渐变面板
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLarge
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 0.5; color: Theme.accentLight }
            GradientStop { position: 1.0; color: Theme.primary }
        }

        // 内容承载区（子元素填入此处）
        Item {
            id: contentHolder
            anchors.fill: parent
        }
    }
}
