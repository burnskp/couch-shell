pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../services/AiUsageLogic.js" as Logic
import "../../../theme" as Theme

Components.HoverPopupFrame {
    minPopupWidth: 275

    Components.HoverPopupCard {
        Components.HoverPopupKeyValueRow {
            label: Services.AiUsageState.title
            labelColumnWidth: 150
            value: Services.AiUsageState.provider.plan
        }
        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: Services.AiUsageState.message
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize - 1
            color: Theme.Theme.subtext0
        }
    }

    Repeater {
        model: Services.AiUsageState.provider.windows
        delegate: Components.HoverPopupCard {
            id: quotaCard
            required property var modelData

            Components.HoverPopupKeyValueRow {
                label: Logic.windowLabel(quotaCard.modelData)
                labelColumnWidth: 95
                value: Logic.percentage(quotaCard.modelData.remainingPercent) + " left"
            }
            Components.HoverPopupMetricBar {
                value: quotaCard.modelData.remainingPercent / 100
                fillColor: quotaCard.modelData.remainingPercent === 0 ? Theme.Theme.red : Theme.Theme.popupFill
            }
            Components.HoverPopupKeyValueRow {
                label: Services.AiUsageState.stale ? "Reset (stale)" : "Resets in"
                labelColumnWidth: 95
                value: Logic.resetDuration(quotaCard.modelData.resetsAt, Services.AiUsageState.now)
            }
        }
    }
}
