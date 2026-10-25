import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    appearancePreset: Theme.WidgetStyles.metric
    popupPreset: Components.HoverPopupPresets.ram
    popupWidth: 292
    iconGlyph: ""
    valueText: Services.SystemStatsState.memoryAvailableLabel
    popupContent: Component {
        Popups.RamHover {}
    }
}
