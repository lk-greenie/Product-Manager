pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

Page {
    id: root

    background: Rectangle { color: Theme.appBackground }

    property double currentConversationId: 0
    property var pendingAction: null
    property int thinkingDots: 0
    property bool errorVisible: false

    function newConversation() {
        const id = aiManager.createConversation(qsTr("新对话"))
        if (id > 0) {
            currentConversationId = id
            aiManager.loadConversation(id)
        }
    }

    // 打开页面时选中最近一次会话，而不是自动新建一个空对话。
    function selectLatestConversation() {
        const id = aiManager.latestConversationId()
        if (id <= 0) {
            currentConversationId = 0
            aiManager.clearMessages()
            return
        }
        currentConversationId = id
        aiManager.loadConversation(id)
    }

    // 取消所有选中（再次点击已选中的对话时调用）。
    function deselectCurrent() {
        currentConversationId = 0
        aiManager.clearMessages()
    }

    function requestDelete(conversationId) {
        confirmDialog.messageText = qsTr("确定要删除该对话吗？")
        confirmDialog.isError = false
        pendingAction = function() {
            if (aiManager.deleteConversation(conversationId)) {
                if (root.currentConversationId === conversationId) {
                    root.deselectCurrent()
                } else if (root.currentConversationId > 0) {
                    // 删除的是非当前对话：重新加载当前对话，恢复其消息
                    aiManager.loadConversation(root.currentConversationId)
                }
            }
        }
        confirmDialog.open()
    }

    function send() {
        if (messageField.text.trim() === "")
            return
        if (currentConversationId <= 0)
            newConversation()
        if (currentConversationId > 0) {
            aiManager.sendMessage(currentConversationId, messageField.text.trim())
            messageField.clear()
        }
    }

    Component.onCompleted: selectLatestConversation()

    Timer {
        id: thinkingTimer
        interval: 420
        repeat: true
        running: aiManager.busy
        onTriggered: root.thinkingDots = (root.thinkingDots + 1) % 4
    }

    Timer {
        id: errorTimer
        interval: 3200
        repeat: false
        onTriggered: root.errorVisible = false
    }

    Connections {
        target: aiManager
        function onErrorOccurred() { root.errorVisible = true; errorTimer.restart() }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            PageTitle {
                title: qsTr("AI 小助手")
                subtitle: loginManager.per === 3
                          ? qsTr("查询公开商品的分类、售价、库存数量和保质期")
                          : qsTr("查询库存、交易和经营数据")
            }

            ListView {
                id: messageView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: aiManager.messagesModel
                spacing: 8
                clip: true
                reuseItems: true
                cacheBuffer: 360
                onCountChanged: positionViewAtEnd()

                delegate: Rectangle {
                    required property string display
                    required property string role
                    width: messageView.width
                    height: bubble.implicitHeight + 16
                    color: role === "user" ? Theme.primarySoft : Theme.surface
                    radius: Theme.radiusMedium
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: bubble
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Label {
                            text: role === "user" ? qsTr("我：") : qsTr("AI：")
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                            color: role === "user" ? Theme.primaryDark : Theme.textSecondary
                        }

                        Text {
                            id: content
                            Layout.fillWidth: true
                            text: display
                            wrapMode: Text.Wrap
                            // AI 回答以 Markdown 渲染，普通文本也兼容；用户消息按纯文本显示
                            textFormat: role === "user" ? Text.PlainText : Text.MarkdownText
                            color: role === "user" ? Theme.primaryDark : Theme.textPrimary
                            font.pixelSize: Theme.fontNormal
                        }
                    }
                }
            }

            Label {
                visible: aiManager.busy
                text: qsTr("AI 正在%1%2").arg(aiManager.busyStatus).arg(".".repeat(root.thinkingDots))
                color: Theme.primaryDark
            }

            Label {
                id: aiErrorLabel
                visible: root.errorVisible && aiManager.lastError !== ""
                text: aiManager.lastError
                color: Theme.danger
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                TextArea {
                    id: messageField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    placeholderText: qsTr("请输入库存管理相关问题，Enter 发送，Shift+Enter 换行")
                    wrapMode: TextEdit.Wrap
                    background: Rectangle {
                        color: Theme.surface
                        border.color: messageField.activeFocus ? Theme.primary : Theme.border
                        border.width: messageField.activeFocus ? 2 : 1
                        radius: Theme.radiusSmall
                    }

                    // Enter 发送，Shift+Enter 换行
                    Keys.onReturnPressed: (event) => {
                        if (event.modifiers & Qt.ShiftModifier)
                            return // 交由默认行为插入换行符
                        event.accepted = true
                        root.send()
                    }
                }

                PrimaryButton {
                    text: qsTr("发送")
                    enabled: !aiManager.busy && messageField.text.trim() !== ""
                    onClicked: root.send()
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 248
            Layout.minimumWidth: 220
            Layout.maximumWidth: 280
            color: Theme.surface
            border.color: Theme.border
            radius: Theme.radiusMedium

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12

                PrimaryButton {
                    text: qsTr("新建对话")
                    Layout.fillWidth: true
                    onClicked: root.newConversation()
                }

                ListView {
                    id: conversationView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: aiManager.conversationsModel
                    clip: true
                    reuseItems: true
                    cacheBuffer: 240

                    delegate: Rectangle {
                        id: convDelegate
                        required property double conversationId
                        required property string display

                        width: conversationView.width
                        height: 38
                        radius: Theme.radiusSmall
                        color: conversationId === root.currentConversationId
                               ? Theme.primarySoft : "transparent"
                        border.color: conversationId === root.currentConversationId
                                      ? Theme.primary : "transparent"
                        border.width: conversationId === root.currentConversationId ? 1 : 0

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 44
                            hoverEnabled: true
                            onClicked: {
                                // 点击已选中的对话再次点击取消选择，否则选中并加载。
                                if (root.currentConversationId === convDelegate.conversationId)
                                    root.deselectCurrent()
                                else {
                                    root.currentConversationId = convDelegate.conversationId
                                    aiManager.loadConversation(root.currentConversationId)
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 4
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: convDelegate.display
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                color: convDelegate.conversationId === root.currentConversationId
                                       ? Theme.primaryDark : Theme.textPrimary
                            }

                            ToolButton {
                                text: qsTr("删除")
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 26
                                onClicked: root.requestDelete(convDelegate.conversationId)
                            }
                        }
                    }
                }
            }
        }
    }

    NoticeDialog {
        id: confirmDialog
        messageText: ""
        isError: false
        autoDismiss: false
        onOk: function() {
            if (root.pendingAction)
                root.pendingAction()
            root.pendingAction = null
            // 确认删除后自动关闭提示窗口
            confirmDialog.close()
        }
    }
}
