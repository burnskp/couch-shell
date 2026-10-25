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
            "cores": root.performanceCores
        },
        {
            "title": "Efficient",
            "cores": root.efficientCores
        },
        {
            "title": "Low Power",
            "cores": root.lowPowerCores
        },
        {
            "title": "Other",
            "cores": root.fallbackCores
        }
    ]
    readonly property var visibleClusterSections: root.clusterSections.filter((section) => section.cores.length > 0)

    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

    function averageUsage(cores) {
        if (!cores || cores.length === 0)
            return 0;

        return Math.round(cores.reduce((sum, core) => sum + core.usagePercent, 0) / cores.length);
    }

    FontMetrics {
        id: clusterLabelMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }

    Repeater {
        model: root.visibleClusterSections

        delegate: ColumnLayout {
            id: clusterSection

            required property var modelData

            Layout.fillWidth: true
            spacing: Theme.Theme.listGap

            Components.HoverPopupMeterRow {
                iconText: "󰘚"
                label: clusterSection.modelData.title
                // One character of padding matches the label-to-bar gap on the other hovers.
                labelColumnWidth: Math.ceil(clusterLabelMetrics.advanceWidth("Performance") + clusterLabelMetrics.advanceWidth(" "))
                valueText: root.averageUsage(clusterSection.modelData.cores) + "%"
                barValue: root.averageUsage(clusterSection.modelData.cores) / 100
            }

            // A single-core cluster is fully described by its title bar.
            Flow {
                id: coreFlow

                visible: clusterSection.modelData.cores.length > 1
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: clusterSection.modelData.cores

                    delegate: Components.HoverPopupMetricBar {
                        id: coreChip

                        required property var modelData

                        width: Math.floor((coreFlow.width - coreFlow.spacing) / 2)
                        value: coreChip.modelData.usagePercent / 100

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
                                color: Theme.Theme.popupValue
                            }
                        }
                    }
                }
            }
        }
    }

    Components.HoverPopupDivider {}

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
