import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../Components"

Label {
    color: "#b91c1c"
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSmall
    visible: text.length > 0
}
