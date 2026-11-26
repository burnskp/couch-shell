pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components" as Components
import "../../services" as Services
import "../../theme" as Theme
import "./widgets" as Widgets

Item {
    id: root

    required property var anchorWindow
    required property var barScreen
    // Maps bar.widgets ids (see ShellConfig.barWidgetIds) to their chips.
    readonly property var widgetComponents: ({
            cpu: cpuComponent,
            temperature: temperatureComponent,
            ram: ramComponent,
            disk: diskComponent,
            aiUsage: aiUsageComponent,
            wifi: wifiComponent,
            battery: batteryComponent,
            audio: audioComponent,
            clock: clockComponent
        })
    property var trackedWidgets: []

    function syncTrackedWidgets() {
        const widgets = [];
        for (let index = 0; index < widgetRepeater.count; index++) {
            const loader = widgetRepeater.itemAt(index) as Loader;
            if (loader && loader.item)
                widgets.push(loader.item);
        }
        root.trackedWidgets = widgets;
    }

    Component {
        id: cpuComponent

        Widgets.CpuWidget {}
    }

    Component {
        id: temperatureComponent

        Widgets.TemperatureWidget {}
    }

    Component {
        id: ramComponent

        Widgets.RamWidget {}
    }

    Component {
        id: diskComponent

        Widgets.DiskWidget {}
    }

    Component {
        id: aiUsageComponent

        Widgets.AiUsageWidget {
            barScreen: root.barScreen
        }
    }

    Component {
        id: wifiComponent

        Widgets.WifiWidget {}
    }

    Component {
        id: batteryComponent

        Widgets.BatteryWidget {}
    }

    Component {
        id: audioComponent

        Widgets.AudioWidget {}
    }

    Component {
        id: clockComponent

        Components.DigitalClock {}
    }

    Rectangle {
        id: barSurface

        anchors.fill: parent
        color: Theme.Theme.barBackground
        radius: 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Theme.barEdgePadding
        anchors.rightMargin: Theme.Theme.barEdgePadding
        spacing: Theme.Theme.sectionGap

        Widgets.WorkspaceStrip {
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            id: windowListSlot

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredHeight: windowList.implicitHeight
            implicitHeight: windowList.implicitHeight
            clip: true

            Widgets.WindowList {
                id: windowList

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                availableWidth: windowListSlot.width
                width: Math.min(implicitWidth, windowListSlot.width)
            }
        }

        Repeater {
            id: widgetRepeater

            model: Services.ShellConfig.barWidgets
            onItemAdded: root.syncTrackedWidgets()
            onItemRemoved: Qt.callLater(root.syncTrackedWidgets)

            delegate: Loader {
                required property string modelData

                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                sourceComponent: root.widgetComponents[modelData] ?? null
                onLoaded: root.syncTrackedWidgets()
            }
        }

        Widgets.StatusClusterWidget {
            id: statusCluster

            barScreen: root.barScreen
            systemMenuActive: Services.SystemMenuManager.isVisibleOnScreen(root.barScreen)
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            onSystemButtonClicked: Services.SystemMenuManager.toggle(root.barScreen)
        }
    }

    BarHoverPopupHost {
        id: hoverPopupHost

        anchorWindow: root.anchorWindow
        anchorSurface: barSurface
        openDelay: 500
        closeDelay: 120
        trackedWidgets: root.trackedWidgets
    }

    Connections {
        target: hoverPopupHost

        function onActivePopupKeyChanged() {
            Services.SystemStatsState.setTopCpuProcessesEnabled(hoverPopupHost.activePopupKey === Components.HoverPopupPresets.cpu);
            Services.SystemStatsState.setTopMemoryProcessesEnabled(hoverPopupHost.activePopupKey === Components.HoverPopupPresets.ram);
        }
    }

    Component.onCompleted: {
        Services.SystemStatsState.setTopCpuProcessesEnabled(hoverPopupHost.activePopupKey === Components.HoverPopupPresets.cpu);
        Services.SystemStatsState.setTopMemoryProcessesEnabled(hoverPopupHost.activePopupKey === Components.HoverPopupPresets.ram);
    }
}
