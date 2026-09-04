import QtQuick 2.15
import QtQuick.Controls 2.15

Label {
    id: root

    property int displayDuration: 2600

    color: Theme.danger
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSmall
    visible: text.length > 0

    Timer {
        id: clearTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.text = ""
    }

    onTextChanged: {
        if (text.length > 0)
            clearTimer.restart()
        else
            clearTimer.stop()
    }
}
