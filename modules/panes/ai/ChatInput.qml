pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui
import "../../../services" as Services

Ui.ShellSurface {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool active: true
    readonly property alias editor: inputArea.editor
    readonly property int iconButtonPadding: Theme.Theme.moduleValuePadding + 5
    readonly property int iconButtonWidth: Theme.Theme.controlHeight + 8

    style: root.shellStyle
    tone: "normal"
    padding: Theme.Theme.modulePadding
    implicitHeight: inputColumn.implicitHeight + (padding * 2)

    function focusEditor() {
        if (!root.active)
            return;

        Qt.callLater(function() {
            inputArea.editor.forceActiveFocus();
        });
    }

    function setWebSearchEnabled(enabled) {
        root.paneState.webSearchMode = enabled ? "live" : "disabled";
        root.paneState.requestInputFocus();
    }

    function setShowReasoning(enabled) {
        root.paneState.showReasoning = enabled;
        root.paneState.requestInputFocus();
    }

    ColumnLayout {
        id: inputColumn

        parent: root.contentItem
        anchors.fill: parent
        spacing: Theme.Theme.listGap + 2

        Ui.ShellTextArea {
            id: inputArea

            Layout.fillWidth: true
            style: root.shellStyle
            minimumHeight: 92
            placeholderText: "Ask Codex..."
            text: root.paneState.inputText
            enabled: !Services.AiChatService.chatBusy
            editor.onTextChanged: root.paneState.updateDraft(text)
            editor.Keys.onReturnPressed: function(event) {
                if (event.modifiers === Qt.ShiftModifier) {
                    inputArea.editor.insert(inputArea.editor.cursorPosition, "\n");
                    event.accepted = true;
                    return;
                }

                if (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ControlModifier) {
                    root.paneState.sendMessage();
                    event.accepted = true;
                }
            }
            editor.Keys.onEnterPressed: function(event) {
                if (event.modifiers === Qt.ShiftModifier) {
                    inputArea.editor.insert(inputArea.editor.cursorPosition, "\n");
                    event.accepted = true;
                    return;
                }

                if (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ControlModifier) {
                    root.paneState.sendMessage();
                    event.accepted = true;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.listGap

            Ui.ShellButton {
                Layout.preferredWidth: root.iconButtonWidth
                style: root.shellStyle
                variant: root.paneState.webSearchMode === "live" ? "accent" : "default"
                checked: root.paneState.webSearchMode === "live"
                text: "󰖟"
                horizontalPadding: root.iconButtonPadding
                onClicked: root.setWebSearchEnabled(root.paneState.webSearchMode !== "live")
            }

            Ui.ShellButton {
                Layout.preferredWidth: root.iconButtonWidth
                style: root.shellStyle
                variant: root.paneState.showReasoning ? "accent" : "default"
                checked: root.paneState.showReasoning
                text: "󰦪"
                horizontalPadding: root.iconButtonPadding
                onClicked: root.setShowReasoning(!root.paneState.showReasoning)
            }

            Item {
                Layout.fillWidth: true
            }

            Ui.ShellButton {
                Layout.preferredWidth: root.iconButtonWidth
                style: root.shellStyle
                variant: "accent"
                text: Services.AiChatService.chatBusy ? "…" : "󰒊"
                enabled: !Services.AiChatService.chatBusy && !Services.AiChatService.authenticatedWorkBlocked && Services.AiChatService.configured && root.paneState.activeEngine
                horizontalPadding: root.iconButtonPadding
                onClicked: root.paneState.sendMessage()
            }
        }
    }

    Connections {
        target: root.paneState

        function onInputFocusRequestChanged() {
            root.focusEditor();
        }
    }
}
