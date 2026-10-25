import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

RowLayout {
    id: root

    property int pid: 0
    property string command: ""
    property string metricText: ""
    readonly property string pidText: root.pid > 0 ? root.pid.toString() : "--"
    readonly property int pidColumnDigits: 6
    readonly property bool pidUsesSingleSeparator: root.pidText.length > root.pidColumnDigits

    Layout.fillWidth: true
    spacing: 0

    FontMetrics {
        id: fontMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Font.Bold
    }

    Text {
        Layout.preferredWidth: fontMetrics.advanceWidth("0".repeat(root.pidColumnDigits))
        Layout.minimumWidth: Layout.preferredWidth
        text: root.pidText
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Font.Bold
        color: Theme.Theme.popupLabel
    }

    Item {
        Layout.preferredWidth: fontMetrics.advanceWidth(root.pidUsesSingleSeparator ? " " : "  ")
        Layout.minimumWidth: Layout.preferredWidth
    }

    Text {
        Layout.fillWidth: true
        text: root.command
        clip: true
        wrapMode: Text.NoWrap
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Font.Bold
        color: Theme.Theme.popupLabel
    }

    Text {
        Layout.leftMargin: 8
        Layout.alignment: Qt.AlignRight
        text: root.metricText || ""
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Font.Bold
        color: Theme.Theme.popupValue
    }
}
