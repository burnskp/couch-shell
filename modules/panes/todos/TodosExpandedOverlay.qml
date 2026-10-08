pragma ComponentBehavior: Bound

import QtQuick
import "../../../animations" as Animations
import "../../../theme" as Theme
import "../../../ui" as Ui

FocusScope {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented

    signal closeRequested()

    Keys.onEscapePressed: function(event) {
        if (root.paneState.expandedTodoId.length > 0) {
            root.paneState.expandedTodoId = "";
            event.accepted = true;
            return;
        }

        root.closeRequested();
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.Theme.crust, 0.42)
    }

    Animations.AnimationSelector {
        anchors.fill: parent
        open: root.visible
        openPreset: Animations.AnimationRegistry.slideIn
        closePreset: Animations.AnimationRegistry.smoke
        openDuration: Animations.AnimationPresets.slideInEnterDurationMs
        closeDuration: Animations.AnimationPresets.smokeDurationMs
        startX: width * 0.08

        Item {
            anchors.fill: parent

            Ui.ShellPaneFrame {
                width: Math.max(840, Math.round(parent.width * 0.78))
                height: Math.max(560, Math.round(parent.height * 0.86))
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Theme.Theme.sectionGap
                style: root.shellStyle
                showAccentRail: false

                TodosPane {
                    anchors.fill: parent
                    anchors.margins: Theme.Theme.modulePadding
                    shellStyle: root.shellStyle
                    paneState: root.paneState
                    expanded: true
                    onExpandRequested: root.closeRequested()
                    onCloseRequested: root.closeRequested()
                }
            }
        }
    }
}
