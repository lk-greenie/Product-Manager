import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import QtQml.Models 2.15
import QtQuick.Dialogs

Page{
    id:dis
    Column{
        anchors.fill:parent
        RowLayout{
            id:menubar
            width:20
            Button {
                text: "管理"
                onClicked: manage.popup()

                Menu {
                    id: manage
                    MenuItem {
                        text: "添加分类";
                        onTriggered:{
                            if(loginManager.per<3)
                            {
                                var component = Qt.createComponent("AddCat.qml")
                                var addnew
                                if (component.status === Component.Ready) {
                                    addnew=component.createObject(dis)
                                } else {
                                    component.statusChanged.connect(() => {
                                        if (component.status === Component.Ready) {
                                            addnew=component.createObject(dis)
                                        }
                                    });
                                }
                                addnew.show()
                            }else{
                                console.log(loginManager.per)
                            }
                            // MessageDialog:{
                            //     id: messageDialog
                            //     title: "提示"
                            //     text: "权限不够！"
                            //     buttons: StandardButton.Ok | StandardButton.Cancel

                            //     // onAccepted: console.log("用户点击了确定")
                            //     // onRejected: console.log("用户点击了取消")
                            // }
                        }
                    }
                    MenuItem {
                        text: "入库";
                        onTriggered:{
                            if(loginManager.per<3)
                            {
                                var component = Qt.createComponent("In.qml")
                                var addnew
                                if (component.status === Component.Ready) {
                                    addnew=component.createObject(dis)
                                } else {
                                    component.statusChanged.connect(() => {
                                        if (component.status === Component.Ready) {
                                            addnew=component.createObject(dis)
                                        }
                                    });
                                }
                                addnew.show()
                            }else{
                                console.log(loginManager.per)
                            }

                        }
                    }
                    MenuItem {
                        text: "出库";
                        onTriggered:{
                            if(loginManager.per<3)
                            {
                                var component = Qt.createComponent("Out.qml")
                                var addnew
                                if (component.status === Component.Ready) {
                                    addnew=component.createObject(dis)
                                } else {
                                    component.statusChanged.connect(() => {
                                        if (component.status === Component.Ready) {
                                            addnew=component.createObject(dis)
                                        }
                                    });
                                }
                                addnew.show()
                            }else{
                                console.log(loginManager.per)
                            }

                        }
                    }
                }
            }
            Button {
                text: "设置"
                onClicked: set.popup()

                Menu {
                    id:set
                    MenuItem
                    {
                        text: "更改售价";
                        onTriggered:{
                            if(loginManager.per<2)
                            {
                                var component = Qt.createComponent("SetPrice.qml")
                                var addnew
                                if (component.status === Component.Ready) {
                                    addnew=component.createObject(dis)
                                } else {
                                    component.statusChanged.connect(() => {
                                        if (component.status === Component.Ready) {
                                            addnew=component.createObject(dis)
                                        }
                                    });
                                }
                                addnew.show()
                            }else{
                                console.log(loginManager.per)
                            }

                        }
                    }
                    MenuItem {
                        text: "更改警告值";
                        onTriggered:{
                            if(loginManager.per<2)
                            {
                                var component = Qt.createComponent("SetLimits.qml")
                                var addnew
                                if (component.status === Component.Ready) {
                                    addnew=component.createObject(dis)
                                } else {
                                    component.statusChanged.connect(() => {
                                        if (component.status === Component.Ready) {
                                            addnew=component.createObject(dis)
                                        }
                                    });
                                }
                                addnew.show()
                            }else{
                                console.log(loginManager.per)
                            }
                        }
                    }
                }
            }
        }

        RowLayout{
            id:filter
            height:40
            width:parent.width

            Label {
                id: label
                text: qsTr("排序方式：")
            }

            ComboBox {
                id: comboBox
                model:["按进价排序","按售价排序","按数量排序"]
                currentIndex: -1
                displayText: currentIndex>=0?currentText:"请选择"
                onCurrentTextChanged: {
                    if(group.checkedButton){
                        console.log(group.checkedButton.text)
                        TableDisplay.sortStock(catcomboBox.currentText,currentText,group.checkedButton.text)
                    }
                }
            }  

            Row {
                ButtonGroup {
                    id: group;
                    exclusive: true
                    onCheckedButtonChanged: {
                        if(group.checkedButton){
                            console.log(group.checkedButton.text)
                            TableDisplay.sortStock(catcomboBox.currentText,comboBox.currentText,group.checkedButton.text)
                        }
                    }
                }
                CheckBox { text: "升序"; ButtonGroup.group: group }
                CheckBox { text: "降序"; ButtonGroup.group: group }

            }

            function getSort(){

            }

            Label {
                id: catlabel
                text: qsTr("分类：")
            }

            ComboBox {
                id: catcomboBox
                model:TableDisplay.catModel
                currentIndex: -1
                displayText: currentIndex>=0?currentText:"请选择"
                onCurrentTextChanged: {
                    var sort
                    var flag
                    if(comboBox.currentIndex!==-1)sort=comboBox.currentText;
                    if(group.checkedButton)flag=group.checkedButton.text;
                    TableDisplay.displayC(catcomboBox.currentText,"stock",sort,flag)
                }
            }

            TextField {
                id: textField
                placeholderText: qsTr("搜索（商品名）")
                onTextChanged: {
                    TableDisplay.proxyModel.setFilterFixedString(text)
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

                model:TableDisplay.proxyModel

                delegate: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 30
                    // color:{
                    //     console.log(model)
                    //     return "red";
                    // }

                    Text {
                        text: {
                            if(column===3||column===4)
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
