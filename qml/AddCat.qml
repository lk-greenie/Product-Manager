import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Window {
    id: addCat
    visible: true
    width: 250
    height: 150
    title: "添加分类"

    ColumnLayout {
        id: column
        width:parent.width*2/3
        height:parent.height*2/3
        anchors.centerIn: parent

        RowLayout {
            id: catrow
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/2

            Label {
                id: catLabel
                width:40
                text: qsTr("分类名：")
            }

            TextField {
                id: cattextField
                width:parent.width-catLabel.width
                placeholderText: qsTr("")
            }
        }

        RowLayout {
            id: row1
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/2

            Button {
                id:commit
                text: qsTr("确认")
                Layout.alignment: Qt.AlignLeft
                onClicked:{
                    TableDisplay.addCat(cattextField.text)
                }
            }

            Button {
                id: quit
                text: qsTr("取消")
                Layout.alignment: Qt.AlignRight
                onClicked:{
                    addCat.close()
                    addCat.destroy()
                }
            }
        }
    }

}
