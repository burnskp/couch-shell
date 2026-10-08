pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

FocusScope {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool expanded: false

    signal expandRequested()
    signal closeRequested()

    Keys.onEscapePressed: function(event) {
        if (root.paneState.addPopupOpen) {
            root.paneState.closeAddPopup();
            event.accepted = true;
            return;
        }

        if (root.paneState.expandedTodoId.length > 0) {
            root.paneState.expandedTodoId = "";
            event.accepted = true;
            return;
        }

        root.closeRequested();
        event.accepted = true;
    }

    function focusNewTask() {
        root.paneState.openAddPopup();
        Qt.callLater(function() {
            addProjectDropdown.forceActiveFocus();
        });
    }

    function submitNewTask() {
        const launched = root.paneState.addTodo();
        if (!launched)
            addTitleField.input.forceActiveFocus();
    }

    Keys.onPressed: function(event) {
        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_N) {
            root.focusNewTask();
            event.accepted = true;
            return;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.Theme.listGap + 4

        RowLayout {
            id: topBar

            Layout.fillWidth: true
            spacing: Theme.Theme.listGap
            z: 20

            TodoScopeDropdown {
                id: scopeDropdown

                Layout.preferredWidth: root.expanded ? 220 : 172
                shellStyle: root.shellStyle
                paneState: root.paneState
            }

            Item {
                Layout.fillWidth: true
            }

            Item {
                id: addTaskAnchor

                Layout.preferredWidth: addTaskButton.implicitWidth
                Layout.preferredHeight: addTaskButton.implicitHeight
                z: root.paneState.addPopupOpen ? 2000 : 0

                Ui.ShellButton {
                    id: addTaskButton

                    anchors.fill: parent
                    style: root.shellStyle
                    variant: root.paneState.addPopupOpen ? "accent" : "ghost"
                    text: root.expanded ? "+ Add Task" : "+"
                    enabled: !root.paneState.mutationBusy
                    onClicked: {
                        if (root.paneState.addPopupOpen)
                            root.paneState.closeAddPopup();
                        else
                            root.focusNewTask();
                    }
                }

                Ui.ShellSurface {
                    id: addTaskPopup

                    visible: root.paneState.addPopupOpen
                    z: 2000
                    x: Math.min(0, addTaskAnchor.width - width)
                    y: addTaskButton.height + Theme.Theme.listGap
                    width: root.expanded ? 360 : Math.min(320, Math.max(280, root.width - (Theme.Theme.modulePadding * 2)))
                    implicitHeight: addTaskColumn.implicitHeight + (padding * 2)
                    style: root.shellStyle
                    tone: "normal"
                    padding: Theme.Theme.modulePadding
                    emphasize: true

                    ColumnLayout {
                        id: addTaskColumn

                        anchors.fill: parent
                        spacing: Theme.Theme.listGap + 4

                        Ui.ShellText {
                            Layout.fillWidth: true
                            role: "heading"
                            style: root.shellStyle
                            text: "New task"
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            role: "label"
                            style: root.shellStyle
                            text: "Project"
                        }

                        TodoProjectDropdown {
                            id: addProjectDropdown

                            Layout.fillWidth: true
                            shellStyle: root.shellStyle
                            paneState: root.paneState
                            onProjectSelected: addTitleField.input.forceActiveFocus()
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            role: "label"
                            style: root.shellStyle
                            text: "Title"
                        }

                        Ui.ShellTextField {
                            id: addTitleField

                            Layout.fillWidth: true
                            style: root.shellStyle
                            text: root.paneState.newTaskTitle
                            placeholderText: "Task title"
                            enabled: !root.paneState.mutationBusy
                            onTextChanged: if (text !== root.paneState.newTaskTitle) root.paneState.newTaskTitle = text
                            Keys.onReturnPressed: root.submitNewTask()
                            Keys.onEnterPressed: root.submitNewTask()
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
                            minimumHeight: 72
                            text: root.paneState.newTaskNotes
                            placeholderText: "Optional notes..."
                            enabled: !root.paneState.mutationBusy
                            onTextChanged: if (text !== root.paneState.newTaskNotes) root.paneState.newTaskNotes = text
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.Theme.listGap

                            Item {
                                Layout.fillWidth: true
                            }

                            Ui.ShellButton {
                                style: root.shellStyle
                                variant: "ghost"
                                text: "Cancel"
                                enabled: !root.paneState.mutationBusy
                                onClicked: root.paneState.closeAddPopup()
                            }

                            Ui.ShellButton {
                                style: root.shellStyle
                                variant: "accent"
                                text: "Add"
                                enabled: root.paneState.newTaskProject.trim().length > 0 && root.paneState.newTaskTitle.trim().length > 0 && !root.paneState.mutationBusy
                                onClicked: root.submitNewTask()
                            }
                        }
                    }
                }
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "ghost"
                text: root.expanded ? "↙" : "⤢"
                onClicked: root.expandRequested()
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "ghost"
                text: "×"
                onClicked: root.closeRequested()
            }
        }

        Ui.ShellDivider {
            style: root.shellStyle
            z: 0
        }

        Item {
            id: listArea

            Layout.fillWidth: true
            Layout.fillHeight: true
            z: 0

            Flickable {
                id: todosFlickable

                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: listColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: listColumn

                    width: todosFlickable.width
                    spacing: Theme.Theme.listGap

                    Ui.ShellSurface {
                        Layout.fillWidth: true
                        visible: root.paneState.loading || root.paneState.mutationBusy || root.paneState.lastError.length > 0
                        style: root.shellStyle
                        tone: root.paneState.lastError.length > 0 ? "accent" : "input"
                        padding: 8
                        implicitHeight: statusText.implicitHeight + (padding * 2)

                        Ui.ShellText {
                            id: statusText

                            anchors.fill: parent
                            role: root.paneState.lastError.length > 0 ? "danger" : "muted"
                            style: root.shellStyle
                            wrapMode: Text.Wrap
                            text: root.paneState.lastError.length > 0 ? root.paneState.lastError : (root.paneState.mutationBusy ? "Updating tasks…" : "Loading tasks…")
                        }
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        visible: !root.paneState.loading && root.paneState.lastError.length === 0 && root.paneState.visibleTodos().length === 0
                        role: "muted"
                        style: root.shellStyle
                        horizontalAlignment: Text.AlignHCenter
                        text: root.paneState.isProjectScope() ? "No pending tasks in this project." : "No pending tasks. Add one to inbox."
                    }

                    Repeater {
                        model: root.paneState.visibleTodos()

                        delegate: TodoRow {
                            id: todoDelegate

                            required property var modelData

                            Layout.fillWidth: true
                            shellStyle: root.shellStyle
                            paneState: root.paneState
                            todo: todoDelegate.modelData
                            dragLayer: dragLayer
                        }
                    }

                    CompletedSection {
                        Layout.fillWidth: true
                        shellStyle: root.shellStyle
                        paneState: root.paneState
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        visible: root.expanded
                        role: "muted"
                        style: root.shellStyle
                        text: `${root.paneState.visibleTodos().length} active tasks • ${root.paneState.completedTodos().length} completed`
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Item {
                id: dragLayer

                anchors.fill: parent
                z: 100
            }
        }
    }

}
