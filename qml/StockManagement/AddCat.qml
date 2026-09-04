import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts
import "Components"
import "../Components"

Window {
    id: window
    visible: true
    width: 420
    height: 250
    minimumWidth: 380
    minimumHeight: 230
    color: Theme.appBackground
    title: qsTr("添加分类")

    Shortcut {
        sequence: "Return"
        onActivated: confirm()
    }

    function confirm() {
        const message = TableDisplay.addCat(categoryField.text)
        if (message === "") {
            notice.messageText = qsTr("操作成功")
            notice.isError = false
            notice.onOk = function(){ window.close(); window.destroy(); }
            notice.open()
        } else {
            notice.messageText = message
            notice.isError = true
            notice.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

         PageTitle { title: qsTr("添加分类"); subtitle: qsTr("新增库存分类名称"); centered: true }

        LabeledField { id: categoryField; labelText: qsTr("分类名：") }
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
