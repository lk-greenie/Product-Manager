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

    background: Rectangle { color: Theme.appBackground }

    function openWindow(component) {
        const window = component.createObject(displayPage)
        if (window) {
            const owner = displayPage.Window.window
            window.transientParent = owner
            window.x = owner.x + Math.round((owner.width - window.width) / 2)
            window.y = owner.y + Math.round((owner.height - window.height) / 2)
            window.show()
        }
    }

    property bool sortAscending: true

    function applyStockSort() {
        if (comboBox.currentIndex < 0)
            return
        TableDisplay.sortStock(catcomboBox.currentText, comboBox.currentText,
                               sortAscending ? BackendContract.ascending : BackendContract.descending)
    }

    function refreshStockFilter() {
        const sort = comboBox.currentIndex >= 0 ? comboBox.currentText : ""
        const order = comboBox.currentIndex >= 0
                ? (sortAscending ? BackendContract.ascending : BackendContract.descending) : ""
        TableDisplay.displayC(catcomboBox.currentText, BackendContract.stockFlag, sort, order)
    }

    Component { id: addCategoryWindow; AddCat {} }
    Component { id: inboundWindow; In {} }
    Component { id: outboundWindow; Out {} }
    Component { id: priceWindow; SetPrice {} }
    Component { id: limitsWindow; SetLimits {} }

    Timer {
        id: stockSearchDebounce
        interval: 180
        repeat: false
        onTriggered: TableDisplay.proxyModel.setFilterFixedString(textField.text.trim())
    }

    Component {
        id: commandMenuItem

        MenuItem {
            id: item
            implicitHeight: Theme.controlHeight

            contentItem: Text {
                leftPadding: 12
                rightPadding: 12
                text: item.text
                color: item.highlighted ? Theme.primaryDark : Theme.textPrimary
                font.pixelSize: Theme.fontSmall
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: Theme.radiusSmall
                color: item.highlighted ? Theme.primarySoft : "transparent"
            }
        }
    }

    ColumnLayout{
        anchors.fill: parent
        anchors.leftMargin: Theme.pagePadding
        anchors.rightMargin: Theme.pagePadding
        anchors.topMargin: 0
        anchors.bottomMargin: Theme.pagePadding
        spacing: 12

        // 顶部命令栏紧贴页面顶边，使用标准菜单栏承载可展开操作。
        MenuBar {
            id: commandBar
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            background: Rectangle {
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusMedium
            }
            delegate: MenuBarItem {
                id: menuBarItem
                implicitWidth: 104
                implicitHeight: commandBar.height

                contentItem: Text {
                    text: menuBarItem.text + qsTr("  ▾")
                    color: menuBarItem.highlighted ? Theme.primaryDark : Theme.textPrimary
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: menuBarItem.highlighted ? Theme.primarySoft : "transparent"
                    border.color: menuBarItem.highlighted ? Theme.borderStrong : "transparent"
                    border.width: menuBarItem.highlighted ? 1 : 0
                }
            }
            // 顾客访客为只读角色，不显示顶部工具栏；店员只保留入库/出库，店主全部可用
            visible: !BackendContract.isVisitor(loginManager.per)

            Menu {
                title: qsTr("管理")
                // Menu.visible 会直接控制 Popup 可见性，不能用于菜单栏权限判断。
                // 当前命令栏已对访客整体隐藏；店主/店员都可使用管理菜单。
                enabled: BackendContract.canInOutStock(loginManager.per) || BackendContract.canAddCategory(loginManager.per)
                width: 160
                delegate: commandMenuItem
                background: Rectangle {
                    color: Theme.surface
                    border.color: Theme.borderStrong
                    border.width: 1
                    radius: Theme.radiusSmall
                }

                MenuItem {
                    text: qsTr("添加分类")
                    visible: BackendContract.canAddCategory(loginManager.per)
                    onTriggered: displayPage.openWindow(addCategoryWindow)
                }
                MenuSeparator { visible: BackendContract.canAddCategory(loginManager.per) }
                MenuItem {
                    text: qsTr("入库")
                    visible: BackendContract.canInOutStock(loginManager.per)
                    onTriggered: displayPage.openWindow(inboundWindow)
                }
                MenuSeparator { visible: BackendContract.canInOutStock(loginManager.per) }
                MenuItem {
                    text: qsTr("出库")
                    visible: BackendContract.canInOutStock(loginManager.per)
                    onTriggered: displayPage.openWindow(outboundWindow)
                }
            }

            Menu {
                title: qsTr("设置")
                // 店员保留禁用状态的菜单标题作为权限提示，菜单内容不可展开。
                enabled: BackendContract.canChangeStockSettings(loginManager.per)
                width: 160
                delegate: commandMenuItem
                background: Rectangle {
                    color: Theme.surface
                    border.color: Theme.borderStrong
                    border.width: 1
                    radius: Theme.radiusSmall
                }

                MenuItem {
                    text: qsTr("更改售价")
                    onTriggered: displayPage.openWindow(priceWindow)
                }
                MenuSeparator {}
                MenuItem {
                    text: qsTr("更改警告值")
                    onTriggered: displayPage.openWindow(limitsWindow)
                }
            }
        }

        PageTitle {
            title: BackendContract.isVisitor(loginManager.per) ? qsTr("库存商品") : qsTr("库存管理")
            subtitle: BackendContract.isVisitor(loginManager.per)
                      ? qsTr("浏览商品分类、售价、库存数量及保质期信息")
                      : qsTr("查看库存状态、保质期和库存预警")
        }

            RowLayout {
                id: filter
            Layout.preferredHeight: 58
            Layout.fillWidth: true
            spacing: 12

            Item{Layout.fillWidth: true}

            RowLayout {
                Layout.preferredWidth: 310
                Layout.fillHeight: true
                spacing:5

                Label {
                    id: sortLabel
                    text: qsTr("排序方式：")
                    font.pixelSize: Theme.fontNormal
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledComboBox {
                    id: comboBox
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: Theme.controlHeight
                    Layout.alignment: Qt.AlignVCenter
                    model: [BackendContract.sortByPurchasePrice,
                           BackendContract.sortBySalePrice,
                           BackendContract.sortByQuantity]
                    currentIndex: -1
                    displayText: currentIndex >= 0 ? currentText : qsTr("选择排序")
                    onActivated: displayPage.applyStockSort()
                }
                ToolButton {
                    id: orderButton
                    visible: comboBox.currentIndex >= 0
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: Theme.controlHeight
                    text: displayPage.sortAscending ? qsTr("↑") : qsTr("↓")
                    font.pixelSize: 20
                    Accessible.name: displayPage.sortAscending ? qsTr("升序") : qsTr("降序")
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.name
                    onClicked: {
                        displayPage.sortAscending = !displayPage.sortAscending
                        displayPage.applyStockSort()
                    }
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: orderButton.hovered ? Theme.primarySoft : Theme.surface
                        border.color: Theme.border
                        border.width: 1
                    }
                }
            }

            Item{Layout.preferredWidth: 10}

            RowLayout{
                Layout.preferredWidth: 210
                Layout.fillHeight: true
                spacing:5

                Label {
                    id: catlabel
                    text: qsTr("分类：")
                    font.pixelSize: Theme.fontNormal
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledComboBox {
                    id: catcomboBox
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: Theme.controlHeight
                    Layout.alignment: Qt.AlignVCenter
                    model:TableDisplay.allCategories()
                    currentIndex: 0
                    displayText: currentIndex >= 0 ? currentText : qsTr("选择分类")
                    onActivated: displayPage.refreshStockFilter()
                }
            }

            Item{Layout.preferredWidth: 10}

            StyledTextField {
                id: textField
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
                placeholderText: qsTr("搜索（商品名）")
                onTextChanged: stockSearchDebounce.restart()
                onAccepted: stockSearchDebounce.restart()
            }

            Item{Layout.fillWidth: true}
        }

        Connections {
            target: TableDisplay
            function onDataChanged() {
                catcomboBox.model = TableDisplay.allCategories()
                displayPage.refreshStockFilter()
            }
        }

            // 库存表使用 stock 表原始十列，分类编号列由关系模型显示为中文分类名称。
        DataTable {
            id: tabview
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: TableDisplay.proxyModel
            dateColumns: [4, 5]
            moneyColumns: [3, 6]
            // 0=库存编号、1=分类名称、2=商品名称、3=进货单价、4/5=日期、6=销售单价、7=库存数量、8/9=库存上下限。
            hiddenColumns: BackendContract.canViewPrivateStockColumns(loginManager.per) ? [0] : [0, 3, 8, 9]
            warningQuantityColumn: 7
            upperLimitColumn: 8
            lowerLimitColumn: 9
            expiryDateColumns: [4, 5]
            showStatusColors: BackendContract.canViewPrivateStockColumns(loginManager.per)
            columnCount: 10
        }
    }
}
