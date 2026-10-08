pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../animations" as Animations
import "../../services" as Services
import "../../theme" as Theme
import "../../ui" as Ui
import "./todos" as Todos

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    readonly property bool isTargetScreen: Services.PaneManager.rightScreen === root.screen
    readonly property real paneWidth: Math.max(336, Math.round(width * 0.33))
    readonly property real paneHeight: Math.max(240, Math.round(height * 0.80))
    readonly property int shadowPadding: Theme.Theme.outerShadowEffectivePadding
    readonly property var shellStyle: Object.assign({}, Ui.ShellStyle.segmented, {
        fontSize: Theme.Theme.tasksPaneFontSize,
        controlHeight: Math.max(Theme.Theme.controlHeight, Theme.Theme.tasksPaneFontSize + Theme.Theme.barIconPadding)
    })
    property bool paneWindowVisible: false
    property string expandedRightPane: ""

    function newTaskOverlayActive() {
        return todosNewTaskOverlay.open || todosNewTaskOverlay.shouldShow;
    }

    function syncWindowState() {
        const overlayActive = root.newTaskOverlayActive();
        root.paneWindowVisible = root.isTargetScreen && paneAnimation.shouldShow;
        root.visible = root.paneWindowVisible || overlayActive;
        root.focusable = Services.PaneManager.rightOpen || overlayActive;
    }

    function syncPaneOpen() {
        paneAnimation.open = Services.PaneManager.rightOpen && root.isTargetScreen;

        if (!Services.PaneManager.rightOpen || !root.isTargetScreen)
            root.expandedRightPane = "";

        if (todosNewTaskOverlay.open)
            paneAnimation.open = false;

        root.syncWindowState();
    }

    function openExpanded() {
        root.expandedRightPane = Services.PaneManager.rightTab;
    }

    function closeExpanded() {
        root.expandedRightPane = "";
    }

    function focusActivePane() {
        if (!root.visible || todosNewTaskOverlay.open)
            return;

        Qt.callLater(function () {
            todosPane.forceActiveFocus();
        });
    }

    function syncNewTaskOverlayOpen() {
        todosNewTaskOverlay.open = Services.PaneManager.newTaskOpen && Services.PaneManager.newTaskScreen === root.screen;
    }

    function focusNewTaskOverlay() {
        if (!todosNewTaskOverlay.open)
            return;

        Qt.callLater(function () {
            todosState.addPopupOpen = false;
            todosNewTaskOverlay.forceActiveFocus();
            todosNewTaskOverlay.focusProject();
        });
    }

    Todos.TodosState {
        id: todosState
    }

    color: Theme.Theme.transparent
    aboveWindows: true
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    visible: false

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Animations.AnimationSelector {
        id: paneAnimation

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.Theme.barHeight + Theme.Theme.sectionGap - root.shadowPadding
        visible: !root.newTaskOverlayActive()
        width: root.paneWidth + root.shadowPadding
        height: root.paneHeight + (root.shadowPadding * 2)
        openPreset: Animations.AnimationRegistry.slideIn
        closePreset: Animations.AnimationRegistry.slideIn
        openDuration: Animations.AnimationPresets.slideInEnterDurationMs
        closeDuration: Animations.AnimationPresets.slideInEnterDurationMs
        startX: width + Theme.Theme.sectionGap
        onShouldShowChanged: root.syncWindowState()

        Ui.ShellPaneFrame {
            x: root.shadowPadding
            y: root.shadowPadding
            width: root.paneWidth
            height: root.paneHeight
            style: root.shellStyle
            showRightBorder: false
            showAccentRail: false

            Todos.TodosPane {
                id: todosPane

                anchors.fill: parent
                anchors.margins: Theme.Theme.modulePadding
                shellStyle: root.shellStyle
                paneState: todosState
                visible: root.expandedRightPane.length === 0
                onExpandRequested: root.openExpanded()
                onCloseRequested: Services.PaneManager.closeRight()
            }
        }
    }

    Todos.TodosExpandedOverlay {
        id: todosExpandedOverlay

        anchors.fill: parent
        visible: root.expandedRightPane === Services.PaneManager.rightTabTasks
        shellStyle: root.shellStyle
        paneState: todosState
        onCloseRequested: root.closeExpanded()
    }

    Todos.TodosNewTaskOverlay {
        id: todosNewTaskOverlay

        anchors.fill: parent
        visible: root.newTaskOverlayActive()
        open: false
        shellStyle: root.shellStyle
        paneState: todosState
        onCloseRequested: Services.PaneManager.closeNewTask()
        onShouldShowChanged: root.syncWindowState()
    }

    mask: Region {
        item: root.newTaskOverlayActive() ? todosNewTaskOverlay : (root.expandedRightPane === Services.PaneManager.rightTabTasks ? todosExpandedOverlay : paneAnimation)
    }

    Connections {
        target: Services.PaneManager

        function onRightOpenChanged() {
            root.syncPaneOpen();
            root.focusActivePane();
        }

        function onRightScreenChanged() {
            root.syncPaneOpen();
            root.focusActivePane();
        }

        function onRightTabChanged() {
            root.expandedRightPane = "";
            root.focusActivePane();
        }

        function onNewTaskOpenChanged() {
            root.syncNewTaskOverlayOpen();
            root.syncPaneOpen();
            root.focusNewTaskOverlay();
        }

        function onNewTaskScreenChanged() {
            root.syncNewTaskOverlayOpen();
            root.syncPaneOpen();
            root.focusNewTaskOverlay();
        }
    }

    Component.onCompleted: {
        syncNewTaskOverlayOpen();
        syncPaneOpen();
        focusActivePane();
    }
}
