import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../../Components"

RowLayout {
    id: root

    property string labelText
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias echoMode: field.echoMode
    property int labelWidth: Theme.labelWidth

    Label {
        Layout.preferredWidth: root.labelWidth
        text: root.labelText
    }

    StyledTextField {
        id: field
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.controlHeight
    }
}
