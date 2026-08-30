import QtQuick 2.15
import QtQuick.Controls 2.15

// MainMenu 左侧导航按钮。
// 用 Button 原生 checked/hovered/down 状态驱动背景色，消除 MouseArea 反模式与重复。
//
// 对外属性：
//   text            —— 导航文字（Button 原生）
//   expanded: bool  —— 导航栏是否展开（收起时不显示文字），默认 true
//   active: bool    —— 是否为当前选中项（背景高亮为白色）；等价于 checked 的显式别名
//   subItem: bool   —— 是否为子项（子菜单项字号更小），默认 false
//   toggleStyle:bool—— true 时选中态背景用 primaryDark（用于“收支记录/数据可视化”这类展开切换按钮），
//                       false 时选中态背景用白色（用于叶子导航项），默认 false
// 信号：clicked（Button 原生）
Button {
    id: control

    property bool expanded: true
    property alias active: control.checked
    property bool subItem: false
    property bool toggleStyle: false

    checkable: true
    flat: true

    contentItem: Text {
        text: control.expanded ? control.text : ""
        font.pixelSize: control.subItem ? Theme.fontSmall : Theme.fontLarge
        // 选中/悬停时文字变黑，否则白色（复刻 MainMenu 原逻辑）
        color: (control.down || control.hovered || (control.checked && !control.toggleStyle))
               ? Theme.textPrimary : Theme.textOnPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radiusLarge
        color: {
            if (control.toggleStyle)
                // 展开切换按钮：选中/悬停用深蓝，否则透明
                return (control.down || control.hovered || control.checked)
                        ? Theme.primaryDark : "transparent"
            // 叶子导航项：选中/悬停用白色，否则透明
            return (control.down || control.hovered || control.checked)
                    ? Theme.surface : "transparent"
        }
    }
}
