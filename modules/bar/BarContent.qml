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

        Widgets.CpuWidget {
            id: cpuWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Widgets.TemperatureWidget {
            id: temperatureWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Widgets.RamWidget {
            id: ramWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Widgets.DiskWidget {
            id: diskWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Widgets.WifiWidget {
            id: wifiWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Widgets.BatteryWidget {
            id: batteryWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Widgets.AudioWidget {
            id: audioWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        Components.DigitalClock {
            id: clockWidget

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
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
        trackedWidgets: [clockWidget, audioWidget, batteryWidget, wifiWidget, diskWidget, ramWidget, temperatureWidget, cpuWidget]
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
