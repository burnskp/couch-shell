pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../services/AiUsageLogic.js" as Logic
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

    FontMetrics {
        id: windowLabelMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }

    Repeater {
        model: Services.AiUsageState.hoverProviders
        delegate: ColumnLayout {
            id: providerSection
            required property var modelData
            required property int index
            readonly property bool stale: Services.AiUsageState.providerStale(modelData)

            Layout.fillWidth: true
            spacing: root.contentSpacing

            Components.HoverPopupDivider { visible: providerSection.index > 0 }

            Components.HoverPopupMeterRow {
                iconColumnWidth: 0
                label: Services.AiUsageState.providerTitle(providerSection.modelData)
                valueText: providerSection.modelData.plan
                showBar: false
                detail: Services.AiUsageState.providerMessage(providerSection.modelData)
                detailWrap: true
            }

            Repeater {
                model: providerSection.modelData.windows
                delegate: Components.HoverPopupMeterRow {
                    required property var modelData
                    // The section can be torn down before its window rows on provider changes.
                    readonly property bool stale: providerSection !== null && providerSection.stale

                    iconColumnWidth: 0
                    labelColumnWidth: Math.ceil(windowLabelMetrics.advanceWidth("Primary limit") + windowLabelMetrics.advanceWidth(" "))
                    label: Logic.windowLabel(modelData)
                    valueText: Logic.percentage(modelData.remainingPercent)
                    barValue: modelData.remainingPercent / 100
                    fillColor: modelData.remainingPercent === 0 ? Theme.Theme.red : Theme.Theme.popupFill
                    detail: (stale ? "Reset (stale) " : "Resets in ") + Logic.resetDuration(modelData.resetsAt, Services.AiUsageState.now)
                }
            }
        }
    }
}
