import QtQuick 2.15
import QtQuick.Controls 2.15

// 主色蓝按钮：蓝底白字圆角。
// 使用 Button 自身的 down/hovered 状态驱动背景色，不内嵌 MouseArea。
// 替换 登录/查询/成本页“查询”等主按钮。
//
// 对外属性：
//   text            —— 按钮文字（Button 原生）
//   ghost: bool     —— true 时为幽灵样式（透明底、主色边框/文字），默认 false
// 信号：clicked（Button 原生）
Button {
    id: control

    // 是否为幽灵（描边）外观
    property bool ghost: false

    implicitHeight: Theme.controlHeight
    implicitWidth: Math.max(96, contentItem.implicitWidth + 28)
    font.pixelSize: Theme.fontNormal
    font.weight: Font.Medium

    // 文字：实心按钮白字；幽灵按钮主色字
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.ghost ? Theme.primary : Theme.textOnPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1.0 : 0.55
    }

    // 背景：hovered/down 时切换到更深的蓝
    background: Rectangle {
        radius: Theme.radiusSmall
        border.color: control.ghost ? Theme.primary : "transparent"
        border.width: control.ghost ? 1 : 0
        color: {
            if (control.ghost)
            return (control.down || control.hovered) ? Theme.primarySoft : "transparent"
            return (control.down || control.hovered) ? Theme.primaryDark : Theme.primary
        }
        opacity: control.enabled ? 1.0 : 0.55
    }
}
