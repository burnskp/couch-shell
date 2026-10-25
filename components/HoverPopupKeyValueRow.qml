import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property int labelColumnWidth: 0
    property int labelElide: Text.ElideNone
    property bool centerValueWhenLabelEmpty: false
    property bool valueWrap: false
    property int labelAlignment: Qt.AlignVCenter
    property int valueAlignment: Qt.AlignVCenter | Qt.AlignRight
    property int labelPixelSize: Theme.Theme.fontSize - 1
    property int valuePixelSize: Theme.Theme.fontSize

    Layout.fillWidth: true
    spacing: 8

    Text {
        Layout.preferredWidth: root.labelColumnWidth
        Layout.minimumWidth: root.labelColumnWidth
        Layout.alignment: root.labelAlignment
        visible: root.label.length > 0 || root.labelColumnWidth > 0
        text: root.label
        textFormat: Text.PlainText
        elide: root.labelElide
        font.family: Theme.Theme.fontFamily
        font.pixelSize: root.labelPixelSize
        font.weight: Font.Bold
        color: Theme.Theme.popupLabel
    }

    Item {
        Layout.fillWidth: true
        visible: !root.centerValueWhenLabelEmpty || root.label.length > 0
    }

    Text {
        Layout.fillWidth: true
        Layout.alignment: root.centerValueWhenLabelEmpty && root.label.length === 0 ? Qt.AlignCenter : root.valueAlignment
        text: root.value
        textFormat: Text.PlainText
        wrapMode: root.valueWrap ? Text.Wrap : Text.NoWrap
        horizontalAlignment: root.centerValueWhenLabelEmpty && root.label.length === 0 ? Text.AlignHCenter : Text.AlignRight
        font.family: Theme.Theme.fontFamily
        font.pixelSize: root.valuePixelSize
        font.weight: Font.Bold
        color: Theme.Theme.popupValue
    }
}
