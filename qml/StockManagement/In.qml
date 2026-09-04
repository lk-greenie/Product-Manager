import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"
import "../Components"

Window {
    id: window
    visible: true
    width: 480
    height: 520
    minimumWidth: 440
    minimumHeight: 480
    color: Theme.appBackground
    title: qsTr("入库")

    function validDate(value) {
        return /^\d{4}-\d{2}-\d{2}$/.test(value)
                && !isNaN(new Date(value + "T00:00:00").getTime())
    }

    Shortcut {
        sequence: "Return"
        onActivated: confirm()
    }

    function confirm() {
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
            notice.messageText = qsTr("操作成功")
            notice.isError = false
            notice.onOk = function(){ window.close(); window.destroy(); }
            notice.open()
        } else {
            notice.messageText = qsTr("入库失败，请检查数据或权限")
            notice.isError = true
            notice.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

         PageTitle { title: qsTr("入库"); subtitle: qsTr("登记商品批次、成本和保质期"); centered: true }

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
