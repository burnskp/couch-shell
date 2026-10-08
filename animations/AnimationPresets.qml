pragma Singleton

import QtQuick

QtObject {
    readonly property int hoverRevealDurationMs: 420
    readonly property int smokeDurationMs: 800
    readonly property int slideInEnterDurationMs: 600
    readonly property int easeOutCubic: Easing.OutCubic
}
