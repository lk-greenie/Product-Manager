import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Window {
    id: inC
    visible: true
    width: 300
    height: 400
    title: "入库"

    ColumnLayout {
        id: inc
        width: parent.width*2/3
        height: parent.height*2/3
        anchors.centerIn: parent


        RowLayout {
            id: catrowLayout
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/7

            Label {
                id: catlabel
                Layout.preferredWidth:50
                text: qsTr("分类名：")
            }

            ComboBox {
                id: catComboBox
                Layout.preferredWidth:parent.width-catlabel.width
                model:TableDisplay.catModel
                currentIndex:-1
                displayText:currentIndex>=0?currentText:"请选择"

            }
        }

        RowLayout {
            id: cnamerowLayout
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/7

            Label {
                id: cnamelabel
                Layout.preferredWidth:50
                text: qsTr("商品名称：")
            }

            TextField {
                id: cnametextField
                Layout.preferredWidth:parent.width-cnamelabel.width
                placeholderText: qsTr("")
            }
        }

        RowLayout {
            id: sumrowLayout
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/7

            Label {
                id: sumlabel
                Layout.preferredWidth:50
                text: qsTr("数量：")
            }

            TextField {
                id: sumtextField
                Layout.preferredWidth:parent.width-sumlabel.width
                placeholderText: qsTr("")
            }
        }

        RowLayout {
            id: bidrowLayout
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height/7

            Label {
                id: bidlabel
                Layout.preferredWidth:50
                text: qsTr("进价：")
            }

            TextField {
                id: bidtextField
                Layout.preferredWidth:parent.width-bidlabel.width
                placeholderText: qsTr("￥")
            }
        }

        RowLayout {
            id: daterowLayout
            Layout.preferredWidth: parent.width
            Layout.preferredHeight:parent.height*2/7


            Label {
                id: datelabel
                Layout.preferredWidth:50
                text: qsTr("保质期：")
            }
            ColumnLayout {
                id: datecolumnLayout
                Layout.preferredWidth:parent.width-datelabel.width
                Layout.preferredHeight:parent.height

                TextField {
                    id: m_datetextField
                    Layout.fillWidth: parent.width
                    placeholderText: qsTr("生产日期(yyyy-mm-dd)")
                }

                TextField {
                    id: e_datetextField
                    Layout.fillWidth: parent.width
                    placeholderText: qsTr("过期日期(yyyy-mm-dd)")
                }
            }
        }

        RowLayout {
            id: rowLayout
            Layout.preferredWidth:parent.width
            Layout.preferredHeight:parent.height/7

            Button {
                id: commit
                Layout.alignment: Qt.AlignLeft
                text: qsTr("确认")
                onClicked:{
                    TableDisplay.inCommodity(catComboBox.currentText,cnametextField.text,sumtextField.text,bidtextField.text,m_datetextField.text,e_datetextField.text)
                }
            }

            Button {
                id: quit
                Layout.alignment: Qt.AlignRight
                text: qsTr("取消")
                onClicked:{
                    inC.close()
                    inC.destroy()
                }
            }
        }
    }


}
