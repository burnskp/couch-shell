import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    visible: Services.NetworkState.available
    appearancePreset: Theme.WidgetStyles.metric
    popupPreset: Components.HoverPopupPresets.wifi
    popupWidth: 292
    iconGlyph: Services.NetworkState.iconGlyph
    valueText: Services.NetworkState.accessPointLabel
    maximumValueWidth: 120
    valueElideMode: Text.ElideRight
    valueTextColor: Services.NetworkState.connected && Services.NetworkState.isOpenNetwork ? Theme.Theme.peach : Theme.Theme.text
    popupContent: Component {
        Popups.WifiHover {}
    }
}
