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
    height: 420
    minimumWidth: 420
    minimumHeight: 390
    color: Theme.appBackground
    title: qsTr("更改售价")

    // 用简单 string 属性承载进价显示，避免 property var 绑定不刷新的问题
    property string purchaseText: qsTr("请选择商品")

    function loadInfo(product) {
        if (categoryField.currentIndex < 0 || !product) {
            window.purchaseText = qsTr("请选择商品")
            salePriceField.text = ""
            return
        }
        const info = TableDisplay.productInfo(categoryField.currentText, product)
        const p = Number(info.purchasePrice)
        window.purchaseText = (info.purchasePrice !== undefined && p > 0)
                ? qsTr("￥%1").arg(p.toFixed(2)) : qsTr("请选择商品")
        salePriceField.text = info.salePrice === undefined ? "" : String(info.salePrice)
    }

    Shortcut {
        sequence: "Return"
        onActivated: confirm()
    }

    function confirm() {
        if (categoryField.currentIndex < 0 || productField.currentIndex < 0
                || isNaN(Number(salePriceField.text)) || Number(salePriceField.text) <= 0) {
            statusLabel.text = qsTr("请选择商品并填写正售价")
            return
        }
        if (TableDisplay.setPrice(categoryField.currentText, productField.currentText, salePriceField.text)) {
            notice.messageText = qsTr("操作成功")
            notice.isError = false
            notice.onOk = function(){ window.close(); window.destroy(); }
            notice.open()
        } else {
            notice.messageText = qsTr("售价更新失败")
            notice.isError = true
            notice.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

         PageTitle { title: qsTr("设置售价"); subtitle: qsTr("调整当前商品的销售价格"); centered: true }

        LabeledComboBox {
            id: categoryField
            labelText: qsTr("分类名：")
            model: TableDisplay.catModel
            onSelectionChanged: function(text) {
                TableDisplay.updatecnameModel(text)
                productField.currentIndex = -1
                window.purchaseText = qsTr("请选择商品")
                salePriceField.text = ""
            }
        }

        LabeledComboBox {
            id: productField
            labelText: qsTr("商品名称：")
            model: TableDisplay.cnameModel
            onSelectionChanged: function(text) { window.loadInfo(text) }
        }

        LabeledValue { labelText: qsTr("进价："); valueText: window.purchaseText }

        LabeledField { id: salePriceField; labelText: qsTr("售价："); placeholderText: qsTr("￥ 正数") }
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
