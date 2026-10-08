pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

FocusScope {
    id: root

    required property var model
    property var shellStyle: Ui.ShellStyle.segmented
    property string value: ""
    property string placeholderText: "Select project"
    property string loadingText: "Projects…"
    property string noticeText: ""
    property bool loading: false
    property bool open: false
    property int highlightedIndex: -1

    signal selected(string value)

    function currentIndex() {
        return root.model.indexOf(root.value);
    }

    function openMenu() {
        if (root.loading)
            return;

        root.highlightedIndex = Math.max(0, root.currentIndex());
        root.open = true;
        root.forceActiveFocus();
        Qt.callLater(root.ensureHighlightedVisible);
    }

    function closeMenu() {
        root.open = false;
    }

    function selectIndex(index) {
        if (index < 0 || index >= root.model.length)
            return;

        const selectedValue = String(root.model[index]);
        root.value = selectedValue;
        root.open = false;
        root.selected(selectedValue);
    }

    function moveHighlight(offset) {
        if (!root.open) {
            root.openMenu();
            return;
        }

        const count = root.model.length;
        if (count === 0)
            return;

        root.highlightedIndex = (root.highlightedIndex + offset + count) % count;
        root.ensureHighlightedVisible();
    }

    function ensureHighlightedVisible() {
        const item = optionRepeater.itemAt(root.highlightedIndex);
        if (!item)
            return;

        if (item.y < optionsFlickable.contentY)
            optionsFlickable.contentY = item.y;
        else if (item.y + item.height > optionsFlickable.contentY + optionsFlickable.height)
            optionsFlickable.contentY = item.y + item.height - optionsFlickable.height;
    }

    implicitWidth: 172
    implicitHeight: trigger.implicitHeight
    activeFocusOnTab: enabled
    z: open ? 1000 : 0
    containmentMask: Item {
        width: root.width
        height: root.open ? trigger.height + Theme.Theme.listGap + menu.height : trigger.height
    }

    onActiveFocusChanged: if (!activeFocus) root.closeMenu()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape && root.open) {
            root.closeMenu();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Down) {
            root.moveHighlight(1);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Up) {
            root.moveHighlight(-1);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.open)
                root.selectIndex(root.highlightedIndex);
            else
                root.openMenu();
            event.accepted = true;
        }
    }

    Ui.ShellButton {
        id: trigger

        anchors.left: parent.left
        anchors.right: parent.right
        style: root.shellStyle
        variant: root.open || root.activeFocus ? "accent" : "default"
        text: root.loading ? root.loadingText : `${root.value.length > 0 ? root.value : root.placeholderText} ▾`
        enabled: root.enabled && !root.loading
        onClicked: {
            root.forceActiveFocus();
            if (root.open)
                root.closeMenu();
            else
                root.openMenu();
        }
    }

    Ui.ShellSurface {
        id: menu

        visible: root.open
        z: 1000
        y: trigger.height + Theme.Theme.listGap
        width: parent.width
        height: Math.min(implicitHeight, 320)
        implicitHeight: optionsColumn.implicitHeight + (padding * 2)
        style: root.shellStyle
        tone: "normal"
        padding: Theme.Theme.listGap
        emphasize: true

        Flickable {
            id: optionsFlickable

            anchors.fill: parent
            anchors.margins: menu.padding
            contentWidth: width
            contentHeight: optionsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: optionsColumn

                width: optionsFlickable.width
                spacing: Theme.Theme.listGap

                Ui.ShellText {
                    Layout.fillWidth: true
                    visible: root.noticeText.length > 0
                    role: "muted"
                    style: root.shellStyle
                    text: root.noticeText
                }

                Repeater {
                    id: optionRepeater

                    model: root.model

                    delegate: Ui.ShellButton {
                        required property int index
                        required property string modelData

                        Layout.fillWidth: true
                        style: root.shellStyle
                        variant: modelData === root.value || index === root.highlightedIndex ? "accent" : "ghost"
                        text: modelData
                        onClicked: root.selectIndex(index)
                    }
                }
            }
        }
    }
}
