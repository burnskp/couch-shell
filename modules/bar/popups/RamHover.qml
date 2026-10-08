pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275

    readonly property var memorySections: [
        {
            "title": "Memory",
            "accent": Theme.Theme.popupFill,
            "percent": Services.SystemStatsState.memoryPercent,
            "summary": Services.SystemStatsState.formatGib(Services.SystemStatsState.memoryUsedBytes) + " / " + Services.SystemStatsState.memoryAvailableLabel,
            "visible": true
        },
        {
            "title": "Swap",
            "accent": Theme.Theme.popupFill,
            "percent": Services.SystemStatsState.swapPercent,
            "summary": Services.SystemStatsState.formatGib(Services.SystemStatsState.swapUsedBytes) + " / " + Services.SystemStatsState.formatGib(Math.max(Services.SystemStatsState.swapTotalBytes - Services.SystemStatsState.swapUsedBytes, 0)),
            "visible": Services.SystemStatsState.swapTotalBytes > 0
        }
    ]
    readonly property var visibleMemorySections: root.memorySections.filter((section) => section.visible)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.visibleMemorySections

            delegate: Components.HoverPopupCard {
                id: memoryCard

                required property var modelData

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: memoryCard.modelData.title
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.Theme.text
                    }

                    Text {
                        text: memoryCard.modelData.summary
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize - 1
                        font.weight: Font.Bold
                        color: Theme.Theme.text
                    }
                }

                Components.HoverPopupMetricBar {
                    value: memoryCard.modelData.percent / 100
                    fillColor: memoryCard.modelData.accent

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: memoryCard.modelData.percent + "%"
                            font.family: Theme.Theme.fontFamily
                            font.pixelSize: Theme.Theme.fontSize - 3
                            font.weight: Font.Bold
                            color: Theme.Theme.text
                        }
                    }
                }
            }
        }
    }

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
