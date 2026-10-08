pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275
    readonly property var statusRows: [
        {
            "label": "Rate",
            "value": Services.BatteryState.wattsText,
            "visible": Services.BatteryState.wattsText !== "Unavailable"
        },
        {
            "label": "Health",
            "value": Services.BatteryState.healthText,
            "visible": Services.BatteryState.healthText !== "Unavailable"
        }
    ]
    readonly property var visibleStatusRows: root.statusRows.filter((row) => row.visible)

    Components.HoverPopupCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Battery"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: Services.BatteryState.percentage + "%"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }
        }

        Components.HoverPopupMetricBar {
            value: Services.BatteryState.percentage / 100
            fillColor: Services.BatteryState.percentage <= 15 ? Theme.Theme.red : Services.BatteryState.percentage <= 35 ? Theme.Theme.peach : Theme.Theme.popupFill
        }
    }

    Components.HoverPopupCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Status"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize + 1
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: Services.BatteryState.statusSummary
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.subtext0
            }
        }

        Repeater {
            model: root.visibleStatusRows

            delegate: Components.HoverPopupKeyValueRow {
                required property var modelData

                label: modelData.label
                value: modelData.value
                labelColumnWidth: 54
                labelPixelSize: Theme.Theme.fontSize - 1
                valuePixelSize: Theme.Theme.fontSize - 1
            }
        }
    }

    Components.HoverPopupCard {
        visible: Services.BatteryState.degradationActive

        Text {
            Layout.fillWidth: true
            text: "Performance"
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize
            font.weight: Font.Bold
            color: Theme.Theme.text
        }

        Text {
            Layout.fillWidth: true
            text: Services.BatteryState.degradationText
            wrapMode: Text.WordWrap
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize - 1
            font.weight: Font.Bold
            color: Theme.Theme.subtext0
        }
    }
}
