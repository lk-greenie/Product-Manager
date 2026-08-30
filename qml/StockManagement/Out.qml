import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"

Window {
    id: window
    visible: true
    width: 340
    height: 330
    title: qsTr("出库")

    property string salePrice: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        LabeledComboBox {
            id: categoryField
            labelText: qsTr("分类名：")
            model: TableDisplay.catModel
            onSelectionChanged: {
                TableDisplay.updatecnameModel(text)
                productField.currentIndex = -1
                window.salePrice = ""
            }
        }

        LabeledComboBox {
            id: productField
            labelText: qsTr("商品名称：")
            model: TableDisplay.cnameModel
            onSelectionChanged: window.salePrice = TableDisplay.getPrice(categoryField.currentText, text)
        }

        LabeledField { id: quantityField; labelText: qsTr("数量："); placeholderText: qsTr("正整数") }

        RowLayout {
            Layout.fillWidth: true
            Label { Layout.preferredWidth: 50; text: qsTr("售价：") }
            Label {
                Layout.fillWidth: true
                text: window.salePrice === "" ? qsTr("请选择商品") : qsTr("￥%1").arg(window.salePrice)
                horizontalAlignment: Text.AlignRight
            }
        }

        StatusLabel { id: statusLabel; Layout.fillWidth: true }

        FormButtonRow {
            onAccepted: {
                if (categoryField.currentIndex < 0 || productField.currentIndex < 0
                        || !/^\d+$/.test(quantityField.text.trim()) || Number(quantityField.text) <= 0
                        || window.salePrice === "") {
                    statusLabel.text = qsTr("请选择分类和商品，并填写正整数数量")
                    return
                }
                if (TableDisplay.outCommodity(categoryField.currentText, productField.currentText,
                                               quantityField.text, window.salePrice)) {
                    window.close()
                    window.destroy()
                } else {
                    statusLabel.text = qsTr("出库失败：库存不足、数据无效或权限不足")
                }
            }
            onRejected: {
                window.close()
                window.destroy()
            }
        }
    }
}
