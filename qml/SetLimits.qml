import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Window {
    id: setL
    visible: true
    width: 250
    height: 400
    title: "更改警告值"

    // TabBar - 顶部导航标签
    TabBar {
        id: tabBar
        width: parent.width

        TabButton {
            text: qsTr("分类种类数警告值")
        }
        TabButton {
            text: qsTr("商品数警告值")
        }
    }

    SwipeView{
        id:che
        anchors {
            top: tabBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        currentIndex: tabBar.currentIndex  // 与TabBar绑定


        //修改分类种类数警告值页面
        Page{
            ColumnLayout {
                id: columnLayout
                anchors.fill:parent
                RowLayout {
                    id: rowLayout
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: catlabel
                        Layout.preferredWidth: uplabel.width
                        text: qsTr("分类名：")
                    }

                    ComboBox {
                        id: catcomboBox
                        model:TableDisplay.catModel
                        Layout.preferredWidth: parent.width-catlabel.width
                        currentIndex: -1
                        displayText:currentIndex>=0?currentText:"请选择"
                        onCurrentTextChanged: {
                            currentsumtextField.text=TableDisplay.sumCat(currentText)
                        }
                    }

                }

                RowLayout {
                    id: rowLayout1
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: uplabel
                        Layout.preferredWidth:80
                        text: qsTr("种类数上限值：")
                    }

                    TextField {
                        id: upField
                        Layout.preferredWidth: parent.width-uplabel.width
                        placeholderText: qsTr("")
                    }
                }

                RowLayout {
                    id: rowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: downlabel
                        Layout.preferredWidth:uplabel.width
                        text: qsTr("种类数下限值：")
                    }

                    TextField {
                        id: downtextField
                        Layout.preferredWidth: parent.width-downlabel.width
                        placeholderText: qsTr("")
                    }
                }

                RowLayout {
                    id: rowLayout3
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: currentsumlabel
                        Layout.preferredWidth:uplabel.width
                        text: qsTr("现有种类数：")
                    }

                    TextField {
                        id: currentsumtextField
                        Layout.preferredWidth: parent.width-currentsumlabel.width
                        placeholderText: qsTr("")
                    }
                }

                RowLayout {
                    id: rowLayout9
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Button {
                        id: commit
                        Layout.alignment: Qt.AlignLeft
                        text: qsTr("确认")
                        onClicked:{

                        }
                    }

                    Button {
                        id: quit
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("取消")
                        onClicked:{
                            setL.close()
                            setL.destroy()
                        }
                    }
                }
            }
        }

        //修改商品数警告值页面
        Page{
            ColumnLayout {
                id: columnLayout2
                anchors.fill:parent
                RowLayout {
                    id: catrowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: catlabel2
                        Layout.preferredWidth: uplabel2.width
                        text: qsTr("分类名：")
                    }

                    ComboBox {
                        id: catcomboBox2
                        Layout.preferredWidth: parent.width-catlabel2.width
                        model:TableDisplay.catModel
                        currentIndex: -1
                        displayText:currentIndex>=0?currentText:"请选择"
                        onCurrentTextChanged: {
                            TableDisplay.updatecnameModel(currentText)
                        }

                    }

                }

                RowLayout {
                    id: cnamerowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: cnamelabel
                        Layout.preferredWidth: uplabel2.width
                        text: qsTr("商品名称：")
                    }

                    ComboBox {
                        id: cnamecatcomboBox2
                        Layout.preferredWidth: parent.width-cnamelabel.width
                        model:TableDisplay.cnameModel
                        currentIndex: -1
                        displayText:currentIndex>=0?currentText:"请选择"
                        onCurrentTextChanged: {
                            currentsumtextField2.text=TableDisplay.sumC(catcomboBox2.currentText,cnamecatcomboBox2.currentText)
                        }
                    }
                }

                RowLayout {
                    id: uprowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: uplabel2
                        Layout.preferredWidth: 80
                        text: qsTr("商品数上限值：")
                    }

                    TextField {
                        id:uptextField2
                        Layout.preferredWidth: parent.width-uplabel2.width
                        placeholderText: qsTr("")
                    }
                }

                RowLayout {
                    id: downrowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id: downlabel2
                        Layout.preferredWidth: uplabel2.width
                        text: qsTr("商品数下限值：")
                    }

                    TextField {
                        id: downtextField2
                        Layout.preferredWidth: parent.width-downlabel2.width
                        placeholderText: qsTr("")
                    }
                }

                RowLayout {
                    id: currentsumrowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Label {
                        id:currentsumlabel2
                        Layout.preferredWidth:uplabel2.width
                        text: qsTr("现有商品数：")
                    }

                    TextField {
                        id: currentsumtextField2
                        Layout.preferredWidth: parent.width-currentsumlabel2.width
                        placeholderText: qsTr("")
                    }
                }

                RowLayout {
                    id: buttonrowLayout2
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight:parent.height/5

                    Button {
                        id: commit2
                        Layout.alignment: Qt.AlignLeft
                        text: qsTr("确认")
                        onClicked:{
                            TableDisplay.setLimits(catcomboBox2.currentText,cnamecatcomboBox2.currentText,uptextField2.text,downtextField2.text)
                        }
                    }

                    Button {
                        id: quit2
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("取消")
                        onClicked:{
                            setL.close()
                            setL.destroy()
                        }
                    }
                }
            }
        }
    }
}
