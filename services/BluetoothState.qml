pragma Singleton

import Quickshell.Io
import QtQuick
import "." as Services

Item {
    id: root

    property bool available: false
    enabled: false
    property bool busy: false
    property string pendingAction: ""

    function parseStatus(output) {
        const text = (output || "").toLowerCase();
        root.available = text.trim().length > 0 && text.indexOf("unsupported") === -1 && text.indexOf("not available") === -1;

        if (text.indexOf("powered: yes") !== -1 || text.indexOf("enabled") !== -1)
            root.enabled = true;
        else if (text.indexOf("powered: no") !== -1 || text.indexOf("disabled") !== -1)
            root.enabled = false;
    }

    function refresh() {
        if (Services.BarManager.visible && !busy && !statusProcess.running)
            statusProcess.running = true;
    }

    function syncBarLifecycle() {
        if (Services.BarManager.visible) {
            root.refresh();
            return;
        }

        if (statusProcess.running)
            statusProcess.running = false;
    }

    function toggle() {
        if (!available || busy)
            return;

        pendingAction = enabled ? "off" : "on";
        busy = true;
        actionProcess.running = true;
    }

    Process {
        id: statusProcess

        command: ["sh", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl show 2>/dev/null || printf 'unsupported\n'; elif command -v nmcli >/dev/null 2>&1; then printf 'powered: '; nmcli radio bluetooth 2>/dev/null || printf 'unsupported\n'; else printf 'unsupported\n'; fi"]

        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(this.text)
        }
    }

    Process {
        id: actionProcess

        command: ["sh", "-lc", 'if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl power "$1" >/dev/null 2>&1; elif command -v nmcli >/dev/null 2>&1; then nmcli radio bluetooth "$1" >/dev/null 2>&1; fi', "sh", root.pendingAction]

        onRunningChanged: {
            if (!running) {
                root.busy = false;
                root.refresh();
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: Services.BarManager.visible
        onTriggered: root.refresh()
    }

    Connections {
        target: Services.BarManager

        function onVisibleChanged() {
            root.syncBarLifecycle();
        }
    }

    Component.onCompleted: root.syncBarLifecycle()
}
