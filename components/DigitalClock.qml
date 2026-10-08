pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "." as Components
import "../modules/bar/popups" as Popups
import "../theme" as Theme

WidgetChip {
    id: root

    appearancePreset: Theme.WidgetStyles.clock
    popupPreset: Components.HoverPopupPresets.calendar
    popupWidth: 292
    iconGlyph: "󰥔"
    popupContent: calendarHover
    valueText: root.visibleClockText

    readonly property date clockDate: clock.date
    readonly property string formattedClockText: Qt.formatDateTime(clock.date, "h:mm ap")
    readonly property string visibleClockText: formattedClockText.slice(0, -3)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }


    Component {
        id: calendarHover

        Popups.ClockHover {
            displayDate: root.clockDate
        }
    }
}
