pragma Singleton

import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool busy: false
    property var pendingCommand: []

    function run(command) {
        if (busy || !command || command.length === 0)
            return;

        pendingCommand = command;
        busy = true;
        actionProcess.running = true;
    }

    function lock() {
        run(["sh", "-lc", "if command -v hyprlock >/dev/null 2>&1; then exec hyprlock; else exec loginctl lock-session; fi"]);
    }

    function logout() {
        run(["sh", "-lc", "if command -v hyprctl >/dev/null 2>&1; then exec hyprctl dispatch exit; elif [ -n \"${XDG_SESSION_ID:-}\" ]; then exec loginctl terminate-session \"$XDG_SESSION_ID\"; else exec loginctl terminate-user \"$USER\"; fi"]);
    }

    function suspend() {
        run(["systemctl", "suspend"]);
    }

    function reloadHyprland() {
        run(["sh", "-lc", "if command -v hyprctl >/dev/null 2>&1; then exec hyprctl reload; fi"]);
    }

    function reboot() {
        run(["systemctl", "reboot"]);
    }

    function powerOff() {
        run(["systemctl", "poweroff"]);
    }

    Process {
        id: actionProcess

        command: root.pendingCommand

        onRunningChanged: {
            if (!running)
                root.busy = false;
        }
    }
}
