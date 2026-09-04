pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15

// 统一的桌面端下拉框：固定控件高度、保留文字空间，并提供一致的弹出菜单样式。
ComboBox {
    id: control

    implicitWidth: 160
    implicitHeight: Theme.controlHeight
    leftPadding: 12
    rightPadding: 36
    font.pixelSize: Theme.fontSmall

    contentItem: Text {
        // ComboBox 已经通过 leftPadding/rightPadding 预留空间，内容文字不再重复加内边距，
        // 否则短下拉框会把“店员”“顾客访客”“按月”等选中项裁成省略号。
        leftPadding: 0
        rightPadding: 0
        // 某些模型（例如带 textRole/valueRole 的对象模型）在 currentText
        // 尚未同步时会暂时返回空字符串，回退到 displayText 可避免选中项空白。
        text: control.currentIndex >= 0 && control.currentText !== ""
              ? control.currentText : control.displayText
        color: control.enabled ? Theme.textPrimary : Theme.textMuted
        font: control.font
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    indicator: Text {
        x: control.width - width - 12
        anchors.verticalCenter: parent.verticalCenter
        text: control.popup.visible ? qsTr("▴") : qsTr("▾")
        color: control.enabled ? Theme.textSecondary : Theme.textMuted
        font.pixelSize: Theme.fontSmall
    }

    background: Rectangle {
        radius: Theme.radiusSmall
        color: control.pressed ? Theme.primarySoft
               : control.hovered ? Theme.surfaceMuted : Theme.surface
        border.color: control.activeFocus ? Theme.primary : Theme.border
        border.width: control.activeFocus ? 2 : 1
    }

    delegate: ItemDelegate {
        id: optionDelegate
        required property int index
        width: control.popup.width
        height: Theme.compactControlHeight
        text: control.textAt(index)
        highlighted: control.highlightedIndex === index

        contentItem: Text {
            leftPadding: 10
            rightPadding: 10
            text: optionDelegate.text
            color: optionDelegate.highlighted ? Theme.primaryDark : Theme.textPrimary
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: optionDelegate.highlighted ? Theme.primarySoft : "transparent"
        }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        padding: 4
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 220)

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.borderStrong
            border.width: 1
            radius: Theme.radiusSmall
        }
    }
}
