import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Window 2.15

Window {
    id: root

    width: 440
    height: 330
    minimumWidth: 390
    minimumHeight: 300
    visible: false
    title: qsTr("数据库服务器设置")
    color: Theme.appBackground
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint

    function showFor(owner) {
        transientParent = owner
        x = owner.x + Math.round((owner.width - width) / 2)
        y = owner.y + Math.round((owner.height - height) / 2)
        show()
        raise()
        requestActivate()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pagePadding
            spacing: Theme.sectionSpacing

            ServerSettingsPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
