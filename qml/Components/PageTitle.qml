import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

// 页面标题区：统一标题、辅助说明和上下留白，适合工作台主内容页。
RowLayout {
    id: root

    property string title
    property string subtitle: ""
    property bool centered: false

    Layout.fillWidth: true
    Layout.preferredHeight: subtitle === "" ? 34 : 48
    spacing: 10

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Label {
            text: root.title
            color: Theme.textPrimary
            font.pixelSize: Theme.fontLarge
            font.weight: Font.DemiBold
            horizontalAlignment: root.centered ? Text.AlignHCenter : Text.AlignLeft
            Layout.fillWidth: true
        }

        Label {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
            horizontalAlignment: root.centered ? Text.AlignHCenter : Text.AlignLeft
            Layout.fillWidth: true
        }
    }
}
