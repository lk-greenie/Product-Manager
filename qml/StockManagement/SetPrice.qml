import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"

Window {
    id: window
    visible: true
    width: 340
    height: 350
    title: qsTr("更改售价")

    property var info: ({})

    function loadInfo() {
        if (categoryField.currentIndex < 0 || productField.currentIndex < 0)
            return
        info = TableDisplay.productInfo(categoryField.currentText, productField.currentText)
        salePriceField.text = info.salePrice === undefined ? "" : info.salePrice
    }

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
                window.info = ({})
            }
        }

        LabeledComboBox {
            id: productField
            labelText: qsTr("商品名称：")
            model: TableDisplay.cnameModel
            onSelectionChanged: window.loadInfo()
        }

        RowLayout {
            Layout.fillWidth: true
            Label { Layout.preferredWidth: 50; text: qsTr("进价：") }
            Label {
                Layout.fillWidth: true
                text: window.info.purchasePrice === undefined ? qsTr("请选择商品") : qsTr("￥%1").arg(Number(window.info.purchasePrice).toFixed(2))
                horizontalAlignment: Text.AlignRight
            }
        }

        LabeledField { id: salePriceField; labelText: qsTr("售价："); placeholderText: qsTr("￥ 正数") }
        StatusLabel { id: statusLabel; Layout.fillWidth: true }

        FormButtonRow {
            onAccepted: {
                if (categoryField.currentIndex < 0 || productField.currentIndex < 0
                        || isNaN(Number(salePriceField.text)) || Number(salePriceField.text) <= 0) {
                    statusLabel.text = qsTr("请选择商品并填写正售价")
                    return
                }
                if (TableDisplay.setPrice(categoryField.currentText, productField.currentText, salePriceField.text)) {
                    window.close()
                    window.destroy()
                } else {
                    statusLabel.text = qsTr("售价更新失败")
                }
            }
            onRejected: {
                window.close()
                window.destroy()
            }
        }
    }
}
