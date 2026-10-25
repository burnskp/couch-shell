pragma ComponentBehavior: Bound

import QtQuick
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

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

        delegate: Components.HoverPopupMeterRow {
            required property var modelData

            iconText: root.sensorIcon(modelData)
            valueColumnWidth: 48
            label: modelData.label
            valueText: modelData.temperatureLabel
            barValue: root.normalizedTemperature(modelData)
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

        delegate: Components.HoverPopupMeterRow {
            required property var modelData

            iconText: "󰈐"
            valueColumnWidth: 48
            label: modelData.label
            valueText: modelData.rpmLabel
            showBar: !root.coolingIdle
            barValue: Math.max(0, Math.min(1, modelData.rpm / root.highestFanRpm))
        }
    }
}
