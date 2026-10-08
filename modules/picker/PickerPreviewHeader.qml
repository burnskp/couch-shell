import QtQuick
import QtQuick.Layouts
import "../../theme" as Theme

ColumnLayout {
    id: root

    property string title: ""
    property color accentColor: Theme.Theme.barAccent
    property bool showHeader: true
    property bool showDivider: true

    Layout.fillWidth: true
    visible: root.showHeader
    spacing: 4

    Text {
        Layout.fillWidth: true
        text: root.title
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
        color: Theme.Theme.text
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        visible: root.showDivider
        color: Qt.alpha(root.accentColor, 0.45)
    }
}
