pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

    readonly property var memorySections: [
        {
            "title": "Memory",
            "percent": Services.SystemStatsState.memoryPercent,
            "summary": Services.SystemStatsState.formatGib(Services.SystemStatsState.memoryUsedBytes) + " used / " + Services.SystemStatsState.memoryAvailableLabel + " free",
            "visible": true
        },
        {
            "title": "Swap",
            "percent": Services.SystemStatsState.swapPercent,
            "summary": Services.SystemStatsState.formatGib(Services.SystemStatsState.swapUsedBytes) + " used / " + Services.SystemStatsState.formatGib(Math.max(Services.SystemStatsState.swapTotalBytes - Services.SystemStatsState.swapUsedBytes, 0)) + " free",
            "visible": Services.SystemStatsState.swapTotalBytes > 0
        }
    ]
    readonly property var visibleMemorySections: root.memorySections.filter((section) => section.visible)

    Repeater {
        model: root.visibleMemorySections

        delegate: Components.HoverPopupMeterRow {
            required property var modelData

            label: modelData.title
            valueText: modelData.percent + "%"
            barValue: modelData.percent / 100
            detail: modelData.summary
        }
    }

    Components.HoverPopupDivider {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: Services.SystemStatsState.topMemoryProcesses.length > 0 ? Services.SystemStatsState.topMemoryProcesses : [
                {
                    "pid": 0,
                    "rssBytes": 0,
                    "command": "Unavailable"
                }
            ]

            delegate: Components.HoverPopupProcessRow {
                required property var modelData

                pid: modelData.pid
                command: modelData.command
                metricText: modelData.pid > 0 ? Services.SystemStatsState.formatBytes(modelData.rssBytes) : ""
            }
        }
    }
}
