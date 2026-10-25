import QtQuick
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    id: root
    property var barScreen: null

    iconGlyph: "󰚩"
    valueText: Services.AiUsageState.summary.text
    tone: Services.AiUsageState.summary.exhausted ? Theme.WidgetStyles.toneWarning : Theme.WidgetStyles.toneNormal
    interactive: true
    popupKey: "ai-usage"
    popupWidth: 292
    popupContent: Component { Popups.AiUsageHover {} }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Services.AiUsageState.selectNext();
    }
}
