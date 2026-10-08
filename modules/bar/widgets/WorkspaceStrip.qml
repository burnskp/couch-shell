pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme

RowLayout {
    id: root

    implicitHeight: Theme.Theme.moduleHeight
    spacing: 2

    function workspaceById(id) {
        const workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let index = 0; index < workspaces.length; index += 1) {
            const workspace = workspaces[index];
            if (workspace && workspace.id === id)
                return workspace;
        }

        return null;
    }

    Repeater {
        model: [1, 2, 3, 4, 5]

        delegate: Rectangle {
            id: workspaceChip

            required property int modelData
            readonly property var workspace: root.workspaceById(modelData)
            readonly property bool active: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
            readonly property bool urgent: !!workspace && workspace.urgent
            readonly property bool occupied: Services.HyprlandState.workspaceOccupied(workspace)

            width: Theme.Theme.workspaceWidth
            height: Theme.Theme.moduleHeight
            color: Theme.Theme.transparent

            Text {
                anchors.centerIn: parent
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.barIconFontSize + 1
                font.weight: Theme.Theme.fontWeight
                text: workspaceChip.urgent ? "" : workspaceChip.occupied || workspaceChip.active ? "" : ""
                color: workspaceChip.urgent ? Theme.Theme.red : workspaceChip.active ? Theme.Theme.barAccent : Theme.Theme.barMuted
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.HyprlandState.switchWorkspace(workspaceChip.modelData)
            }
        }
    }
}
