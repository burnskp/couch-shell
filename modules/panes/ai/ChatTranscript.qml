pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Ui.ShellSurface {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool active: true
    property bool transcriptRegistered: false

    style: root.shellStyle
    tone: "subtle"
    padding: Theme.Theme.modulePadding

    Flickable {
        id: transcriptFlickable

        parent: root.contentItem
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: transcriptColumn.implicitHeight
        onContentYChanged: root.paneState.recordTranscriptScroll(height, contentHeight, contentY)
        onHeightChanged: root.paneState.restoreTranscriptScroll(transcriptFlickable)
        onContentHeightChanged: root.paneState.restoreTranscriptScroll(transcriptFlickable)
    }

    ColumnLayout {
        id: transcriptColumn

        parent: transcriptFlickable.contentItem
        width: transcriptFlickable.width
        spacing: Theme.Theme.listGap + 6

        Ui.ShellEmptyState {
            Layout.fillWidth: true
            visible: !root.paneState.activeSession || root.paneState.activeSession.messages.length === 0
            style: root.shellStyle
            title: "No messages yet"
            body: "Ask Codex below to start a new chat."
        }

        Repeater {
            model: root.paneState.activeSession ? root.paneState.activeSession.messages : []

            delegate: AiMessageBubble {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: transcriptColumn.width
                shellStyle: root.shellStyle
                message: modelData
                showReasoning: root.paneState.showReasoning
            }
        }
    }

    function updateTranscriptRegistration() {
        if (root.active && !root.transcriptRegistered) {
            root.transcriptRegistered = true;
            root.paneState.transcriptSurfaceActivated();
            return;
        }

        if (!root.active && root.transcriptRegistered) {
            root.transcriptRegistered = false;
            root.paneState.transcriptSurfaceDeactivated();
        }
    }

    function releaseTranscriptRegistration() {
        if (!root.transcriptRegistered)
            return;

        root.transcriptRegistered = false;
        root.paneState.transcriptSurfaceDeactivated();
    }

    onActiveChanged: root.updateTranscriptRegistration()

    Connections {
        target: root.paneState

        function onTranscriptRestoreRequestChanged() {
            if (root.active)
                root.paneState.restoreTranscriptScroll(transcriptFlickable);
        }
    }

    Component.onCompleted: root.updateTranscriptRegistration()
    Component.onDestruction: root.releaseTranscriptRegistration()
}
