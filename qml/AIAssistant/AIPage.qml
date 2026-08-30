pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

Page {
    id: root

    property double currentConversationId: 0

    function newConversation() {
        const id = aiManager.createConversation(qsTr("新对话"))
        if (id > 0) {
            currentConversationId = id
            aiManager.loadConversation(id)
        }
    }

    function send() {
        if (messageField.text.trim() === "")
            return
        if (currentConversationId <= 0)
            newConversation()
        if (currentConversationId > 0) {
            aiManager.sendMessage(currentConversationId, messageField.text)
            messageField.clear()
        }
    }

    Component.onCompleted: newConversation()

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            ListView {
                id: messageView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: aiManager.messagesModel
                spacing: 8
                clip: true
                onCountChanged: positionViewAtEnd()

                delegate: Rectangle {
                    required property string display
                    required property string role
                    width: messageView.width
                    height: content.implicitHeight + 16
                    color: role === "user" ? "#dbeafe" : "#f3f4f6"
                    radius: 8

                    Text {
                        id: content
                        anchors.fill: parent
                        anchors.margins: 8
                        text: parent.role === "user" ? qsTr("我：%1").arg(parent.display) : qsTr("AI：%1").arg(parent.display)
                        wrapMode: Text.Wrap
                    }
                }
            }

            Label {
                visible: aiManager.busy
                text: qsTr("AI 正在思考…")
            }

            Label {
                visible: aiManager.lastError !== ""
                text: aiManager.lastError
                color: "#b91c1c"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                TextArea {
                    id: messageField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    placeholderText: qsTr("请输入库存管理相关问题")
                    wrapMode: TextEdit.Wrap
                }

                Button {
                    text: qsTr("发送")
                    enabled: !aiManager.busy && messageField.text.trim() !== ""
                    onClicked: root.send()
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: "#f8fafc"
            border.color: "#d1d5db"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10

                Button {
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

                    delegate: ItemDelegate {
                        required property double conversationId
                        required property var model

                        width: conversationView.width
                        text: model.display
                        highlighted: conversationId === root.currentConversationId
                        onClicked: {
                            root.currentConversationId = conversationId
                            aiManager.loadConversation(root.currentConversationId)
                        }
                    }
                }
            }
        }
    }
}
