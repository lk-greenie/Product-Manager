import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

// MainMenu 左侧导航按钮。
// 用 Button 原生 checked/hovered/down 状态驱动背景色，消除 MouseArea 反模式与重复。
//
// 对外属性：
//   text            —— 导航文字（Button 原生）
//   expanded: bool  —— 导航栏是否展开（收起时不显示文字），默认 true
//   active: bool    —— 是否为当前选中项；等价于 checked 的显式别名
//   subItem: bool   —— 是否为子项（子菜单项字号更小），默认 false
//   toggleStyle:bool—— true 时作为分组展开按钮，不参与当前路由选中态
// 信号：clicked（Button 原生）
Button {
    id: control

    property bool expanded: true
    property alias active: control.checked
    property bool subItem: false
    property bool toggleStyle: false
    property bool actionOnly: false
    property bool sectionOpen: false
    property string iconKind: "inventory"
    property bool lightSurface: false
    readonly property color foregroundColor: control.lightSurface
                                           ? ((control.checked && !control.toggleStyle) ? Theme.primaryDark : Theme.textPrimary)
                                           : Theme.textOnPrimary

    // 选中态完全由外层路由决定。若设为 checkable，重复点击当前按钮会让
    // Button 自动反选并覆盖 active 绑定，导致导航栏暂时没有任何选中项。
    checkable: false
    flat: true
    hoverEnabled: true
    Accessible.name: control.text
    ToolTip.visible: !control.expanded && control.hovered && control.text !== ""
    ToolTip.text: control.text

    contentItem: Item {
        // 收起态使用独立的居中图标标签，不把展开态 RowLayout 压缩到窄栏中。
        NavIcon {
            anchors.centerIn: parent
            visible: !control.expanded
            kind: control.iconKind
            color: control.foregroundColor
            opacity: control.enabled ? 1.0 : 0.5
        }

        RowLayout {
            anchors.fill: parent
            visible: control.expanded
            spacing: 10

            NavIcon {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                kind: control.iconKind
                color: control.foregroundColor
                opacity: control.enabled ? 1.0 : 0.5
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: control.text
                font.pixelSize: control.subItem ? Theme.fontSmall : Theme.fontNormal
                color: control.foregroundColor
                opacity: control.enabled ? 1.0 : 0.5
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        color: {
            if (control.lightSurface) {
                if (control.checked)
                    return Theme.primarySoft
                return (control.down || control.hovered) ? Theme.accentLight : "transparent"
            }
            if (control.toggleStyle)
                // 分组只表达展开状态，不抢占叶子路由的选中态。
                return (control.down || control.hovered || control.sectionOpen)
                        ? Theme.sidebarHover : "transparent"
            // 深色侧栏中的当前页使用主蓝色块，收起后仍能明确识别选中位置。
            if (control.checked)
                return Theme.primary
            return (control.down || control.hovered || control.checked)
                    ? Theme.sidebarHover : "transparent"
        }
    }
}
