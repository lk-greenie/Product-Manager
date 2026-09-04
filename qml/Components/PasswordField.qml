import QtQuick 2.15
import QtQuick.Controls 2.15

// 密码输入框：复用 StyledTextField 的白底圆角样式，并在右侧加入“眼睛”图标，
// 点击可在隐藏/显示明文之间切换（echoMode: Password <-> Normal）。
// 登录/注册页的密码框使用本组件。
TextField {
    id: control

    // 是否显示明文（默认隐藏，即密码态）
    property bool showPassword: false

    verticalAlignment: TextInput.AlignVCenter
    implicitHeight: Theme.controlHeight
    implicitWidth: 180
    font.pixelSize: Theme.fontSmall
    color: Theme.textPrimary
    placeholderTextColor: Theme.textMuted
    echoMode: control.showPassword ? TextInput.Normal : TextInput.Password
    leftPadding: 12
    rightPadding: 34

    background: Rectangle {
        radius: Theme.radiusSmall
        color: control.enabled ? Theme.surface : Theme.surfaceMuted
        // 与 StyledTextField 使用完全相同的默认/聚焦边框，避免密码框看起来像无边框文本。
        border.color: control.activeFocus ? Theme.primary : Theme.border
        border.width: control.activeFocus ? 2 : 1
    }

    ToolButton {
        id: eyeButton
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        hoverEnabled: true
        padding: 0
        Accessible.name: control.showPassword ? qsTr("隐藏密码") : qsTr("显示密码")
        ToolTip.visible: hovered
        ToolTip.text: control.showPassword ? qsTr("隐藏密码") : qsTr("显示密码")
        onClicked: control.showPassword = !control.showPassword

        contentItem: Canvas {
            id: eyeIcon
            width: 20
            height: 20

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const cx = width / 2
                const cy = height / 2

                // 眼睛轮廓：上下两条二次贝塞尔构成的杏仁形
                ctx.beginPath()
                ctx.moveTo(2, cy)
                ctx.quadraticCurveTo(cx, 1.5, width - 2, cy)
                ctx.quadraticCurveTo(cx, height - 1.5, 2, cy)
                ctx.lineWidth = 1.6
                ctx.strokeStyle = control.showPassword ? Theme.primary : Theme.textSecondary
                ctx.stroke()

                // 瞳孔
                ctx.beginPath()
                ctx.arc(cx, cy, 2.2, 0, Math.PI * 2)
                ctx.fillStyle = control.showPassword ? Theme.primaryDark : Theme.textSecondary
                ctx.fill()

                // 隐藏态：叠加一条斜线表示“不可见”
                if (!control.showPassword) {
                    ctx.beginPath()
                    ctx.moveTo(3, height - 3)
                    ctx.lineTo(width - 3, 3)
                    ctx.lineWidth = 1.6
                    ctx.strokeStyle = Theme.textSecondary
                    ctx.stroke()
                }
            }
        }

        background: Rectangle {
            radius: Theme.radiusSmall
            color: eyeButton.pressed ? Theme.primarySoft
                   : eyeButton.hovered ? Theme.surfaceMuted : "transparent"
            border.color: eyeButton.hovered ? Theme.border : "transparent"
            border.width: eyeButton.hovered ? 1 : 0
        }
    }

    // Canvas 不会因为外部属性变化自动重绘，显式请求重绘才能让“显示/隐藏”图标真正变化。
    onShowPasswordChanged: eyeIcon.requestPaint()
}
