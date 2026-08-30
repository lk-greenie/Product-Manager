import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"

Window {
    id: window
    visible: true
    width: 360
    height: 400
    title: qsTr("更改警告阈值")

    property var info: ({})

    function loadInfo() {
        if (categoryField.currentIndex < 0 || productField.currentIndex < 0)
            return
        info = TableDisplay.productInfo(categoryField.currentText, productField.currentText)
        upperField.text = info.upperLimit === undefined ? "" : info.upperLimit
        lowerField.text = info.lowerLimit === undefined ? "" : info.lowerLimit
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

        LabeledField { id: upperField; labelText: qsTr("上限值："); placeholderText: qsTr("非负整数") }
        LabeledField { id: lowerField; labelText: qsTr("下限值："); placeholderText: qsTr("非负整数") }

        RowLayout {
            Layout.fillWidth: true
            Label { Layout.preferredWidth: 50; text: qsTr("现有数量：") }
            Label {
                Layout.fillWidth: true
                text: window.info.quantity === undefined ? qsTr("请选择商品") : window.info.quantity
                horizontalAlignment: Text.AlignRight
            }
        }

        StatusLabel { id: statusLabel; Layout.fillWidth: true }

        FormButtonRow {
            onAccepted: {
                if (categoryField.currentIndex < 0 || productField.currentIndex < 0
                        || !/^\d+$/.test(upperField.text.trim()) || !/^\d+$/.test(lowerField.text.trim())
                        || Number(upperField.text) < Number(lowerField.text)) {
                    statusLabel.text = qsTr("上下限必须为非负整数，且上限不得小于下限")
                    return
                }
                if (TableDisplay.setLimits(categoryField.currentText, productField.currentText,
                                           upperField.text, lowerField.text)) {
                    window.close()
                    window.destroy()
                } else {
                    statusLabel.text = qsTr("警告阈值更新失败")
                }
            }
            onRejected: {
                window.close()
                window.destroy()
            }
        }
    }
}
