import QtQuick
import "../../services" as Services
import "../../theme" as Theme

Rectangle {
    id: root

    property color surfaceColor: Theme.Theme.barSurface
    property color accentColor: Theme.Theme.barAccent
    property string styleVariant: "default"
    property string badgeText: ">"
    property string placeholderText: ""
    property alias textInput: textInput
    readonly property int badgeWidth: root.styleVariant === "utility" ? 28 : root.styleVariant === "files" ? 34 : 30
    readonly property int textLeftMargin: root.badgeWidth + Theme.Theme.listGap + 8

    signal escapePressed

    implicitHeight: 40
    color: root.surfaceColor
    radius: 0
    border.width: 1
    border.color: textInput.activeFocus ? Qt.alpha(root.accentColor, 0.8) : Qt.alpha(root.accentColor, 0.22)

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.badgeWidth
        color: root.accentColor
        radius: 0

        Text {
            anchors.centerIn: parent
            text: root.badgeText
            font.family: Theme.Theme.fontFamily
            font.pixelSize: root.styleVariant === "files" ? Theme.Theme.fontSize - 2 : Theme.Theme.fontSize - 1
            font.weight: Font.Bold
            color: Theme.Theme.barBackground
        }
    }

    TextInput {
        id: textInput

        anchors.fill: parent
        anchors.leftMargin: root.textLeftMargin
        anchors.rightMargin: Theme.Theme.modulePadding
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        text: Services.PickerService.query
        color: Theme.Theme.text
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Font.Bold
        selectionColor: Theme.Theme.barAccent
        selectedTextColor: Theme.Theme.barBackground
        clip: true
        onTextChanged: Services.PickerService.query = text
        Keys.onEscapePressed: event => {
            root.escapePressed();
            event.accepted = true;
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.textLeftMargin
        text: root.placeholderText
        visible: textInput.text.length === 0
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: Theme.Theme.fontWeight
        color: Theme.Theme.subtext0
    }
}
