pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../animations" as Animations
import "../../services" as Services
import "../../theme" as Theme
import "./popups" as Popups

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    readonly property bool isTargetScreen: Services.SystemMenuManager.screen === root.screen
    readonly property int shadowPadding: Theme.Theme.outerShadowEffectivePadding

    function syncMenuOpen() {
        menuAnimation.open = Services.SystemMenuManager.open && root.isTargetScreen;
    }

    color: Theme.Theme.transparent
    aboveWindows: true
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    visible: Services.BarManager.visible && root.isTargetScreen && menuAnimation.shouldShow

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Animations.AnimationSelector {
        id: menuAnimation

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.Theme.barHeight + Theme.Theme.sectionGap - root.shadowPadding
        anchors.rightMargin: 0
        width: systemMenuSurface.implicitWidth + root.shadowPadding
        height: systemMenuSurface.implicitHeight + (root.shadowPadding * 2)
        openPreset: Animations.AnimationRegistry.slideIn
        closePreset: Animations.AnimationRegistry.slideIn
        openDuration: Animations.AnimationPresets.slideInEnterDurationMs
        closeDuration: Animations.AnimationPresets.slideInEnterDurationMs

        Popups.SystemMenu {
            id: systemMenuSurface

            x: root.shadowPadding
            y: root.shadowPadding
            barScreen: root.screen
            onRequestClose: Services.SystemMenuManager.close()
        }
    }

    mask: Region {
        item: systemMenuSurface
    }

    HyprlandFocusGrab {
        active: Services.SystemMenuManager.open && root.visible && root.isTargetScreen
        windows: [root]
        onCleared: Services.SystemMenuManager.close()
    }

    onIsTargetScreenChanged: syncMenuOpen()

    Connections {
        target: Services.SystemMenuManager

        function onOpenChanged() {
            root.syncMenuOpen();
        }

        function onScreenChanged() {
            root.syncMenuOpen();
        }
    }

    Component.onCompleted: syncMenuOpen()
}
