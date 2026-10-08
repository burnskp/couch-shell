import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property var style: ({})
    property int labelColumnWidth: 0
    property string valueRole: "value"

    Layout.fillWidth: true
    spacing: root.style.controlSpacing || 8

    ShellText {
        Layout.preferredWidth: root.labelColumnWidth
        Layout.minimumWidth: root.labelColumnWidth
        visible: root.label.length > 0 || root.labelColumnWidth > 0
        role: "label"
        style: root.style
        text: root.label
    }

    Item {
        Layout.fillWidth: true
    }

    ShellText {
        Layout.alignment: Qt.AlignRight
        role: root.valueRole
        style: root.style
        text: root.value
        horizontalAlignment: Text.AlignRight
    }
}
