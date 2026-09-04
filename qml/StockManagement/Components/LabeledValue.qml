import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../../Components"

// 只读展示行：外观与输入框保持一致，标签宽度、文字基线和左右内边距统一。
// 用于入库/出库/售价/库存预警弹窗中的只读数据展示。
RowLayout {
    id: root

    property string labelText
    property string valueText: ""
    property int labelWidth: Theme.labelWidth

    Label {
        Layout.preferredWidth: root.labelWidth
        text: root.labelText
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
        verticalAlignment: Text.AlignVCenter
    }

    StyledTextField {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.controlHeight
        readOnly: true
        text: root.valueText
    }
}
