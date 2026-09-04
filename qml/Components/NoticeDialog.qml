pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

// 统一的操作结果提示弹窗。
// 对外属性：
//   messageText : string —— 提示正文
//   okText      : string —— “确定”按钮文字，默认“确定”
//   isError     : bool   —— true 时正文为错误红，默认 false
//   onOk        : var    —— 点击“确定”后执行的回调；若提供，可用来在成功后关闭父窗口
// 使用：msgDialog.messageText = "操作成功"; msgDialog.open()
Dialog {
    id: dialog

    property string messageText: ""
    property string okText: qsTr("确定")
    property bool isError: false
    property var onOk: null
    property bool autoDismiss: true
    property int dismissInterval: 2200

    modal: true
    focus: true
    title: qsTr("提示")
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onOpened: okButton.forceActiveFocus()

    Timer {
        id: dismissTimer
        interval: dialog.dismissInterval
        repeat: false
        running: dialog.visible && dialog.autoDismiss
        onTriggered: {
            if (typeof dialog.onOk === "function")
                dialog.onOk()
            dialog.close()
        }
    }

    contentItem: ColumnLayout {
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: dialog.messageText
            wrapMode: Text.Wrap
            color: dialog.isError ? "#b91c1c" : "#111827"
            font.pixelSize: Theme.fontNormal
        }

        PrimaryButton {
            id: okButton
            text: dialog.okText
            focus: true
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                if (typeof dialog.onOk === "function")
                    dialog.onOk()
                dialog.close()
            }
        }
    }
}
