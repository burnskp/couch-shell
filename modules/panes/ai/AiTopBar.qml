pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Ui.ShellSurface {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool sessionsChecked: root.paneState.sessionsPopoverOpen
    property bool showSessionsButton: true
    property bool detailsChecked: false
    property bool showDetailsButton: false
    property bool showExpandButton: true
    property bool showCollapseButton: false
    property bool showCloseButton: false
    property string newChatText: "󰐕"
    property string settingsText: "󰒓"
    property string sessionsText: "󰋚"
    property string detailsText: "󰋼"
    property string expandText: "󰘖"
    property string collapseText: "󰘕"
    property string closeText: "󰅖"
    readonly property int iconButtonPadding: Theme.Theme.moduleValuePadding + 5
    readonly property int iconButtonWidth: Theme.Theme.controlHeight + 8
    signal sessionsRequested()
    signal detailsRequested()
    signal expandRequested()
    signal collapseRequested()
    signal closeRequested()

    style: root.shellStyle
    tone: "normal"
    padding: Theme.Theme.moduleValuePadding + 2
    implicitHeight: topBarRow.implicitHeight + (padding * 2)

    RowLayout {
        id: topBarRow

        parent: root.contentItem
        anchors.fill: parent
        spacing: Theme.Theme.listGap + 1

        Ui.ShellText {
            Layout.fillWidth: true
            Layout.minimumWidth: 140
            role: "muted"
            style: root.shellStyle
            text: root.paneState.activeEngine ? root.paneState.activeEngine.model + " (" + root.paneState.reasoningEffort + ")" : "No model selected"
            elide: Text.ElideRight
        }

        Ui.ShellButton {
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            text: root.newChatText
            horizontalPadding: root.iconButtonPadding
            onClicked: root.paneState.createNewChat()
        }

        Item {
            Layout.fillWidth: true
        }

        Ui.ShellButton {
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            variant: root.paneState.settingsPopoverOpen ? "accent" : "ghost"
            text: root.settingsText
            horizontalPadding: root.iconButtonPadding
            onClicked: root.paneState.toggleSettingsPopover()
        }

        Ui.ShellButton {
            visible: root.showSessionsButton
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            variant: root.sessionsChecked ? "accent" : "ghost"
            text: root.sessionsText
            horizontalPadding: root.iconButtonPadding
            onClicked: root.sessionsRequested()
        }

        Ui.ShellButton {
            visible: root.showDetailsButton
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            variant: root.detailsChecked ? "accent" : "ghost"
            text: root.detailsText
            horizontalPadding: root.iconButtonPadding
            onClicked: root.detailsRequested()
        }

        Ui.ShellButton {
            visible: root.showExpandButton
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            variant: "ghost"
            text: root.expandText
            horizontalPadding: root.iconButtonPadding
            onClicked: {
                root.paneState.closePopovers();
                root.expandRequested();
            }
        }

        Ui.ShellButton {
            visible: root.showCollapseButton
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            variant: "ghost"
            text: root.collapseText
            horizontalPadding: root.iconButtonPadding
            onClicked: root.collapseRequested()
        }

        Ui.ShellButton {
            visible: root.showCloseButton
            Layout.preferredWidth: root.iconButtonWidth
            style: root.shellStyle
            variant: "ghost"
            text: root.closeText
            horizontalPadding: root.iconButtonPadding
            onClicked: {
                root.paneState.closePopovers();
                root.closeRequested();
            }
        }
    }
}
