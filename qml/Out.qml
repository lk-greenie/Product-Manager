import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Window {
    id: outC
    visible: true
    width: 300
    height: 400
    title: "出库"

    ColumnLayout {
        id: column
        width: parent.width*2/3
        height: parent.height*2/3
        anchors.centerIn: parent

        RowLayout {
            id: catrow
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/5

            Label {
                id: catlabel
                Layout.preferredWidth:cnamelabel.width
                text: qsTr("分类名：")
            }

            ComboBox {
                id: catcomboBox
                Layout.preferredWidth:parent.width-catlabel.width
                model:TableDisplay.catModel
                currentIndex: -1
                displayText:currentIndex>=0?currentText:"请选择"
                onCurrentTextChanged: {
                    TableDisplay.updatecnameModel(currentText)
                }
            }
        }

        RowLayout {
            id:cnamerow
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/5

            Label {
                id: cnamelabel
                Layout.preferredWidth:50
                text: qsTr("商品名称：")
            }

            ComboBox {
                id: cnamecomboBox
                Layout.preferredWidth:parent.width-cnamelabel.width
                model:TableDisplay.cnameModel
                currentIndex: -1
                displayText:currentIndex>=0?currentText:"请选择"
                onCurrentTextChanged: {
                    pricetextField.text=TableDisplay.getPrice(catcomboBox.currentText,currentText)
                }
            }
        }

        RowLayout {
            id: sumrow
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/5

            Label {
                id: sumlabel
                Layout.preferredWidth:cnamelabel.width
                text: qsTr("数量：")
            }

            TextField {
                id: sumtextField
                Layout.preferredWidth:parent.width-sumlabel.width
                placeholderText: qsTr("")
            }
        }

        RowLayout {
            id: pricerow
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/5

            Label {
                id: pricelabel
                Layout.preferredWidth:cnamelabel.width
                text: qsTr("售价：")
            }

            TextField {
                id: pricetextField
                Layout.preferredWidth:parent.width-pricelabel.width
                placeholderText: qsTr("￥")
            }
        }

        RowLayout {
            id: rowLayout
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/5

            Button {
                id: commit
                Layout.alignment: Qt.AlignLeft
                text: qsTr("确认")
                onClicked:{
                    TableDisplay.outCommodity(catcomboBox.currentText,cnamecomboBox.currentText,sumtextField.text,pricetextField.text)
                }
            }

            Button {
                id: quit
                Layout.alignment: Qt.AlignRight
                text: qsTr("取消")
                onClicked:{
                    outC.close()
                    outC.destroy()
                }
            }
        }
    }


}
