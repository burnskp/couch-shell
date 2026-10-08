pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Ui.ShellSurface {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool confirmClear: false
    readonly property var completed: root.paneState.completedTodos()

    visible: root.paneState.loadingCompleted || root.completed.length > 0
    implicitHeight: visible ? content.implicitHeight + (padding * 2) : 0
    style: root.shellStyle
    tone: "input"
    padding: 8

    onCompletedChanged: if (root.completed.length === 0) root.confirmClear = false

    Connections {
        target: root.paneState
        function onScopeChanged() {
            root.confirmClear = false;
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: Theme.Theme.listGap

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Theme.listGap

            Ui.ShellText {
                Layout.fillWidth: true
                role: "muted"
                style: root.shellStyle
                text: `Completed (${root.completed.length})`
            }

            Ui.ShellButton {
                visible: root.completed.length > 0
                style: root.shellStyle
                variant: root.confirmClear ? "danger" : "ghost"
                text: root.confirmClear ? (root.paneState.isProjectScope() ? "confirm clear" : "confirm all") : "󰆴"
                enabled: !root.paneState.mutationBusy
                onClicked: {
                    if (root.confirmClear)
                        root.paneState.clearCompleted();
                    else
                        root.confirmClear = true;
                }
            }

            Ui.ShellButton {
                visible: root.confirmClear
                style: root.shellStyle
                variant: "ghost"
                text: "cancel"
                enabled: !root.paneState.mutationBusy
                onClicked: root.confirmClear = false
            }

            Ui.ShellButton {
                style: root.shellStyle
                variant: "ghost"
                text: root.paneState.completedOpen ? "⌄" : "›"
                enabled: root.completed.length > 0
                onClicked: root.paneState.completedOpen = !root.paneState.completedOpen
            }
        }

        Ui.ShellText {
            Layout.fillWidth: true
            visible: root.paneState.loadingCompleted && root.completed.length === 0
            role: "muted"
            style: root.shellStyle
            text: "Loading completed tasks…"
        }

        Repeater {
            model: root.paneState.completedOpen ? root.completed : []

            delegate: RowLayout {
                id: completedRow

                required property var modelData

                Layout.fillWidth: true
                spacing: Theme.Theme.listGap

                Ui.ShellText {
                    role: "muted"
                    style: root.shellStyle
                    text: "✓"
                }

                Ui.ShellText {
                    visible: !root.paneState.isProjectScope()
                    role: "label"
                    style: root.shellStyle
                    text: completedRow.modelData.project || completedRow.modelData.project_name || "project"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Ui.ShellText {
                        Layout.fillWidth: true
                        role: "muted"
                        style: root.shellStyle
                        text: completedRow.modelData.title || "Untitled task"
                        wrapMode: Text.Wrap
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        visible: (completedRow.modelData.notes || "").trim().length > 0
                        role: "muted"
                        style: root.shellStyle
                        text: (completedRow.modelData.notes || "").replace(/\n+/g, " ")
                        elide: Text.ElideRight
                    }
                }

                Ui.ShellButton {
                    style: root.shellStyle
                    variant: "ghost"
                    text: "restore"
                    enabled: !root.paneState.mutationBusy
                    onClicked: root.paneState.restoreTask(completedRow.modelData.id)
                }
            }
        }
    }
}
