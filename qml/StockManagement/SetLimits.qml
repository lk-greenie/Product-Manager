import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"
import "../Components"

Window {
    id: window
    visible: true
    width: 460
    height: 450
    minimumWidth: 420
    minimumHeight: 410
    color: Theme.appBackground
    title: qsTr("更改警告阈值")

    // 现有数量用简单 string 属性承载，避免 property var 绑定不刷新
    property string quantityText: qsTr("请选择商品")

    function loadInfo(product) {
        if (categoryField.currentIndex < 0 || !product) {
            upperField.text = ""
            lowerField.text = ""
            window.quantityText = qsTr("请选择商品")
            return
        }
        const info = TableDisplay.productInfo(categoryField.currentText, product)
        upperField.text = info.upperLimit === undefined ? "0" : String(info.upperLimit)
        lowerField.text = info.lowerLimit === undefined ? "0" : String(info.lowerLimit)
        window.quantityText = info.quantity === undefined ? qsTr("请选择商品") : String(info.quantity)
    }

    Shortcut {
        sequence: "Return"
        onActivated: confirm()
    }

    function confirm() {
        if (categoryField.currentIndex < 0 || productField.currentIndex < 0
                || !/^\d+$/.test(upperField.text.trim()) || !/^\d+$/.test(lowerField.text.trim())
                || Number(upperField.text) < Number(lowerField.text)) {
            statusLabel.text = qsTr("上下限必须为非负整数，且上限不得小于下限")
            return
        }
        if (TableDisplay.setLimits(categoryField.currentText, productField.currentText,
                                   upperField.text, lowerField.text)) {
            notice.messageText = qsTr("操作成功")
            notice.isError = false
            notice.onOk = function(){ window.close(); window.destroy(); }
            notice.open()
        } else {
            notice.messageText = qsTr("警告阈值更新失败")
            notice.isError = true
            notice.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

         PageTitle { title: qsTr("设置库存预警"); subtitle: qsTr("为商品设置库存上下限"); centered: true }

        LabeledComboBox {
            id: categoryField
            labelText: qsTr("分类名：")
            model: TableDisplay.catModel
            onSelectionChanged: function(text) {
                TableDisplay.updatecnameModel(text)
                productField.currentIndex = -1
                upperField.text = ""
                lowerField.text = ""
                window.quantityText = qsTr("请选择商品")
            }
        }

        LabeledComboBox {
            id: productField
            labelText: qsTr("商品名称：")
            model: TableDisplay.cnameModel
            onSelectionChanged: function(text) { window.loadInfo(text) }
        }

        LabeledField { id: upperField; labelText: qsTr("上限值："); placeholderText: qsTr("非负整数") }
        LabeledField { id: lowerField; labelText: qsTr("下限值："); placeholderText: qsTr("非负整数") }

        LabeledValue { labelText: qsTr("现有数量："); valueText: window.quantityText }

        StatusLabel { id: statusLabel; Layout.fillWidth: true }

        FormButtonRow {
            onAccepted: window.confirm()
            onRejected: {
                window.close()
                window.destroy()
            }
        }
    }

    NoticeDialog {
        id: notice
    }
}
