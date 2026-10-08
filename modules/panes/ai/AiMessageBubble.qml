pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../theme" as Theme
import "../../../ui" as Ui
import "AiMessageBubbleLogic.js" as MessageLogic

Item {
    id: root

    required property var message
    property var shellStyle: Ui.ShellStyle.segmented
    property bool showReasoning: false
    property bool messageCopied: false
    readonly property bool isUser: root.message.role === "user"
    readonly property bool isError: !!root.message.error
    readonly property bool isPending: !!root.message.pending
    readonly property string rawMessageContent: MessageLogic.rawContent(root.message)
    readonly property bool canCopyMessage: MessageLogic.canCopy(root.message)
    readonly property bool hasReasoning: !root.isUser && !!root.message.reasoning && root.message.reasoning.length > 0
    readonly property bool webSearchActive: ["active", "in_progress", "searching"].indexOf(root.message.webSearchStatus) !== -1
    readonly property string webSearchLabel: root.message.webSearchStatus === "searching" ? "Searching the web…" : "Starting web search…"
    readonly property color bubbleColor: root.isUser ? Theme.Theme.userBubbleBackground : Theme.Theme.assistantBubbleBackground
    readonly property color bubbleBorder: root.isError ? Theme.Theme.red : (root.isUser ? Theme.Theme.userBubbleBorder : Theme.Theme.assistantBubbleBorder)
    width: parent ? parent.width : implicitWidth
    implicitHeight: bubbleColumn.implicitHeight

    function messageCopyArguments() {
        return MessageLogic.copyArguments(root.message);
    }

    function copyMessage() {
        if (!root.canCopyMessage)
            return;

        messageCopyProcess.exec(root.messageCopyArguments());
    }

    function handleMessageCopyResult(succeeded) {
        if (!MessageLogic.shouldShowCopied(succeeded))
            return;

        root.messageCopied = true;
        messageCopiedResetTimer.restart();
    }

    ColumnLayout {
        id: bubbleColumn

        width: parent.width
        spacing: Theme.Theme.listGap

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.listGap + 2

            Rectangle {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                color: root.isUser ? Theme.Theme.userMarkerBackground : Theme.Theme.aiMarkerBackground
                radius: 0
            }

            Ui.ShellText {
                text: root.message.label
                role: "heading"
                style: root.shellStyle
            }

            Item {
                Layout.fillWidth: true
            }

            Ui.ShellText {
                role: "muted"
                text: root.message.timestamp
                style: root.shellStyle
            }

            Ui.ShellButton {
                objectName: "messageCopyButton"
                Layout.preferredWidth: Theme.Theme.controlHeight
                Layout.preferredHeight: Theme.Theme.controlHeight
                enabled: root.canCopyMessage
                style: root.shellStyle
                variant: root.messageCopied ? "accent" : "ghost"
                text: root.messageCopied ? "󰄬" : "󰆏"
                horizontalPadding: Theme.Theme.moduleValuePadding
                onClicked: root.copyMessage()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            color: root.bubbleColor
            radius: 0
            border.width: 1
            border.color: root.bubbleBorder
            implicitHeight: messageColumn.implicitHeight + (Theme.Theme.modulePadding * 2)

            ColumnLayout {
                id: messageColumn

                anchors.fill: parent
                anchors.margins: Theme.Theme.modulePadding
                spacing: Theme.Theme.listGap + 2

                Ui.ShellSurface {
                    id: webSearchSurface

                    Layout.fillWidth: true
                    visible: root.webSearchActive
                    style: root.shellStyle
                    tone: "subtle"
                    padding: Theme.Theme.moduleValuePadding + 3
                    implicitHeight: webSearchRow.implicitHeight + (padding * 2)

                    RowLayout {
                        id: webSearchRow

                        parent: webSearchSurface.contentItem
                        anchors.fill: parent
                        spacing: Theme.Theme.listGap

                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            color: Theme.Theme.blue
                            radius: 0
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            text: root.webSearchLabel
                            role: "accent"
                            style: root.shellStyle
                        }
                    }
                }

                Ui.ShellSurface {
                    id: reasoningSurface

                    Layout.fillWidth: true
                    visible: root.showReasoning && root.hasReasoning
                    style: root.shellStyle
                    tone: "subtle"
                    padding: Theme.Theme.moduleValuePadding + 3
                    implicitHeight: reasoningColumn.implicitHeight + (padding * 2)

                    ColumnLayout {
                        id: reasoningColumn

                        parent: reasoningSurface.contentItem
                        anchors.fill: parent
                        spacing: Theme.Theme.listGap

                        Ui.ShellText {
                            Layout.fillWidth: true
                            text: "Reasoning"
                            role: "label"
                            style: root.shellStyle
                        }

                        Ui.ShellMarkdownText {
                            Layout.fillWidth: true
                            Layout.preferredWidth: reasoningColumn.width
                            text: root.message.reasoning || ""
                            role: "muted"
                            style: root.shellStyle
                        }
                    }
                }

                Ui.ShellMarkdownText {
                    Layout.fillWidth: true
                    Layout.preferredWidth: messageColumn.width
                    text: root.message.content && root.message.content.length > 0 ? root.message.content : (root.isPending ? "Codex is thinking…" : "")
                    role: root.isError ? "danger" : "body"
                    style: root.shellStyle
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.Theme.listGap
                    visible: !!(root.message.files && root.message.files.length > 0)

                    Repeater {
                        model: root.message.files || []

                        delegate: Ui.ShellSurface {
                            id: messageFileChip

                            required property var modelData
                            height: fileRow.implicitHeight + (Theme.Theme.moduleValuePadding * 2)
                            padding: Theme.Theme.moduleValuePadding
                            style: root.shellStyle
                            tone: "normal"

                            RowLayout {
                                id: fileRow

                                parent: messageFileChip.contentItem
                                anchors.fill: parent
                                spacing: Theme.Theme.listGap

                                Ui.ShellText {
                                    text: messageFileChip.modelData.name
                                    role: "muted"
                                    style: root.shellStyle
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: messageCopyProcess

        stdout: StdioCollector {
            onStreamFinished: root.handleMessageCopyResult(this.text === "copied")
        }
    }

    Timer {
        id: messageCopiedResetTimer

        interval: 1400
        onTriggered: root.messageCopied = false
    }
}
