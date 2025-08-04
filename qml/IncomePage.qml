import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Page {
    id:incomePage
    Column{
        anchors.fill:parent
        RowLayout{
            id:filter
            height:40
            width:parent.width

            Label {
                id: label1
                text: qsTr("分类：")
            }

            ComboBox {
                id: catcomboBox
                model:TableDisplay.catModel
                currentIndex:-1
                displayText:currentIndex>=0?currentText:"请选择"
                onCurrentTextChanged: {
                    TableDisplay.displayC(currentText,"income")
                    incv.text=TableDisplay.sumCheck(catcomboBox.currentText,"income")+"￥"                        }
                }

            Label {
                id: inc
                text: qsTr("总收入：")
            }

            TextField {
                id: incv
                text:TableDisplay.sumCheck("全部","income")+"￥"
            }

            TextField {
                id: textField
                placeholderText: qsTr("搜索（商品名）")
                onTextChanged: {
                    TableDisplay.proxyModel3.setFilterFixedString(text)
                }
            }
        }

        Column {
            id:tabview
            width:parent.width
            height:parent.height-filter.height

            //水平表头 - 现在会显示在表格上方
            HorizontalHeaderView {
                id: horizontalHeader
                Layout.fillWidth: true
                syncView: tableView
                height: 30  // 明确设置表头高度

                delegate: Rectangle {
                    color: "#f0f0f0"
                    border.color: "#cccccc"
                    implicitWidth: 200
                    implicitHeight: 30
                    Text {
                        text: model.display || modelData
                        anchors.centerIn: parent
                    }
                }
            }

            // 表格内容
            TableView {
                id: tableView
                width: parent.width
                height: tabview.height - horizontalHeader.height

                model: TableDisplay.proxyModel3

                delegate: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 30


                    Text {

                        text: {
                            if(column===6)
                            {
                                var rawDate=new Date(display);
                                return rawDate.toLocaleDateString(Qt.locale(),"yyyy-MM-dd");
                            }else return display;

                        }
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
}
