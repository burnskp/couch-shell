pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: popup

    required property date displayDate

    readonly property date monthStart: new Date(displayDate.getFullYear(), displayDate.getMonth(), 1)
    readonly property int firstDayOffset: monthStart.getDay()
    readonly property int daysInMonth: new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 0).getDate()
    readonly property int weekCount: Math.ceil((firstDayOffset + daysInMonth) / 7)
    readonly property var dayLabels: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    readonly property string weekdayText: Qt.formatDateTime(popup.displayDate, "dddd")
    readonly property string longDateText: Qt.formatDateTime(popup.displayDate, "MMMM d, yyyy")
    readonly property string monthYearText: Qt.formatDateTime(popup.displayDate, "MMMM yyyy")
    readonly property var calendarCells: {
        const cells = [];

        for (let index = 0; index < weekCount * 7; index += 1) {
            const dayNumber = index - firstDayOffset + 1;
            cells.push({
                "dayNumber": dayNumber,
                "inMonth": dayNumber >= 1 && dayNumber <= daysInMonth,
                "isToday": dayNumber === displayDate.getDate()
            });
        }

        return cells;
    }

    contentSpacing: Theme.Theme.listGap + 2
    minPopupWidth: 275

    Components.HoverPopupMeterRow {
        label: "Today"
        valueText: popup.weekdayText
        showBar: false
        detail: popup.longDateText
    }

    Components.HoverPopupDivider {}

    Components.HoverPopupMeterRow {
        label: "Calendar"
        valueText: popup.monthYearText
        showBar: false
    }

    GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 7
        columnSpacing: 4
        rowSpacing: 4

        Repeater {
            model: popup.dayLabels

            delegate: Text {
                required property string modelData

                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.popupLabel
            }
        }

        Repeater {
            model: popup.calendarCells

            delegate: Rectangle {
                id: dayCell

                required property var modelData

                Layout.preferredWidth: 30
                Layout.preferredHeight: 24
                radius: 0
                color: dayCell.modelData.isToday ? Theme.Theme.popupFill : Theme.Theme.transparent

                Text {
                    anchors.centerIn: parent
                    text: dayCell.modelData.inMonth ? dayCell.modelData.dayNumber.toString() : ""
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize - 1
                    font.weight: Font.Bold
                    color: dayCell.modelData.isToday ? Theme.Theme.crust : Theme.Theme.popupValue
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
