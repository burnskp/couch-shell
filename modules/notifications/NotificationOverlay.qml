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
    exclusionMode: ExclusionMode.Ignore
    visible: Services.NotificationManager.toasts.count > 0

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Column {
        id: toastStack

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.Theme.barHeight + Theme.Theme.sectionGap - Theme.Theme.outerShadowEffectivePadding
        anchors.rightMargin: 0
        spacing: Theme.Theme.listGap

        Repeater {
            model: Services.NotificationManager.toasts

            delegate: ToastItem {
                notificationManager: Services.NotificationManager
            }
        }
    }

    mask: Region {
        item: toastStack
    }
}
