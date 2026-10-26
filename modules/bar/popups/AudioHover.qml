pragma ComponentBehavior: Bound

import QtQuick
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    readonly property bool hasActiveStreams: Services.AudioState.activeStreams.length > 0
    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

    FontMetrics {
        id: valueMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }

    Components.HoverPopupMeterRow {
        label: "Output"
        valueColumnWidth: Math.ceil(valueMetrics.advanceWidth("Muted"))
        valueText: Services.AudioState.muted ? "Muted" : Services.AudioState.volumePercent + "%"
        barValue: Services.AudioState.muted ? 0 : Services.AudioState.volumePercent / 100
        detail: Services.AudioState.outputName
    }

    Components.HoverPopupMeterRow {
        label: "Input"
        valueColumnWidth: Math.ceil(valueMetrics.advanceWidth("Muted"))
        valueText: Services.AudioState.inputMuted ? "Muted" : Services.AudioState.inputVolumePercent + "%"
        barValue: Services.AudioState.inputMuted ? 0 : Services.AudioState.inputVolumePercent / 100
        detail: Services.AudioState.inputName
    }

    Components.HoverPopupDivider {
        visible: root.hasActiveStreams
    }

    Repeater {
        model: Services.AudioState.activeStreams

        delegate: Components.HoverPopupMeterRow {
            required property var modelData

            label: modelData.title
            showBar: false
            detail: modelData.subtitle
        }
    }
}
