pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../animations" as Animations
import "../../../theme" as Theme
import "../../../ui" as Ui

FocusScope {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool open: false
    readonly property bool shouldShow: newTaskAnimation.shouldShow

    signal closeRequested()

    function focusProject() {
        Qt.callLater(function() {
            projectDropdown.forceActiveFocus();
        });
    }

    function resetFields() {
        root.paneState.newTaskProject = root.paneState.defaultNewTaskProject();
        root.paneState.newTaskTitle = "";
        root.paneState.newTaskNotes = "";
    }

    function submit() {
        if (root.paneState.addTodo())
            root.closeRequested();
        else
            titleField.input.forceActiveFocus();
    }

    Keys.onEscapePressed: function(event) {
        root.closeRequested();
        event.accepted = true;
    }

    onOpenChanged: {
        if (open) {
            root.paneState.refreshProjects();
            root.resetFields();
            root.focusProject();
        }
    }

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Animations.AnimationSelector {
        id: newTaskAnimation

        anchors.centerIn: parent
        width: Math.min(440, Math.max(320, Math.round(parent.width * 0.34)))
        height: newTaskFrame.implicitHeight
        open: root.open
        openPreset: Animations.AnimationRegistry.smoke
        closePreset: Animations.AnimationRegistry.smoke
        openDuration: Animations.AnimationPresets.smokeDurationMs
        closeDuration: Animations.AnimationPresets.smokeDurationMs

        Ui.ShellPaneFrame {
            id: newTaskFrame

            width: parent.width
            implicitHeight: content.implicitHeight + (Theme.Theme.modulePadding * 2)
            style: root.shellStyle
            showAccentRail: false

            ColumnLayout {
                id: content

                anchors.fill: parent
                spacing: Theme.Theme.listGap + 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.Theme.listGap

                    Ui.ShellText {
                        Layout.fillWidth: true
                        role: "heading"
                        style: root.shellStyle
                        text: "New task"
                    }

                    Ui.ShellButton {
                        style: root.shellStyle
                        variant: "ghost"
                        text: "×"
                        enabled: !root.paneState.mutationBusy
                        onClicked: root.closeRequested()
                    }
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    role: "label"
                    style: root.shellStyle
                    text: "Project"
                }

                TodoProjectDropdown {
                    id: projectDropdown

                    Layout.fillWidth: true
                    shellStyle: root.shellStyle
                    paneState: root.paneState
                    onProjectSelected: titleField.input.forceActiveFocus()
                }

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
                    text: root.paneState.newTaskTitle
                    placeholderText: "Task title"
                    enabled: !root.paneState.mutationBusy
                    onTextChanged: if (text !== root.paneState.newTaskTitle) root.paneState.newTaskTitle = text
                    Keys.onReturnPressed: root.submit()
                    Keys.onEnterPressed: root.submit()
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
                    minimumHeight: 96
                    text: root.paneState.newTaskNotes
                    placeholderText: "Optional notes..."
                    enabled: !root.paneState.mutationBusy
                    onTextChanged: if (text !== root.paneState.newTaskNotes) root.paneState.newTaskNotes = text
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    visible: root.paneState.lastError.length > 0
                    role: "danger"
                    style: root.shellStyle
                    wrapMode: Text.Wrap
                    text: root.paneState.lastError
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
                        onClicked: root.closeRequested()
                    }

                    Ui.ShellButton {
                        style: root.shellStyle
                        variant: "accent"
                        text: root.paneState.mutationBusy ? "Adding…" : "Add"
                        enabled: root.paneState.newTaskProject.trim().length > 0 && root.paneState.newTaskTitle.trim().length > 0 && !root.paneState.mutationBusy
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
