import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    id: root

    readonly property string valueTemplate: "0".repeat(Services.ShellConfig.barTemperatureDigits) + (Services.ShellConfig.barTemperatureShowUnit ? " °C" : "")
    // Never reserve less than the "Unk" fallback so it does not overflow into the icon.
    readonly property real valueWidth: Math.max(temperatureValueMetrics.advanceWidth(root.valueTemplate), temperatureValueMetrics.advanceWidth("Unk"))

    appearancePreset: Theme.WidgetStyles.metric
    popupWidth: 292
    iconGlyph: ""
    valueText: Services.SystemStatsState.formatTemperature(Services.SystemStatsState.primaryTemperatureC, Services.ShellConfig.barTemperatureShowUnit)
    preferredValueWidth: root.valueWidth
    valueHorizontalAlignment: Text.AlignRight
    popupContent: Component {
        Popups.TemperatureHover {}
    }

    FontMetrics {
        id: temperatureValueMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }
}
