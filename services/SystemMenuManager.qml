pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import "." as Services

QtObject {
    id: root

    property bool open: false
    property var screen: null
    property var barManagerConnections: Connections {
        target: Services.BarManager

        function onVisibleChanged() {
            if (!Services.BarManager.visible)
                root.close();
        }
    }

    function isVisibleOnScreen(targetScreen) {
        return root.open && root.screen === targetScreen;
    }

    function toggle(targetScreen) {
        if (root.isVisibleOnScreen(targetScreen)) {
            root.close();
            return;
        }

        root.openOnScreen(targetScreen);
    }

    function openOnScreen(targetScreen) {
        Services.NotificationManager.closeHistory();
        root.screen = targetScreen;
        root.open = true;
    }

    function close() {
        root.open = false;
    }
}
