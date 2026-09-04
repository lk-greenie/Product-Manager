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
    title: qsTr("出库")

    property string salePrice: ""

    Shortcut {
        sequence: "Return"
        onActivated: confirm()
    }

    function confirm() {
        if (categoryField.currentIndex < 0 || productField.currentIndex < 0
                || !/^\d+$/.test(quantityField.text.trim()) || Number(quantityField.text) <= 0
                || window.salePrice === "") {
            statusLabel.text = qsTr("请选择分类和商品，并填写正整数数量")
            return
        }
        if (TableDisplay.outCommodity(categoryField.currentText, productField.currentText,
                                       quantityField.text, window.salePrice)) {
            notice.messageText = qsTr("操作成功")
            notice.isError = false
            notice.onOk = function(){ window.close(); window.destroy(); }
            notice.open()
        } else {
            notice.messageText = qsTr("出库失败：库存不足、数据无效或权限不足")
            notice.isError = true
            notice.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

         PageTitle { title: qsTr("出库"); subtitle: qsTr("登记销售数量并更新库存"); centered: true }

        LabeledComboBox {
            id: categoryField
            labelText: qsTr("分类名：")
            model: TableDisplay.catModel
            onSelectionChanged: function(text) {
                TableDisplay.updatecnameModel(text)
                productField.currentIndex = -1
                window.salePrice = ""
            }
        }

        LabeledComboBox {
            id: productField
            labelText: qsTr("商品名称：")
            model: TableDisplay.cnameModel
            onSelectionChanged: function(text) {
                window.salePrice = TableDisplay.getPrice(categoryField.currentText, text)
            }
        }

        LabeledField { id: quantityField; labelText: qsTr("数量："); placeholderText: qsTr("正整数") }

        LabeledValue {
            labelText: qsTr("售价：")
            valueText: window.salePrice === "" ? qsTr("请选择商品") : qsTr("￥%1").arg(window.salePrice)
        }

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
