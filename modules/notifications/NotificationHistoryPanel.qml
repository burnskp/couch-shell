pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../animations" as Animations
import "../../services" as Services
import "../../theme" as Theme
import "../../ui" as Ui

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    readonly property bool isTargetScreen: Services.NotificationManager.historyScreen === root.screen
    readonly property int panelWidth: 360
    readonly property int maxPanelHeight: Math.max(180, Math.min(height * 0.75, height - (Theme.Theme.barHeight + (Theme.Theme.sectionGap * 3))))
    readonly property int maxListHeight: Math.max(96, maxPanelHeight - 128)
    readonly property bool dndEnabled: Services.NotificationManager.dndEnabled
    readonly property bool hasHistory: Services.NotificationManager.history.count > 0
    readonly property int shadowPadding: Theme.Theme.outerShadowEffectivePadding
    readonly property var shellStyle: Ui.ShellStyle.flatPopup

    function syncPanelOpen() {
        panelAnimation.open = Services.NotificationManager.historyOpen && root.isTargetScreen;
    }

    color: Theme.Theme.transparent
    aboveWindows: true
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    visible: Services.BarManager.visible && root.isTargetScreen && panelAnimation.shouldShow

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Animations.AnimationSelector {
        id: panelAnimation

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.Theme.barHeight + Theme.Theme.sectionGap - root.shadowPadding
        anchors.rightMargin: 0
        width: root.panelWidth + root.shadowPadding
        height: panelSurface.implicitHeight + (root.shadowPadding * 2)
        openPreset: Animations.AnimationRegistry.slideIn
        closePreset: Animations.AnimationRegistry.slideIn
        openDuration: Animations.AnimationPresets.slideInEnterDurationMs
        closeDuration: Animations.AnimationPresets.slideInEnterDurationMs

        Ui.ShellPaneFrame {
            id: panelSurface

            x: root.shadowPadding
            y: root.shadowPadding
            width: root.panelWidth
            implicitHeight: Math.min(root.maxPanelHeight, panelColumn.implicitHeight + (panelSurface.padding * 2))
            style: root.shellStyle
            showRightBorder: false
            showAccentRail: false

            ColumnLayout {
                id: panelColumn

                parent: panelSurface.contentItem
                anchors.fill: parent
                spacing: Theme.Theme.listGap + 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.Theme.listGap

                    Ui.ShellText {
                        Layout.fillWidth: true
                        role: "heading"
                        style: root.shellStyle
                        text: "Notifications"
                    }

                    Ui.ShellToggleButton {
                        style: root.shellStyle
                        checked: root.dndEnabled
                        onText: "DND"
                        offText: "DND"
                        onClicked: Services.NotificationManager.toggleDnd()
                    }

                    Ui.ShellButton {
                        style: root.shellStyle
                        variant: "danger"
                        text: "Clear"
                        onClicked: Services.NotificationManager.clearHistory()
                    }
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    role: "muted"
                    style: root.shellStyle
                    text: root.hasHistory
                        ? Services.NotificationManager.unreadCount > 0
                            ? Services.NotificationManager.unreadCount + " unread"
                            : Services.NotificationManager.history.count + " stored"
                        : root.dndEnabled ? "DND enabled" : "No notifications"
                }

                Ui.ShellDivider {
                    style: root.shellStyle
                    opacity: 0.9
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.hasHistory ? Math.min(notificationColumn.height, root.maxListHeight) : 88
                    clip: true

                    Ui.ShellEmptyState {
                        anchors.fill: parent
                        visible: !root.hasHistory
                        style: Object.assign({}, root.shellStyle, {
                            surfaceColor: Theme.Theme.transparent,
                            borderColor: Theme.Theme.transparent
                        })
                        title: root.dndEnabled ? "DND enabled" : "No notifications"
                        body: root.dndEnabled
                            ? "DND is on. New notifications will be stored here."
                            : "Your notification history is empty."
                    }

                    Flickable {
                        anchors.fill: parent
                        visible: root.hasHistory
                        clip: true
                        contentWidth: width
                        contentHeight: notificationColumn.height
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: notificationColumn

                            width: parent.width
                            spacing: Theme.Theme.listGap + 2

                            Repeater {
                                model: Services.NotificationManager.history

                                 delegate: Rectangle {
                                     id: notificationEntry

                                     required property int historyId
                                    required property string title
                                    required property string body
                                    required property string appName
                                    required property string appIcon
                                    required property string desktopEntry
                                    required property string image
                                     required property string urgency
                                     required property double timestampMs
                                     required property bool read
                                     required property int rollupCount

                                     width: parent ? parent.width : 0
                                     implicitHeight: notificationCard.implicitHeight

                                     NotificationCard {
                                         id: notificationCard

                                         anchors.fill: parent
                                         title: notificationEntry.title
                                         body: notificationEntry.body
                                         appName: notificationEntry.appName
                                         appLabel: notificationEntry.appName.length > 0 ? notificationEntry.appName : "Notification"
                                         appIcon: notificationEntry.appIcon
                                         desktopEntry: notificationEntry.desktopEntry
                                         image: notificationEntry.image
                                         urgency: notificationEntry.urgency
                                         trailingText: Qt.formatTime(new Date(notificationEntry.timestampMs), "h:mm ap")
                                         footerTrailingText: notificationEntry.rollupCount > 1 ? notificationEntry.rollupCount + "x" : ""
                                         highlighted: !notificationEntry.read
                                         imagePlacement: "below"
                                         appIconSize: 18
                                         leadingPadding: Theme.Theme.modulePadding + notificationCard.accentWidth
                                         horizontalPadding: Theme.Theme.modulePadding
                                         verticalPadding: Theme.Theme.moduleValuePadding * 2
                                     }

                                     MouseArea {
                                         anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.NotificationManager.removeHistory(notificationEntry.historyId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    mask: Region {
        item: panelAnimation
    }

    onIsTargetScreenChanged: syncPanelOpen()

    Connections {
        target: Services.NotificationManager

        function onHistoryOpenChanged() {
            root.syncPanelOpen();
        }

        function onHistoryScreenChanged() {
            root.syncPanelOpen();
        }
    }

    Component.onCompleted: syncPanelOpen()
}
