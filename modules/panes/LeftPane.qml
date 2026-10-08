pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../animations" as Animations
import "../../services" as Services
import "../../theme" as Theme
import "../../ui" as Ui
import "./ai" as Ai

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    readonly property bool isTargetScreen: Services.PaneManager.leftScreen === root.screen
    readonly property real paneWidth: Math.max(420, Math.round(width * 0.33))
    readonly property real paneHeight: Math.max(320, Math.round(height * 0.80))
    readonly property int shadowPadding: Theme.Theme.outerShadowEffectivePadding
    readonly property var shellStyle: Object.assign({}, Ui.ShellStyle.segmented, {
        fontSize: Theme.Theme.aiPaneFontSize,
        controlHeight: Math.max(Theme.Theme.controlHeight, Theme.Theme.aiPaneFontSize + Theme.Theme.barIconPadding)
    })
    property bool couchAiExpanded: false

    function syncPaneOpen() {
        paneAnimation.open = Services.PaneManager.leftOpen && root.isTargetScreen;

        if (!Services.PaneManager.leftOpen || !root.isTargetScreen)
            root.couchAiExpanded = false;
    }

    function focusCouchAiInput() {
        if (!root.visible)
            return;

        Qt.callLater(function () {
            if (root.couchAiExpanded)
                expandedOverlay.forceInputFocus();
            else
                couchAiPane.forceInputFocus();
        });
    }

    function openCouchAiExpanded() {
        root.couchAiExpanded = true;
        couchAiPane.closePopovers();
        root.focusCouchAiInput();
    }

    function closeCouchAiExpanded() {
        root.couchAiExpanded = false;
        couchAiPane.closePopovers();
        root.focusCouchAiInput();
    }

    Ai.AiState {
        id: aiState
    }

    color: Theme.Theme.transparent
    aboveWindows: true
    focusable: Services.PaneManager.leftOpen
    exclusionMode: ExclusionMode.Ignore
    visible: root.isTargetScreen && paneAnimation.shouldShow

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Animations.AnimationSelector {
        id: paneAnimation

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Theme.Theme.barHeight + Theme.Theme.sectionGap - root.shadowPadding
        width: root.paneWidth + root.shadowPadding
        height: root.paneHeight + (root.shadowPadding * 2)
        openPreset: Animations.AnimationRegistry.slideIn
        closePreset: Animations.AnimationRegistry.slideIn
        openDuration: Animations.AnimationPresets.slideInEnterDurationMs
        closeDuration: Animations.AnimationPresets.slideInEnterDurationMs
        startX: -(width + Theme.Theme.sectionGap)

        Ui.ShellPaneFrame {
            y: root.shadowPadding
            width: root.paneWidth
            height: root.paneHeight
            style: root.shellStyle
            showLeftBorder: false
            showAccentRail: false

            CouchAiPane {
                id: couchAiPane

                anchors.fill: parent
                anchors.margins: Theme.Theme.modulePadding
                shellStyle: root.shellStyle
                paneState: aiState
                active: Services.PaneManager.leftOpen && root.isTargetScreen && !root.couchAiExpanded
                visible: !root.couchAiExpanded
                onExpandRequested: root.openCouchAiExpanded()
                onCloseRequested: Services.PaneManager.closeLeft()
            }
        }
    }

    CouchAiExpandedOverlay {
        id: expandedOverlay

        anchors.fill: parent
        visible: root.couchAiExpanded
        shellStyle: root.shellStyle
        paneState: aiState
        onCloseRequested: root.closeCouchAiExpanded()
    }

    mask: Region {
        item: root.couchAiExpanded ? expandedOverlay : paneAnimation
    }

    Connections {
        target: Services.PaneManager

        function onLeftOpenChanged() {
            root.syncPaneOpen();
            root.focusCouchAiInput();
        }

        function onLeftScreenChanged() {
            root.syncPaneOpen();
            root.focusCouchAiInput();
        }

        function onLeftTabChanged() {
            root.focusCouchAiInput();
        }
    }

    Component.onCompleted: {
        syncPaneOpen();
        focusCouchAiInput();
    }
}
