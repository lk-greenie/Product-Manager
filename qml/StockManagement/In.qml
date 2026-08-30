import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"

Window {
    id: window
    visible: true
    width: 360
    height: 420
    title: qsTr("入库")

    function validDate(value) {
        return /^\d{4}-\d{2}-\d{2}$/.test(value)
                && !isNaN(new Date(value + "T00:00:00").getTime())
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        LabeledComboBox {
            id: categoryField
            labelText: qsTr("分类名：")
            model: TableDisplay.catModel
        }

        LabeledField { id: nameField; labelText: qsTr("商品名称：") }
        LabeledField { id: quantityField; labelText: qsTr("数量："); placeholderText: qsTr("正整数") }
        LabeledField { id: priceField; labelText: qsTr("进价："); placeholderText: qsTr("￥ 正数") }
        LabeledField { id: manufactureField; labelText: qsTr("生产日期："); placeholderText: qsTr("yyyy-MM-dd") }
        LabeledField { id: expiryField; labelText: qsTr("保质日期："); placeholderText: qsTr("yyyy-MM-dd") }

        StatusLabel { id: statusLabel; Layout.fillWidth: true }

        FormButtonRow {
            onAccepted: {
                if (categoryField.currentIndex < 0 || nameField.text.trim() === ""
                        || !/^\d+$/.test(quantityField.text.trim())
                        || Number(quantityField.text) <= 0
                        || isNaN(Number(priceField.text)) || Number(priceField.text) <= 0
                        || !window.validDate(manufactureField.text.trim())
                        || !window.validDate(expiryField.text.trim())
                        || manufactureField.text > expiryField.text) {
                    statusLabel.text = qsTr("请完整填写有效信息：数量和进价必须为正数，日期为 yyyy-MM-dd")
                    return
                }
                if (TableDisplay.inCommodity(categoryField.currentText, nameField.text,
                                              quantityField.text, priceField.text,
                                              manufactureField.text, expiryField.text)) {
                    window.close()
                    window.destroy()
                } else {
                    statusLabel.text = qsTr("入库失败，请检查数据或权限")
                }
            }
            onRejected: {
                window.close()
                window.destroy()
            }
        }
    }
}
