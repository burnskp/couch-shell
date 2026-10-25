pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../services/AiUsageLogic.js" as Logic
import "../../../theme" as Theme

Components.HoverPopupFrame {
    minPopupWidth: 275

    Repeater {
        model: Services.AiUsageState.hoverProviders
        delegate: Components.HoverPopupCard {
            id: providerCard
            required property var modelData
            readonly property bool stale: Services.AiUsageState.providerStale(modelData)

            Components.HoverPopupKeyValueRow {
                label: Services.AiUsageState.providerTitle(providerCard.modelData)
                labelColumnWidth: 150
                value: providerCard.modelData.plan
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: Services.AiUsageState.providerMessage(providerCard.modelData)
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                color: Theme.Theme.subtext0
            }

            Components.HoverPopupDivider { visible: providerCard.modelData.windows.length > 0 }
            // Spacing, not dividers, separates quota windows within one provider.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: providerCard.modelData.windows
                    delegate: ColumnLayout {
                        id: quotaSection
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: providerCard.contentSpacing

                        Components.HoverPopupKeyValueRow {
                            label: Logic.windowLabel(quotaSection.modelData)
                            labelColumnWidth: 95
                            value: Logic.percentage(quotaSection.modelData.remainingPercent) + " left"
                        }
                        Components.HoverPopupMetricBar {
                            value: quotaSection.modelData.remainingPercent / 100
                            fillColor: quotaSection.modelData.remainingPercent === 0 ? Theme.Theme.red : Theme.Theme.popupFill
                        }
                        Components.HoverPopupKeyValueRow {
                            label: providerCard.stale ? "Reset (stale)" : "Resets in"
                            labelColumnWidth: 95
                            value: Logic.resetDuration(quotaSection.modelData.resetsAt, Services.AiUsageState.now)
                        }
                    }
                }
            }
        }
    }
}
