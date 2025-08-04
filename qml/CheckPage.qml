import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts

Page{
    id:check

    // TabBar - 顶部导航标签
    TabBar {
        id: tabBar
        width: parent.width

        TabButton {
            text: qsTr("总交易记录")
        }
        TabButton {
            text: qsTr("支出记录")
        }
        TabButton {
            text: qsTr("收入记录")
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


        //总交易记录页面
        Page{
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
                        onCurrentTextChanged:{
                            TableDisplay.displayC(currentText,"check")
                            chv.text=TableDisplay.sumCheck(catcomboBox.currentText,"check")+"￥"
                        }
                    }

                    Label {
                        id: ch
                        text: qsTr("总额：")
                    }

                    TextField {
                        id: chv
                        text:TableDisplay.sumCheck("全部","check")+"￥"
                    }

                    TextField {
                        id: textField
                        placeholderText: qsTr("搜索（商品名）")
                        onTextChanged: {
                            TableDisplay.proxyModel1.setFilterFixedString(text)
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

                        model: TableDisplay.proxyModel1

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

        //支出记录页面
        ExpensePage{

        }

        //收入记录页面
        IncomePage {

        }
    }




}
