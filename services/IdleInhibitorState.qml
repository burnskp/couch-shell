pragma Singleton

import QtQml

QtObject {
    id: root

    property bool enabled: false

    readonly property string iconGlyph: enabled ? "󰅶" : "󰛊"
    readonly property string shortLabel: enabled ? "Awake" : "Idle"
    readonly property string statusLabel: enabled ? "Idle inhibitor enabled" : "Idle inhibitor disabled"
    readonly property string description: enabled ? "Automatic locking and idle sleep are paused." : "Automatic locking follows normal idle timeouts."

    function toggle() {
        root.enabled = !root.enabled;
    }
}
