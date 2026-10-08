pragma ComponentBehavior: Bound

import QtQuick
import "../../theme" as Theme
import "../../ui" as Ui
import "./ai" as Ai

Item {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool active: true
    implicitHeight: 560

    signal expandRequested()
    signal closeRequested()

    Keys.onEscapePressed: function(event) {
        if (root.paneState.sessionsPopoverOpen || root.paneState.settingsPopoverOpen) {
            root.paneState.closePopovers();
            event.accepted = true;
        }
    }

    Keys.onPressed: function(event) {
        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_N) {
            root.paneState.createNewChat();
            event.accepted = true;
            return;
        }

        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_K) {
            root.paneState.toggleSessionsPopover();
            if (root.paneState.sessionsPopoverOpen)
                sessionsPopoverContent.focusSearch();
            event.accepted = true;
            return;
        }

        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_Return) {
            root.paneState.sendMessage();
            event.accepted = true;
        }
    }

    function closePopovers() {
        root.paneState.closePopovers();
    }

    function forceInputFocus() {
        chatInput.focusEditor();
    }

    Ai.AiTopBar {
        id: topBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        shellStyle: root.shellStyle
        paneState: root.paneState
        showExpandButton: true
        showCloseButton: true
        onSessionsRequested: {
            root.paneState.toggleSessionsPopover();
            if (root.paneState.sessionsPopoverOpen)
                sessionsPopoverContent.focusSearch();
        }
        onExpandRequested: root.expandRequested()
        onCloseRequested: root.closeRequested()
    }

    Ai.ChatTranscript {
        id: transcript

        anchors.top: topBar.bottom
        anchors.topMargin: Theme.Theme.listGap + 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: chatInput.top
        anchors.bottomMargin: Theme.Theme.listGap + 4
        shellStyle: root.shellStyle
        paneState: root.paneState
        active: root.active && root.visible
    }

    Ai.ChatInput {
        id: chatInput

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        shellStyle: root.shellStyle
        paneState: root.paneState
        active: root.active && root.visible
    }

    Item {
        anchors.fill: parent
        z: 10
        visible: root.paneState.sessionsPopoverOpen || root.paneState.settingsPopoverOpen

        MouseArea {
            anchors.fill: parent
            onClicked: root.paneState.closePopovers()
        }

        Ui.ShellSurface {
            id: sessionsPopoverSurface

            visible: root.paneState.sessionsPopoverOpen
            width: Math.min(root.width - 16, 380)
            x: Math.max(Theme.Theme.listGap, root.width - width - Theme.Theme.listGap)
            y: topBar.y + topBar.height + Theme.Theme.listGap
            style: root.shellStyle
            tone: "normal"
            padding: Theme.Theme.modulePadding
            height: Math.min(root.height * 0.72, sessionsPopoverContent.implicitHeight + (padding * 2))

            Ai.SessionsList {
                id: sessionsPopoverContent

                parent: sessionsPopoverSurface.contentItem
                anchors.fill: parent
                shellStyle: root.shellStyle
                paneState: root.paneState
                active: root.active && root.visible
                groups: ["Pinned", "Today", "Yesterday"]
            }
        }

        Ai.SettingsPopover {
            visible: root.paneState.settingsPopoverOpen
            width: Math.min(root.width - 16, 340)
            height: Math.min(implicitHeight, root.height - y - Theme.Theme.listGap)
            x: Math.max(Theme.Theme.listGap, root.width - width - 72)
            y: topBar.y + topBar.height + Theme.Theme.listGap
            shellStyle: root.shellStyle
            paneState: root.paneState
        }
    }
}
