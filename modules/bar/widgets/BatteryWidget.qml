import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    visible: Services.BatteryState.ready
    appearancePreset: Theme.WidgetStyles.metric
    tone: Services.BatteryState.lowCritical ? Theme.WidgetStyles.toneWarning : Services.BatteryState.lowWarning ? Theme.WidgetStyles.toneCaution : Theme.WidgetStyles.toneNormal
    popupPreset: Components.HoverPopupPresets.battery
    popupWidth: 292
    iconGlyph: Services.BatteryState.iconGlyph
    valueText: Services.BatteryState.label
    popupContent: Component {
        Popups.BatteryHover {}
    }
}
