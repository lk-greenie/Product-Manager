import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "../Components"
import "../Services"

Page{
    id:displayPage
    Layout.fillWidth: true
    Layout.fillHeight: true

    function openWindow(component) {
        const window = component.createObject(displayPage)
        if (window)
            window.show()
    }

    Component { id: addCategoryWindow; AddCat {} }
    Component { id: inboundWindow; In {} }
    Component { id: outboundWindow; Out {} }
    Component { id: priceWindow; SetPrice {} }
    Component { id: limitsWindow; SetLimits {} }

    ColumnLayout{
        anchors.fill:parent
        spacing: 0

        // 顶部工具栏
        ToolBar {
            id:menubar
            position: ToolBar.Header
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            RowLayout {
                anchors.fill: parent
                spacing: 0

                ToolButton {
                    text: "管理"
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth:  menubar.width/23
                    Layout.fillHeight: true
                    onClicked: manageMenu.open()
                    Menu {
                        id: manageMenu
                        y: parent.height
                        MenuItem {
                            text: "添加分类";
                            // 权限约定：分类维护要求 per<3
                            onTriggered:{
                                if (BackendContract.canAddCategory(loginManager.per))
                                    displayPage.openWindow(addCategoryWindow)
                                else
                                    accessStatus.text = qsTr("当前角色没有添加分类权限")
                            }
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "入库";
                            // 权限约定：入库要求 per<3
                            onTriggered: {
                                if (BackendContract.canInOutStock(loginManager.per))
                                    displayPage.openWindow(inboundWindow)
                                else
                                    accessStatus.text = qsTr("当前角色没有入库权限")
                            }
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "出库";
                            // 权限约定：出库要求 per<3
                            onTriggered: {
                                if (BackendContract.canInOutStock(loginManager.per))
                                    displayPage.openWindow(outboundWindow)
                                else
                                    accessStatus.text = qsTr("当前角色没有出库权限")
                            }
                        }
                    }
                }

                ToolSeparator {
                    Layout.fillHeight:true
                }

                ToolButton {
                    text: "设置"
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth:  menubar.width/23
                    Layout.fillHeight: true
                    onClicked: editMenu.open()
                    Menu {
                        id: editMenu
                        y: parent.height
                        MenuItem {
                            text: "更改售价";
                            // 权限约定：售价设置要求 per<2
                            onTriggered: {
                                if (BackendContract.canChangeStockSettings(loginManager.per))
                                    displayPage.openWindow(priceWindow)
                                else
                                    accessStatus.text = qsTr("当前角色没有修改售价权限")
                            }
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "更改警告值";
                            // 权限约定：阈值设置要求 per<2
                            onTriggered: {
                                if (BackendContract.canChangeStockSettings(loginManager.per))
                                    displayPage.openWindow(limitsWindow)
                                else
                                    accessStatus.text = qsTr("当前角色没有修改警告阈值权限")
                            }
                        }
                    }
                }
                Item {Layout.fillWidth: true}
            }
        }

        RowLayout{
            id:filter
            Layout.preferredHeight: displayPage.height/15
            Layout.fillWidth: true
            spacing:0

            Item{Layout.fillWidth: true}

            RowLayout{
                Layout.preferredWidth: displayPage.width*0.15
                Layout.fillHeight: true
                spacing:5

                Label {
                    id: sortLabel
                    text: qsTr("排序方式：")
                    font.pixelSize: Theme.fontNormal
                    Layout.alignment: Qt.AlignVCenter
                }

                ComboBox {
                    id: comboBox
                    Layout.preferredHeight: sortLabel.height
                    Layout.alignment: Qt.AlignVCenter
                    model: [BackendContract.sortByPurchasePrice,
                           BackendContract.sortBySalePrice,
                           BackendContract.sortByQuantity]
                    currentIndex: -1
                    displayText: currentIndex>=0?currentText:"请选择"
                    onCurrentTextChanged: {
                        if(group.checkedButton){
                            console.log(group.checkedButton.text)
                            TableDisplay.sortStock(catcomboBox.currentText,currentText,group.checkedButton.text)
                        }
                    }
                }
            }

            Item{Layout.preferredWidth: displayPage.width*0.1}

            RowLayout {
                Layout.preferredWidth: displayPage.width*0.15
                Layout.fillHeight: true
                spacing:5

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
                CheckBox {
                    text: "升序";
                    font.pixelSize: Theme.fontNormal;
                    ButtonGroup.group: group
                    Layout.alignment: Qt.AlignVCenter
                }
                CheckBox {
                    text: "降序";
                    font.pixelSize: Theme.fontNormal;
                    ButtonGroup.group: group
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item{Layout.preferredWidth: displayPage.width*0.1}

            RowLayout{
                Layout.preferredWidth: displayPage.width*0.15
                Layout.fillHeight: true
                spacing:5

                Label {
                    id: catlabel
                    text: qsTr("分类：")
                    font.pixelSize: Theme.fontNormal
                    Layout.alignment: Qt.AlignVCenter
                }

                ComboBox {
                    id: catcomboBox
                    Layout.preferredHeight: catlabel.height
                    Layout.alignment: Qt.AlignVCenter
                    model:TableDisplay.catModel
                    currentIndex: -1
                    displayText: currentIndex>=0?currentText:"请选择"
                    onCurrentTextChanged: {
                        var sort
                        var flag
                        if(comboBox.currentIndex!==-1)sort=comboBox.currentText;
                        if(group.checkedButton)flag=group.checkedButton.text;
                        TableDisplay.displayC(catcomboBox.currentText, BackendContract.stockFlag, sort, flag)
                    }
                }
            }

            Item{Layout.preferredWidth: displayPage.width*0.1}

            StyledTextField {
                id: textField
                Layout.preferredWidth: displayPage.width*0.15
                Layout.alignment: Qt.AlignVCenter
                placeholderText: qsTr("搜索（商品名）")
                onTextChanged: {
                    TableDisplay.proxyModel.setFilterFixedString(text)
                }
            }

            Item{Layout.fillWidth: true}
        }

        // 库存表：复用 DataTable，保留进价色标列(2)与日期列(3/4)格式化
        DataTable {
            id: tabview
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: TableDisplay.proxyModel
            dateColumns: [3, 4]
            hiddenColumns: BackendContract.canViewPrivateStockColumns(loginManager.per) ? [] : [2, 7, 8]
            warningQuantityColumn: 6
            upperLimitColumn: 7
            lowerLimitColumn: 8
            expiryDateColumns: [3, 4]
            showStatusColors: BackendContract.canViewPrivateStockColumns(loginManager.per)
            columnCount: BackendContract.canViewPrivateStockColumns(loginManager.per) ? 9 : 6
        }

        // 底部状态栏
        Rectangle {
            id: statusBar
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.statusBarHeight
            color: Theme.statusBar

            Row {
                anchors.fill: parent
                spacing: 10

                // 状态信息
                Text {
                    id: accessStatus
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("状态：正常")
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                }

                // 时间显示
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(new Date(), "hh:mm:ss")
                    color: Theme.textOnPrimary
                    font.pixelSize: Theme.fontSmall

                    // 更新时间
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                    }
                }
            }
        }
    }
}
