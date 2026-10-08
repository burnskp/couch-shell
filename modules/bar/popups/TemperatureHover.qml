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

    readonly property int rowHeight: 28
    readonly property int rowSpacing: Theme.Theme.listGap
    readonly property int iconColumnWidth: 22
    readonly property int labelColumnWidth: 52
    readonly property int valueColumnWidth: 48

    readonly property var thermalRows: Services.SystemStatsState.temperatureRows
    readonly property var visibleThermalRows: root.thermalRows.filter(row => Number.isFinite(row.temperatureC))
    readonly property var coolingRows: Services.SystemStatsState.fanRows
    readonly property var activeCoolingRows: root.coolingRows.filter(row => row.rpm > 0)
    readonly property bool coolingIdle: root.coolingRows.length > 0 && root.activeCoolingRows.length === 0
    readonly property real highestFanRpm: {
        let highest = 0;

        for (const row of root.activeCoolingRows)
            highest = Math.max(highest, row.rpm >= 0 ? row.rpm : 0);

        return Math.max(highest, 1);
    }

    function sensorIcon(row) {
        const label = row && row.label ? row.label.toString().toLowerCase() : "";

        if (label.indexOf("wifi") >= 0 || label.indexOf("wireless") >= 0)
            return "󰖩";

        if (label.indexOf("ram") >= 0 || label.indexOf("memory") >= 0)
            return "󰍛";

        if (label.indexOf("nvme") >= 0 || label.indexOf("ssd") >= 0 || label.indexOf("disk") >= 0)
            return "󰋊";

        if (label.indexOf("cpu") >= 0 || label.indexOf("package") >= 0 || label.indexOf("core") >= 0)
            return "󰘚";

        return "";
    }

    function normalizedTemperature(row) {
        if (!row || !Number.isFinite(row.temperatureC) || !Number.isFinite(row.criticalC) || row.criticalC <= 0)
            return 0;

        return Math.max(0, Math.min(1, row.temperatureC / row.criticalC));
    }

    Repeater {
        model: root.visibleThermalRows

        delegate: RowLayout {
            id: thermalRow

            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: root.rowHeight
            spacing: root.rowSpacing

            Text {
                Layout.preferredWidth: root.iconColumnWidth
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.sensorIcon(thermalRow.modelData)
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize + 6
                font.weight: Font.Bold
                color: Theme.Theme.popupIcon
            }

            Text {
                Layout.preferredWidth: root.labelColumnWidth
                Layout.alignment: Qt.AlignVCenter
                text: thermalRow.modelData.label
                elide: Text.ElideRight
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.popupLabel
            }

            Components.HoverPopupMetricBar {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: root.normalizedTemperature(thermalRow.modelData)
                fillColor: Theme.Theme.popupFill
                trackColor: Theme.Theme.popupTrack
            }

            Text {
                Layout.preferredWidth: root.valueColumnWidth
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: thermalRow.modelData.temperatureLabel
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.popupValue
            }
        }
    }

    Components.HoverPopupDivider {
        visible: root.visibleThermalRows.length > 0 && root.coolingRows.length > 0
    }

    Repeater {
        model: root.coolingIdle ? [
            {
                "label": "Fans",
                "rpm": 0,
                "rpmLabel": "Idle"
            }
        ] : root.coolingRows

        delegate: RowLayout {
            id: fanRow

            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: root.rowHeight
            spacing: root.rowSpacing

            Text {
                Layout.preferredWidth: root.iconColumnWidth
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: "󰈐"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize + 6
                font.weight: Font.Bold
                color: Theme.Theme.popupIcon
            }

            Text {
                Layout.preferredWidth: root.labelColumnWidth
                Layout.alignment: Qt.AlignVCenter
                text: fanRow.modelData.label
                elide: Text.ElideRight
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.popupLabel
            }

            Components.HoverPopupMetricBar {
                visible: !root.coolingIdle
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: Math.max(0, Math.min(1, fanRow.modelData.rpm / root.highestFanRpm))
                fillColor: Theme.Theme.popupFill
                trackColor: Theme.Theme.popupTrack
            }

            Item {
                visible: root.coolingIdle
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }

            Text {
                Layout.preferredWidth: root.valueColumnWidth
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: fanRow.modelData.rpmLabel
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: root.coolingIdle ? Theme.Theme.popupIdle : Theme.Theme.popupValue
            }
        }
    }
}
