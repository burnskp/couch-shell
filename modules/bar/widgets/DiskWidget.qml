import QtQuick
import "../../../services/SystemStatsBtrfs.js" as Btrfs
import "../popups" as Popups
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../components" as Components

Components.WidgetChip {
    appearancePreset: Theme.WidgetStyles.metric
    tone: Services.SystemStatsState.diskSeverity === 2 ? Theme.WidgetStyles.toneWarning : Services.SystemStatsState.diskSeverity === 1 ? Theme.WidgetStyles.toneCaution : Theme.WidgetStyles.toneNormal
    iconGlyph: "󰋊"
    valueText: Services.SystemStatsState.diskAvailableLabel
    popupKey: "disk"
    popupWidth: 320
    popupContent: Btrfs.popupEnabled(Services.ShellConfig.barDiskBtrfsEnabled, Services.ShellConfig.barDiskPopupPaths) ? diskPopup : null

    Component {
        id: diskPopup
        Popups.DiskHover {}
    }
}
