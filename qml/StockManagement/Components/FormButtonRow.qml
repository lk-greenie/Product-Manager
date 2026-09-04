import QtQuick 2.15
import QtQuick.Layouts
import "../../Components"

RowLayout {
    id: root

    signal accepted()
    signal rejected()

    Layout.fillWidth: true
    spacing: 10
    Layout.topMargin: 8

    PrimaryButton {
        text: qsTr("确认")
        Layout.alignment: Qt.AlignLeft
        onClicked: root.accepted()
    }

    Item { Layout.fillWidth: true }

    SecondaryButton {
        text: qsTr("取消")
        Layout.alignment: Qt.AlignRight
        onClicked: root.rejected()
    }
}
