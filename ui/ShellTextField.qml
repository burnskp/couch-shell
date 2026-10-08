import QtQuick
import "../theme" as Theme

Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholderText: ""
    property string fontFamily: Theme.Theme.proseFontFamily
    property var style: ({})
    property bool hovered: fieldMouseArea.containsMouse

    color: input.activeFocus ? (root.style.inputBackgroundActive || Theme.Theme.inputBackgroundActive) : (root.style.inputBackground || Theme.Theme.inputBackground)
    radius: 0
    border.width: 1
    border.color: input.activeFocus ? (root.style.focusBorder || Theme.Theme.focusBorder) : (root.style.borderColor || Theme.Theme.surfaceBorder)
    implicitHeight: root.style.controlHeight || Theme.Theme.controlHeight

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: input.activeFocus ? (root.style.inputFocusRailWidth || root.style.accentRailWidth || 0) : 0
        color: root.style.focusBorder || Theme.Theme.focusBorder
        visible: width > 0
        radius: 0
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: root.style.fieldHorizontalPadding || Theme.Theme.modulePadding
        anchors.rightMargin: root.style.fieldHorizontalPadding || Theme.Theme.modulePadding
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        color: root.style.textColor || Theme.Theme.text
        font.family: root.fontFamily
        font.pixelSize: root.style.fontSize || Theme.Theme.fontSize
        font.weight: Theme.Theme.fontWeight
        selectionColor: root.style.inputSelection || Theme.Theme.inputSelection
        selectedTextColor: root.style.textColor || Theme.Theme.text
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        activeFocusOnTab: true
    }

    ShellText {
        anchors.fill: input
        role: "muted"
        style: root.style
        text: root.placeholderText
        visible: input.text.length === 0
        verticalAlignment: Text.AlignVCenter
        font.family: root.fontFamily
    }

    MouseArea {
        id: fieldMouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onPressed: function(mouse) {
            mouse.accepted = false;
            input.forceActiveFocus();
        }
    }
}
