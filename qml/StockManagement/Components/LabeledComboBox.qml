import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../../Components"

RowLayout {
    id: root

    property string labelText
    property var model
    property int labelWidth: Theme.labelWidth
    property alias currentIndex: comboBox.currentIndex
    readonly property string currentText: comboBox.currentText
    signal selectionChanged(string text)

    Label {
        Layout.preferredWidth: root.labelWidth
        text: root.labelText
    }

    ComboBox {
        id: comboBox
        Layout.fillWidth: true
        model: root.model
        currentIndex: -1
        displayText: currentIndex >= 0 ? currentText : qsTr("请选择")
        onCurrentTextChanged: root.selectionChanged(currentText)
    }
}
