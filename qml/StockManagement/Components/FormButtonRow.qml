import QtQuick 2.15
import QtQuick.Layouts
import "../../Components"

RowLayout {
    id: root

    signal accepted()
    signal rejected()

    Layout.fillWidth: true

    PrimaryButton {
        text: qsTr("确认")
        Layout.alignment: Qt.AlignLeft
        onClicked: root.accepted()
    }

    SecondaryButton {
        text: qsTr("取消")
        Layout.alignment: Qt.AlignRight
        onClicked: root.rejected()
    }
}
