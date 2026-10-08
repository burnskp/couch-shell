import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    property alias text: editor.text
    property alias editor: editor
    property string placeholderText: ""
    property string fontFamily: Theme.Theme.proseFontFamily
    property var style: ({})
    property int minimumHeight: 120

    color: editor.activeFocus ? (root.style.inputBackgroundActive || Theme.Theme.inputBackgroundActive) : (root.style.inputBackground || Theme.Theme.inputBackground)
    radius: 0
    border.width: 1
    border.color: editor.activeFocus ? (root.style.focusBorder || Theme.Theme.focusBorder) : (root.style.borderColor || Theme.Theme.surfaceBorder)
    implicitHeight: Math.max(root.minimumHeight, editor.contentHeight + ((root.style.sectionPadding || 6) * 2))

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: editor.activeFocus ? (root.style.inputFocusRailWidth || root.style.accentRailWidth || 0) : 0
        color: root.style.focusBorder || Theme.Theme.focusBorder
        visible: width > 0
        radius: 0
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        anchors.margins: root.style.sectionPadding || 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: editor.contentHeight

        TextEdit {
            id: editor

            width: flickable.width
            height: Math.max(contentHeight, root.minimumHeight - ((root.style.sectionPadding || 6) * 2))
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            selectByKeyboard: true
            persistentSelection: true
            color: root.style.textColor || Theme.Theme.text
            font.family: root.fontFamily
            font.pixelSize: root.style.fontSize || Theme.Theme.fontSize
            font.weight: Theme.Theme.fontWeight
            selectionColor: root.style.inputSelection || Theme.Theme.inputSelection
            selectedTextColor: root.style.textColor || Theme.Theme.text
            activeFocusOnTab: true
        }
    }

    ShellText {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.style.sectionPadding || 6
        role: "muted"
        style: root.style
        text: root.placeholderText
        visible: editor.text.length === 0
        font.family: root.fontFamily
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        onPressed: function(mouse) {
            mouse.accepted = false;
            editor.forceActiveFocus();
        }
    }
}
