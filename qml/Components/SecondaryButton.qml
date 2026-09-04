import QtQuick 2.15
import QtQuick.Controls 2.15

// 白/浅灰次按钮：注册/导出/返回登录等。
// 同样基于 Button 原生 down/hovered 状态，不内嵌 MouseArea。
// 对外属性：text（原生）；信号：clicked（原生）。
Button {
    id: control

    implicitHeight: Theme.controlHeight
    implicitWidth: Math.max(96, contentItem.implicitWidth + 28)
    font.pixelSize: Theme.fontNormal
    font.weight: Font.Medium

    contentItem: Text {
        text: control.text
        font: control.font
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1.0 : 0.55
    }

    background: Rectangle {
        radius: Theme.radiusSmall
        color: (control.down || control.hovered) ? Theme.statusBar : Theme.surface
        border.color: control.activeFocus ? Theme.primary : Theme.border
        border.width: 1
        opacity: control.enabled ? 1.0 : 0.55
    }
}
