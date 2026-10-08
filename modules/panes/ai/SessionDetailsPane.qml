pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Item {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property int headingRightInset: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.Theme.listGap + 4

        RowLayout {
            Layout.fillWidth: true

            Ui.ShellText {
                Layout.fillWidth: true
                text: "Session Details"
                role: "heading"
                style: root.shellStyle
                elide: Text.ElideRight
            }

            Item {
                Layout.preferredWidth: root.headingRightInset
                Layout.preferredHeight: 1
                visible: root.headingRightInset > 0
            }
        }

        Ui.ShellSection {
            Layout.fillWidth: true
            title: root.paneState.activeSession ? root.paneState.activeSession.title : ""
            style: root.shellStyle

            Ui.ShellText {
                Layout.fillWidth: true
                text: "Updated · " + (root.paneState.activeSession ? root.paneState.activeSession.updatedLabel : "")
                role: "muted"
                style: root.shellStyle
                wrapMode: Text.Wrap
            }

            Ui.ShellText {
                Layout.fillWidth: true
                text: "Model · " + (root.paneState.activeEngine ? root.paneState.activeEngine.label : "")
                role: "muted"
                style: root.shellStyle
                wrapMode: Text.Wrap
            }
        }

        Ui.ShellSection {
            Layout.fillWidth: true
            title: "Files"
            summary: root.paneState.activeSession && root.paneState.activeSession.files ? String(root.paneState.activeSession.files.length) : "0"
            style: root.shellStyle
            visible: !!(root.paneState.activeSession && root.paneState.activeSession.files && root.paneState.activeSession.files.length > 0)

            Repeater {
                model: root.paneState.activeSession ? root.paneState.activeSession.files : []

                delegate: Ui.ShellSurface {
                    id: detailsFileRow

                    required property var modelData
                    Layout.fillWidth: true
                    style: root.shellStyle
                    tone: "subtle"
                    padding: Theme.Theme.moduleValuePadding + 3
                    implicitHeight: fileMeta.implicitHeight + (padding * 2)

                    ColumnLayout {
                        id: fileMeta

                        parent: detailsFileRow.contentItem
                        anchors.fill: parent
                        spacing: 1

                        Ui.ShellText {
                            text: detailsFileRow.modelData.name
                            style: root.shellStyle
                            elide: Text.ElideRight
                        }

                        Ui.ShellText {
                            text: detailsFileRow.modelData.detail || "Attached"
                            role: "muted"
                            style: root.shellStyle
                        }
                    }
                }
            }
        }

        Ui.ShellSection {
            Layout.fillWidth: true
            title: "Notes"
            style: root.shellStyle
            visible: !!(root.paneState.activeSession && root.paneState.activeSession.notes && root.paneState.activeSession.notes.length > 0)

            Ui.ShellText {
                Layout.fillWidth: true
                text: root.paneState.activeSession ? root.paneState.activeSession.notes : ""
                role: "muted"
                style: root.shellStyle
                wrapMode: Text.Wrap
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
