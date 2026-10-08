import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services" as Services
import "../../theme" as Theme

// The idle-inhibit protocol requires a live Wayland surface. Keep that surface
// independent from TopBar so hiding every bar does not change the user's choice.
// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    color: Theme.Theme.transparent
    visible: Services.IdleInhibitorState.enabled
    implicitWidth: 1
    implicitHeight: 1
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
    }

    mask: Region {}

    IdleInhibitor {
        enabled: Services.IdleInhibitorState.enabled
        window: root
    }
}
