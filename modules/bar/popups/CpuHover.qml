pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    readonly property var placeholderCpuCores: Array.from({ length: 16 }, (_, index) => ({
        index: index,
        usagePercent: 0,
        coreType: "unknown"
    }))
    readonly property var cpuCoreModel: Services.SystemStatsState.cpuCores.length > 0 ? Services.SystemStatsState.cpuCores : root.placeholderCpuCores
    readonly property var performanceCores: root.cpuCoreModel.filter((core) => core.coreType === "performance")
    readonly property var efficientCores: root.cpuCoreModel.filter((core) => core.coreType === "efficient")
    readonly property var lowPowerCores: root.cpuCoreModel.filter((core) => core.coreType === "lowPowerEfficient")
    readonly property var fallbackCores: root.cpuCoreModel.filter((core) => ["performance", "efficient", "lowPowerEfficient"].indexOf(core.coreType) === -1)
    readonly property var clusterSections: [
        {
            "title": "Performance",
            "accent": Theme.Theme.peach,
            "cores": root.performanceCores
        },
        {
            "title": "Efficient",
            "accent": Theme.Theme.blue,
            "cores": root.efficientCores
        },
        {
            "title": "Low Power",
            "accent": Theme.Theme.teal,
            "cores": root.lowPowerCores
        },
        {
            "title": "Other",
            "accent": Theme.Theme.barAccent,
            "cores": root.fallbackCores
        }
    ]
    readonly property var visibleClusterSections: root.clusterSections.filter((section) => section.cores.length > 0)

    minPopupWidth: 275

    function averageUsage(cores) {
        if (!cores || cores.length === 0)
            return 0;

        return Math.round(cores.reduce((sum, core) => sum + core.usagePercent, 0) / cores.length);
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.visibleClusterSections

            delegate: Components.HoverPopupCard {
                id: clusterCard

                required property var modelData

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: clusterCard.modelData.title
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.Theme.text
                    }

                    Text {
                        text: root.averageUsage(clusterCard.modelData.cores) + "%"
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.Theme.text
                    }
                }

                Flow {
                    id: coreFlow

                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: clusterCard.modelData.cores

                        delegate: Components.HoverPopupMetricBar {
                            id: coreChip

                            required property var modelData

                            width: Math.floor((coreFlow.width - coreFlow.spacing) / 2)
                            barHeight: (Theme.Theme.indicatorThickness + 5) * 2
                            value: coreChip.modelData.usagePercent / 100
                            fillColor: clusterCard.modelData.accent

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 6

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: coreChip.modelData.usagePercent + "%"
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
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: Services.SystemStatsState.topCpuProcesses.length > 0 ? Services.SystemStatsState.topCpuProcesses : [
                {
                    "pid": 0,
                    "cpuPercent": 0,
                    "command": "Unavailable"
                }
            ]

            delegate: Components.HoverPopupProcessRow {
                required property var modelData

                pid: modelData.pid
                command: modelData.command
                metricText: modelData.pid > 0 ? Services.SystemStatsState.formatProcessCpuPercent(modelData.cpuPercent) : ""
            }
        }
    }
}
