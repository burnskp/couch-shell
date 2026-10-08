pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQml

QtObject {
    id: root

    readonly property string leftTabCouchAi: "couch-ai"
    readonly property string rightTabTasks: "tasks"

    property bool leftOpen: false
    property bool rightOpen: false
    property var leftScreen: null
    property var rightScreen: null
    property bool newTaskOpen: false
    property var newTaskScreen: null
    property string leftTab: root.leftTabCouchAi
    property string rightTab: root.rightTabTasks

    readonly property IpcHandler paneIpc: IpcHandler {
        target: "panes"

        function toggleCouchAi() {
            root.toggleLeftTab(root.focusedScreen(), root.leftTabCouchAi);
        }

        function toggleTasks() {
            root.toggleRightTab(root.focusedScreen(), root.rightTabTasks);
        }

        function openNewTask() {
            root.openNewTask(root.focusedScreen());
        }
    }

    function firstScreen() {
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function normalizeLeftTab(tab) {
        switch ((tab || "").toString().trim().toLowerCase()) {
        case root.leftTabCouchAi:
        case "couch ai":
        case "couch_ai":
        default:
            return root.leftTabCouchAi;
        }
    }

    function normalizeRightTab(tab) {
        switch ((tab || "").toString().trim().toLowerCase()) {
        case root.rightTabTasks:
        default:
            return root.rightTabTasks;
        }
    }

    function isLeftVisibleOnScreen(screen) {
        return root.leftOpen && root.leftScreen === screen;
    }

    function isRightVisibleOnScreen(screen) {
        return root.rightOpen && root.rightScreen === screen;
    }

    function isNewTaskVisibleOnScreen(screen) {
        return root.newTaskOpen && root.newTaskScreen === screen;
    }

    function closeLeft() {
        root.leftOpen = false;
    }

    function closeRight() {
        root.rightOpen = false;
    }

    function closeNewTask() {
        root.newTaskOpen = false;
    }

    function openLeft(screen, tab) {
        if (!screen)
            return;

        root.leftScreen = screen;
        root.leftTab = normalizeLeftTab(tab || root.leftTab);
        root.leftOpen = true;
    }

    function openRight(screen, tab) {
        if (!screen)
            return;

        root.rightScreen = screen;
        root.rightTab = normalizeRightTab(tab || root.rightTab);
        root.rightOpen = true;
    }

    function openNewTask(screen) {
        if (!screen)
            return;

        root.newTaskScreen = screen;
        root.newTaskOpen = true;
    }

    function toggleLeft(screen) {
        toggleLeftTab(screen, root.leftTab);
    }

    function toggleRight(screen) {
        toggleRightTab(screen, root.rightTab);
    }

    function toggleLeftTab(screen, tab) {
        if (!screen)
            return;

        const nextTab = normalizeLeftTab(tab);
        if (root.isLeftVisibleOnScreen(screen) && root.leftTab === nextTab) {
            root.closeLeft();
            return;
        }

        root.openLeft(screen, nextTab);
    }

    function toggleRightTab(screen, tab) {
        if (!screen)
            return;

        const nextTab = normalizeRightTab(tab);
        if (root.isRightVisibleOnScreen(screen) && root.rightTab === nextTab) {
            root.closeRight();
            return;
        }

        root.openRight(screen, nextTab);
    }

    function focusedScreen() {
        const focusedMonitor = Hyprland.focusedMonitor;
        if (!focusedMonitor)
            return root.firstScreen();

        for (const screen of Quickshell.screens) {
            if (screen && screen.name === focusedMonitor.name)
                return screen;
        }

        return root.firstScreen();
    }
}
