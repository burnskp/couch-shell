pragma Singleton

import Quickshell.Io
import QtQuick
import "." as Services

Item {
    id: root

    property bool available: false
    property bool active: false
    property bool busy: false
    property string unitName: ""
    property string controlMode: ""
    property string pendingAction: ""

    readonly property string statusLabel: active ? "Screen saver enabled" : "Screen saver disabled"

    function parseStatus(output) {
        const data = ({ });
        const lines = (output || "").split("\n");

        for (const line of lines) {
            const index = line.indexOf("=");
            if (index === -1)
                continue;

            data[line.slice(0, index)] = line.slice(index + 1);
        }

        available = data.available === "yes";
        active = data.active === "yes";
        unitName = data.unit || "";
        controlMode = data.mode || "";
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

        pendingAction = active ? "off" : "on";
        busy = true;
        actionProcess.running = true;
    }

    function statusScript() {
        return [
            'find_systemd_unit() {',
            '  for candidate in hypridle.service swayidle.service xscreensaver.service; do',
            '    load_state=$(systemctl --user show -p LoadState --value "$candidate" 2>/dev/null || true)',
            '    if [ -n "$load_state" ] && [ "$load_state" != not-found ]; then',
            '      printf "%s" "$candidate"',
            '      return 0',
            '    fi',
            '    if systemctl --user list-unit-files "$candidate" --no-legend 2>/dev/null | grep -q "^$candidate[[:space:]]"; then',
            '      printf "%s" "$candidate"',
            '      return 0',
            '    fi',
            '  done',
            '}',
            '',
            'if command -v systemctl >/dev/null 2>&1; then',
            '  unit=$(find_systemd_unit)',
            '  if [ -n "$unit" ]; then',
            '    active_state=$(systemctl --user is-active "$unit" 2>/dev/null || true)',
            '    printf "available=yes\\n"',
            '    printf "mode=systemd\\n"',
            '    printf "unit=%s\\n" "$unit"',
            '    if [ "$active_state" = active ]; then printf "active=yes\\n"; else printf "active=no\\n"; fi',
            '    exit 0',
            '  fi',
            'fi',
            '',
            'for candidate in hypridle swayidle xscreensaver; do',
            '  if command -v "$candidate" >/dev/null 2>&1; then',
            '    printf "available=yes\\n"',
            '    printf "mode=process\\n"',
            '    printf "unit=%s\\n" "$candidate"',
            '    if pgrep -x "$candidate" >/dev/null 2>&1; then printf "active=yes\\n"; else printf "active=no\\n"; fi',
            '    exit 0',
            '  fi',
            'done',
            '',
            'printf "available=no\\nactive=no\\n"'
        ].join("\n");
    }

    function actionScript() {
        return [
            'action="$1"',
            'target="$2"',
            'mode="$3"',
            '',
            'if [ -z "$action" ] || [ -z "$target" ] || [ -z "$mode" ]; then',
            '  exit 0',
            'fi',
            '',
            'case "$mode" in',
            '  systemd)',
            '    if [ "$action" = on ]; then',
            '      systemctl --user start "$target" >/dev/null 2>&1 || true',
            '    else',
            '      systemctl --user stop "$target" >/dev/null 2>&1 || true',
            '    fi',
            '    ;;',
            '  process)',
            '    if [ "$action" = on ]; then',
            '      if ! pgrep -x "$target" >/dev/null 2>&1; then',
            '        nohup "$target" >/dev/null 2>&1 &',
            '      fi',
            '    else',
            '      pkill -x "$target" >/dev/null 2>&1 || true',
            '    fi',
            '    ;;',
            'esac'
        ].join("\n");
    }

    Process {
        id: statusProcess

        command: ["sh", "-lc", root.statusScript()]

        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(this.text)
        }
    }

    Process {
        id: actionProcess

        command: ["sh", "-lc", root.actionScript(), "sh", root.pendingAction, root.unitName, root.controlMode]

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
