import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

// Flat hover popup row: [icon | label | metric bar | value] with an optional detail line.
// Without a bar the label takes the free width so longer names and values still fit.
ColumnLayout {
    id: root

    property string iconText: ""
    property color iconColor: Theme.Theme.popupIcon
    property string label: ""
    property int labelElide: Text.ElideRight
    property string valueText: ""
    property bool showBar: true
    property real barValue: 0
    property color fillColor: Theme.Theme.popupFill
    property color trackColor: Theme.Theme.popupTrack
    property string detail: ""
    property bool detailWrap: false
    property int rowHeight: 28
    property int columnSpacing: Theme.Theme.listGap
    property int iconColumnWidth: 22
    property int labelColumnWidth: 52
    // Fits the widest percentage so the value sits close to the bar.
    property int valueColumnWidth: Math.ceil(valueMetrics.advanceWidth("100%"))
    readonly property int detailIndent: root.iconColumnWidth > 0 ? root.iconColumnWidth + root.columnSpacing : 0

    Layout.fillWidth: true
    spacing: 0

    FontMetrics {
        id: valueMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight
        spacing: root.columnSpacing

        Text {
            visible: root.iconColumnWidth > 0
            Layout.preferredWidth: root.iconColumnWidth
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.iconText
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize + 6
            font.weight: Font.Bold
            color: root.iconColor
        }

        Text {
            Layout.fillWidth: !root.showBar
            Layout.preferredWidth: root.labelColumnWidth
            Layout.minimumWidth: root.showBar ? root.labelColumnWidth : 0
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            textFormat: Text.PlainText
            elide: root.labelElide
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize
            font.weight: Font.Bold
            color: Theme.Theme.popupLabel
        }

        HoverPopupMetricBar {
            visible: root.showBar
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            value: root.barValue
            fillColor: root.fillColor
            trackColor: root.trackColor
        }

        Text {
            Layout.preferredWidth: Math.max(root.valueColumnWidth, implicitWidth)
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: root.valueText
            textFormat: Text.PlainText
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize
            font.weight: Font.Bold
            color: Theme.Theme.popupValue
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: root.detailIndent
        visible: root.detail.length > 0
        text: root.detail
        textFormat: Text.PlainText
        elide: root.detailWrap ? Text.ElideNone : Text.ElideRight
        wrapMode: root.detailWrap ? Text.WordWrap : Text.NoWrap
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Font.Bold
        color: Theme.Theme.popupValue
    }
}
