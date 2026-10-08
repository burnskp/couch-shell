pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Ui.ShellSurface {
    id: root

    required property var paneState
    required property var todo
    property var shellStyle: Ui.ShellStyle.segmented
    property string draftTitle: ""
    property string draftNotes: ""
    readonly property bool dirty: root.todo && (root.draftTitle !== (root.todo.title || "") || root.draftNotes !== (root.todo.notes || ""))

    function resetDrafts() {
        root.draftTitle = root.todo ? (root.todo.title || "") : "";
        root.draftNotes = root.todo ? (root.todo.notes || "") : "";
    }

    function saveDrafts() {
        if (!root.todo)
            return;

        if (root.paneState.updateTask(root.todo.id, root.draftTitle, root.draftNotes))
            titleField.input.forceActiveFocus();
    }

    implicitHeight: editorColumn.implicitHeight + (padding * 2)
    style: root.shellStyle
    tone: "accent"
    padding: Theme.Theme.modulePadding
    emphasize: true

    onTodoChanged: root.resetDrafts()
    onVisibleChanged: if (visible) root.resetDrafts()
    Component.onCompleted: root.resetDrafts()

    ColumnLayout {
        id: editorColumn

        anchors.fill: parent
        spacing: Theme.Theme.listGap + 4

        Ui.ShellText {
            Layout.fillWidth: true
            role: "label"
            style: root.shellStyle
            text: "Title"
        }

        Ui.ShellTextField {
            id: titleField

            Layout.fillWidth: true
            style: root.shellStyle
            text: root.draftTitle
            placeholderText: "Task title"
            enabled: !root.paneState.mutationBusy
            onTextChanged: if (text !== root.draftTitle) root.draftTitle = text
            Keys.onReturnPressed: root.saveDrafts()
            Keys.onEnterPressed: root.saveDrafts()
        }

        Ui.ShellText {
            Layout.fillWidth: true
            role: "label"
            style: root.shellStyle
            text: "Notes"
        }

        Ui.ShellTextArea {
            Layout.fillWidth: true
            style: root.shellStyle
            minimumHeight: 70
            text: root.draftNotes
            placeholderText: "Add notes..."
            enabled: !root.paneState.mutationBusy
            onTextChanged: if (text !== root.draftNotes) root.draftNotes = text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.listGap

            Ui.ShellButton {
                style: root.shellStyle
                variant: root.paneState.canMoveTodo(root.todo.id, "up") ? "ghost" : "default"
                text: "↑"
                enabled: root.paneState.canMoveTodo(root.todo.id, "up")
                onClicked: root.paneState.moveTodo(root.todo.id, "up")
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: root.paneState.canMoveTodo(root.todo.id, "down") ? "ghost" : "default"
                text: "↓"
                enabled: root.paneState.canMoveTodo(root.todo.id, "down")
                onClicked: root.paneState.moveTodo(root.todo.id, "down")
            }

            Item {
                Layout.fillWidth: true
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "ghost"
                text: "Cancel"
                enabled: root.dirty && !root.paneState.mutationBusy
                onClicked: root.resetDrafts()
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "accent"
                text: "Save"
                enabled: root.dirty && root.draftTitle.trim().length > 0 && !root.paneState.mutationBusy
                onClicked: root.saveDrafts()
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "accent"
                text: "✓ Done"
                enabled: !root.paneState.mutationBusy
                onClicked: root.paneState.completeTask(root.todo.id)
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "danger"
                text: "trash"
                enabled: !root.paneState.mutationBusy
                onClicked: root.paneState.deleteTask(root.todo.id)
            }
        }
    }
}
