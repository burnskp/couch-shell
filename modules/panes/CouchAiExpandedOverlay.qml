pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../animations" as Animations
import "../../theme" as Theme
import "../../ui" as Ui
import "./ai" as Ai

FocusScope {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool leftPaneOpen: true
    property bool rightPaneOpen: false
    readonly property bool compactMode: width < 1000

    signal closeRequested()

    function forceInputFocus() {
        overlayInput.focusEditor();
    }

    function focusSessionSearch() {
        sessionsList.focusSearch();
    }

    function closeTransientUi() {
        root.paneState.closePopovers();
    }

    function toggleLeftPane() {
        if (root.leftPaneOpen) {
            root.leftPaneOpen = false;
            return;
        }

        root.leftPaneOpen = true;
        if (root.compactMode)
            root.rightPaneOpen = false;
    }

    function toggleRightPane() {
        if (root.rightPaneOpen) {
            root.rightPaneOpen = false;
            return;
        }

        root.rightPaneOpen = true;
        if (root.compactMode)
            root.leftPaneOpen = false;
    }

    onCompactModeChanged: {
        if (root.compactMode && root.leftPaneOpen && root.rightPaneOpen)
            root.rightPaneOpen = false;
    }

    Keys.onEscapePressed: function(event) {
        if (root.paneState.settingsPopoverOpen) {
            root.closeTransientUi();
            event.accepted = true;
            return;
        }

        root.closeRequested();
        event.accepted = true;
    }

    Keys.onPressed: function(event) {
        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_N) {
            root.paneState.createNewChat();
            event.accepted = true;
            return;
        }

        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_K) {
            if (!root.leftPaneOpen)
                root.toggleLeftPane();

            root.focusSessionSearch();
            event.accepted = true;
            return;
        }

        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_BracketLeft) {
            root.toggleLeftPane();
            event.accepted = true;
            return;
        }

        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_BracketRight) {
            root.toggleRightPane();
            event.accepted = true;
            return;
        }

        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_Return) {
            root.paneState.sendMessage();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.Theme.crust, 0.42)
    }

    Animations.AnimationSelector {
        id: overlayAnimation

        anchors.fill: parent
        open: root.visible
        openPreset: Animations.AnimationRegistry.slideIn
        closePreset: Animations.AnimationRegistry.smoke
        openDuration: Animations.AnimationPresets.slideInEnterDurationMs
        closeDuration: Animations.AnimationPresets.smokeDurationMs
        startX: -(overlayFrame.width * 0.08)

        Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeTransientUi()
            }

            Ui.ShellPaneFrame {
                id: overlayFrame

                width: Math.max(920, Math.round(root.width * 0.86))
                height: Math.max(620, Math.round(root.height * 0.88))
                anchors.centerIn: parent
                style: root.shellStyle
                showAccentRail: false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.Theme.modulePadding
                    spacing: Theme.Theme.listGap + 4

                    Ai.AiTopBar {
                        id: overlayTopBar

                        Layout.fillWidth: true
                        shellStyle: root.shellStyle
                        paneState: root.paneState
                        showExpandButton: false
                        showCollapseButton: true
                        showCloseButton: false
                        showDetailsButton: true
                        detailsChecked: root.rightPaneOpen
                        sessionsChecked: root.leftPaneOpen
                        onSessionsRequested: root.toggleLeftPane()
                        onDetailsRequested: root.toggleRightPane()
                        onCollapseRequested: root.closeRequested()
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            anchors.fill: parent
                            spacing: Theme.Theme.listGap + 4

                            Ui.ShellPaneFrame {
                                visible: root.leftPaneOpen
                                Layout.preferredWidth: 280
                                Layout.fillHeight: true
                                style: root.shellStyle
                                showAccentRail: false

                                Ai.SessionsList {
                                    id: sessionsList

                                    anchors.fill: parent
                                    anchors.margins: Theme.Theme.modulePadding
                                    shellStyle: root.shellStyle
                                    paneState: root.paneState
                                    active: root.visible && root.leftPaneOpen
                                }
                            }

                            Ui.ShellPaneFrame {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                style: root.shellStyle
                                showAccentRail: false

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.Theme.modulePadding
                                    spacing: Theme.Theme.listGap + 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.Theme.listGap

                                        Ui.ShellText {
                                            Layout.fillWidth: true
                                            text: root.paneState.activeSession ? root.paneState.activeSession.title : "Couch AI"
                                            role: "heading"
                                            style: root.shellStyle
                                            elide: Text.ElideRight
                                        }

                                        Ui.ShellText {
                                            text: root.paneState.activeSession ? root.paneState.activeSession.updatedLabel : ""
                                            role: "muted"
                                            style: root.shellStyle
                                        }

                                    }

                                    Ui.ShellDivider {
                                        style: root.shellStyle
                                    }

                                    Ai.ChatTranscript {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        shellStyle: root.shellStyle
                                        paneState: root.paneState
                                        active: root.visible
                                    }

                                    Ai.ChatInput {
                                        id: overlayInput

                                        Layout.fillWidth: true
                                        shellStyle: root.shellStyle
                                        paneState: root.paneState
                                        active: root.visible
                                    }
                                }
                            }

                            Ui.ShellPaneFrame {
                                visible: root.rightPaneOpen
                                Layout.preferredWidth: 300
                                Layout.fillHeight: true
                                style: root.shellStyle
                                showAccentRail: false

                                Ai.SessionDetailsPane {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.Theme.modulePadding
                                    anchors.rightMargin: Theme.Theme.modulePadding
                                    anchors.topMargin: Theme.Theme.listGap
                                    anchors.bottomMargin: Theme.Theme.modulePadding
                                    shellStyle: root.shellStyle
                                    paneState: root.paneState
                                }
                            }
                        }
                    }
                }
            }

            Ai.SettingsPopover {
                visible: root.paneState.settingsPopoverOpen
                width: 340
                height: Math.min(implicitHeight, overlayFrame.y + overlayFrame.height - y - Theme.Theme.modulePadding)
                x: overlayFrame.x + overlayFrame.width - width - Theme.Theme.modulePadding
                y: overlayFrame.y + overlayTopBar.height + Theme.Theme.modulePadding + 2
                shellStyle: root.shellStyle
                paneState: root.paneState
                z: 2
            }
        }
    }
}
