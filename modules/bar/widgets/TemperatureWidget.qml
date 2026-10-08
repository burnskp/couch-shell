import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    id: root

    readonly property real valueWidth: temperatureValueMetrics.advanceWidth("000 °C")

    visible: Services.ShellConfig.barTemperatureEnabled
    appearancePreset: Theme.WidgetStyles.metric
    popupWidth: 292
    iconGlyph: ""
    valueText: Services.SystemStatsState.primaryTemperatureLabel
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
