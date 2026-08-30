import QtQuick 2.15
import QtQuick.Controls 2.15

// 白/浅灰次按钮：注册/导出/返回登录等。
// 同样基于 Button 原生 down/hovered 状态，不内嵌 MouseArea。
// 对外属性：text（原生）；信号：clicked（原生）。
Button {
    id: control

    font.pixelSize: Theme.fontNormal
    implicitHeight: Theme.controlHeight

    contentItem: Text {
        text: control.text
        font: control.font
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1.0 : 0.5
    }

    background: Rectangle {
        radius: Theme.radiusSmall
        // 悬停/按下时变浅灰，否则白色（复刻登录页“注册”按钮观感）
        color: (control.down || control.hovered) ? Theme.statusBar : Theme.surface
        opacity: control.enabled ? 1.0 : 0.5
    }
}
