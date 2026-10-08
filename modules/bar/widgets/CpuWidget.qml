import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    id: root

    readonly property real valueWidth: cpuValueMetrics.advanceWidth("0000")

    appearancePreset: Theme.WidgetStyles.metric
    popupPreset: Components.HoverPopupPresets.cpu
    popupWidth: 292
    iconGlyph: Services.PowerProfileState.iconGlyph
    valueText: Services.SystemStatsState.cpuUsageLabel
    preferredValueWidth: root.valueWidth
    valueHorizontalAlignment: Text.AlignRight
    interactive: Services.PowerProfileState.available
    onClicked: Services.PowerProfileState.cycleProfile()
    popupContent: Component {
        Popups.CpuHover {}
    }

    FontMetrics {
        id: cpuValueMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }
}
