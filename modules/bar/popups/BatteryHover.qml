pragma ComponentBehavior: Bound

import QtQuick
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

    readonly property var statusRows: [
        {
            "icon": "󱐋",
            "label": "Rate",
            "value": Services.BatteryState.wattsText,
            "visible": Services.BatteryState.wattsText !== "Unavailable"
        },
        {
            "icon": "󰣐",
            "label": "Health",
            "value": Services.BatteryState.healthText,
            "visible": Services.BatteryState.healthText !== "Unavailable"
        }
    ]
    readonly property var visibleStatusRows: root.statusRows.filter((row) => row.visible)

    Components.HoverPopupMeterRow {
        iconText: "󰁹"
        label: "Battery"
        valueText: Services.BatteryState.percentage + "%"
        barValue: Services.BatteryState.percentage / 100
        fillColor: Services.BatteryState.percentage <= 15 ? Theme.Theme.red : Services.BatteryState.percentage <= 35 ? Theme.Theme.peach : Theme.Theme.popupFill
    }

    Components.HoverPopupDivider {}

    Components.HoverPopupMeterRow {
        iconText: "󰚥"
        label: "Status"
        valueText: Services.BatteryState.statusSummary
        showBar: false
    }

    Repeater {
        model: root.visibleStatusRows

        delegate: Components.HoverPopupMeterRow {
            required property var modelData

            iconText: modelData.icon
            label: modelData.label
            valueText: modelData.value
            showBar: false
        }
    }

    Components.HoverPopupMeterRow {
        visible: Services.BatteryState.degradationActive
        iconText: "󰓅"
        label: "Performance"
        showBar: false
        detail: Services.BatteryState.degradationText
        detailWrap: true
    }
}
