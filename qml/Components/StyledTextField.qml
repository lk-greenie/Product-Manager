import QtQuick 2.15
import QtQuick.Controls 2.15

// 白底圆角输入框：focus 时边框变主色深蓝 (#008deb)。
// 登录/注册及各弹窗表单复用。可通过 validator 属性扩展校验。
//
// 对外属性：
//   text            —— 文本内容（TextField 原生，可 alias）
//   placeholderText —— 占位符（原生）
//   validator       —— 校验器（原生，透传）
//   echoMode        —— 回显模式（原生，支持密码框）
TextField {
    id: control

    verticalAlignment: TextInput.AlignVCenter
    implicitHeight: Theme.controlHeight
    font.pixelSize: Theme.fontSmall
    color: Theme.textPrimary

    background: Rectangle {
        radius: Theme.radiusSmall
        color: Theme.surface
        border.color: control.activeFocus ? Theme.primaryDark : "transparent"
        border.width: 1
    }
}
