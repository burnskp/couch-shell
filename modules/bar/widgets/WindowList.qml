pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../../../services" as Services
import "../../../components" as Components
import "../../../theme" as Theme
import "./WindowListLogic.js" as WindowListLogic

RowLayout {
    id: root

    readonly property var currentWorkspaceWindows: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.toplevels ? Hyprland.focusedWorkspace.toplevels.values : []
    property real availableWidth: width

    implicitHeight: Theme.Theme.moduleHeight
    spacing: Theme.Theme.moduleGap
    clip: true
    visible: repeater.count > 0

    Repeater {
        id: repeater
        model: root.currentWorkspaceWindows

        delegate: Item {
            id: windowChip

            required property var modelData

            property int stateRevision: 0

            readonly property string iconGlyph: {
                stateRevision;
                return Services.HyprlandState.overrideGlyphFor(modelData);
            }
            readonly property string fallbackGlyph: ""
            readonly property string iconName: {
                stateRevision;
                Services.HyprlandState.iconRevision;
                return Services.HyprlandState.iconNameFor(modelData);
            }
            readonly property string title: {
                stateRevision;
                return Services.HyprlandState.titleFor(modelData);
            }
            readonly property string iconSource: iconName.startsWith("/") ? `file://${iconName}` : Quickshell.iconPath(iconName, "application-x-executable")
            readonly property bool imageIconFailed: windowIcon.status === Image.Error
            readonly property bool active: !!Hyprland.activeToplevel && Hyprland.activeToplevel.address === windowChip.modelData.address

            implicitHeight: Theme.Theme.moduleHeight
            implicitWidth: WindowListLogic.constrainedChipWidth(windowLabel.implicitWidth, Theme.Theme.modulePadding, Theme.Theme.moduleLeadingWidth, Theme.Theme.windowChipMinWidth, Theme.Theme.windowMaxWidth, root.availableWidth, repeater.count, root.spacing)

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: Theme.Theme.moduleLeadingWidth
                    Layout.fillHeight: true
                    color: windowChip.active ? Theme.Theme.barAccent : Theme.Theme.barMuted
                    radius: 0

                    IconImage {
                        id: windowIcon

                        anchors.centerIn: parent
                        implicitSize: Theme.Theme.iconSize
                        source: windowChip.iconSource
                        visible: !windowChip.iconGlyph.length && !windowChip.imageIconFailed
                    }

                    Components.CenteredGlyph {
                        visible: windowChip.iconGlyph.length > 0 || windowChip.imageIconFailed
                        text: windowChip.iconGlyph.length > 0 ? windowChip.iconGlyph : windowChip.fallbackGlyph
                        font.weight: Theme.Theme.fontWeight
                        color: Theme.Theme.barBackground
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth
                    implicitWidth: WindowListLogic.constrainedTitleBlockWidth(windowLabel.implicitWidth, Theme.Theme.modulePadding, Theme.Theme.windowChipMinWidth, Theme.Theme.moduleLeadingWidth, Theme.Theme.windowMaxWidth, root.availableWidth, repeater.count, root.spacing)
                    color: windowChip.active ? Theme.Theme.barActiveSurface : Theme.Theme.barSurface
                    radius: 0

                    Text {
                        id: windowLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.Theme.modulePadding
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.Theme.modulePadding
                        elide: Text.ElideRight
                        text: windowChip.title
                        textFormat: Text.PlainText
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize
                        font.weight: Theme.Theme.fontWeight
                        color: Theme.Theme.text
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.HyprlandState.focusWindow(windowChip.modelData.address)
            }

            Connections {
                target: windowChip.modelData
                ignoreUnknownSignals: true

                function onAddressChanged() {
                    windowChip.stateRevision += 1;
                }

                function onAppIdChanged() {
                    windowChip.stateRevision += 1;
                }

                function onClassChanged() {
                    windowChip.stateRevision += 1;
                }

                function onHyprlandHandleChanged() {
                    windowChip.stateRevision += 1;
                }

                function onInitialClassChanged() {
                    windowChip.stateRevision += 1;
                }

                function onInitialTitleChanged() {
                    windowChip.stateRevision += 1;
                }

                function onLastIpcObjectChanged() {
                    windowChip.stateRevision += 1;
                }

                function onTitleChanged() {
                    windowChip.stateRevision += 1;
                }

                function onWaylandHandleChanged() {
                    windowChip.stateRevision += 1;
                }
            }

            Connections {
                target: windowChip.modelData ? windowChip.modelData.wayland : null
                ignoreUnknownSignals: true

                function onAppIdChanged() {
                    windowChip.stateRevision += 1;
                }
            }

        }
    }
}
