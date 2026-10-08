pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../services" as Services
import "../../theme" as Theme

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    color: Theme.Theme.transparent
    aboveWindows: true
    focusable: false
    visible: Services.BarManager.visible
    exclusiveZone: Services.BarManager.visible ? Theme.Theme.barHeight : 0
    implicitHeight: Theme.Theme.barHeight

    anchors {
        top: true
        left: true
        right: true
    }

    Loader {
        anchors.fill: parent
        active: Services.BarManager.visible

        sourceComponent: Component {
            BarContent {
                anchorWindow: root
                barScreen: root.screen
            }
        }
    }
}
