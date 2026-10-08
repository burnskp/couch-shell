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

    contentSpacing: 6
    minPopupWidth: 275

    Components.HoverPopupCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Today"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: popup.weekdayText
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }
        }

        Text {
            Layout.fillWidth: true
            text: popup.longDateText
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize - 1
            font.weight: Font.Bold
            color: Theme.Theme.subtext0
        }
    }

    Components.HoverPopupCard {
        contentSpacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Calendar"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: popup.monthYearText
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.subtext0
            }
        }

        GridLayout {
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
                    color: Theme.Theme.subtext1
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
                    color: dayCell.modelData.isToday ? Theme.Theme.mauve : Theme.Theme.transparent

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.modelData.inMonth ? dayCell.modelData.dayNumber.toString() : ""
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize - 1
                        font.weight: Font.Bold
                        color: dayCell.modelData.isToday ? Theme.Theme.crust : Theme.Theme.subtext0
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
