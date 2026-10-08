import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    id: root

    readonly property real valueWidth: audioValueMetrics.advanceWidth("0000")

    appearancePreset: Theme.WidgetStyles.toggle
    popupPreset: Components.HoverPopupPresets.audio
    popupWidth: 292
    iconGlyph: Services.AudioState.iconGlyph
    valueText: Services.AudioState.label
    preferredValueWidth: root.valueWidth
    valueHorizontalAlignment: Text.AlignRight
    interactive: true
    onClicked: Services.AudioState.toggleMute()
    popupContent: Component {
        Popups.AudioHover {}
    }

    FontMetrics {
        id: audioValueMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }
}
