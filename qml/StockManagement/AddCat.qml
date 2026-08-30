import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"

Window {
    id: window
    visible: true
    width: 320
    height: 200
    title: qsTr("添加分类")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        LabeledField { id: categoryField; labelText: qsTr("分类名：") }
        StatusLabel { id: statusLabel; Layout.fillWidth: true }

        FormButtonRow {
            onAccepted: {
                const message = TableDisplay.addCat(categoryField.text)
                if (message === "") {
                    window.close()
                    window.destroy()
                } else {
                    statusLabel.text = message
                }
            }
            onRejected: {
                window.close()
                window.destroy()
            }
        }
    }
}
