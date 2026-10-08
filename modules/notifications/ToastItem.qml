pragma ComponentBehavior: Bound

import QtQuick
import "../../animations" as Animations
import "../../theme" as Theme
import "../../ui" as Ui

Animations.AnimationSelector {
    id: root

    required property int toastId
    required property string title
    required property string body
    required property string appName
    required property string appIcon
    required property string desktopEntry
    required property string image
    required property string urgency
    required property int timeoutMs
    required property bool closing
    required property string closingReason
    required property var notificationManager

    property real lifetimeProgress: 1
    readonly property int toastWidth: 384
    readonly property int maxToastHeight: 164
    readonly property int shadowPadding: Theme.Theme.outerShadowEffectivePadding
    readonly property int cardHeight: Math.min(root.maxToastHeight, notificationCard.implicitHeight)

    width: root.toastWidth + root.shadowPadding
    implicitHeight: root.cardHeight + (root.shadowPadding * 2)
    clip: false
    open: !root.closing
    openPreset: Animations.AnimationRegistry.slideIn
    closePreset: Animations.AnimationRegistry.slideIn
    openDuration: Animations.AnimationPresets.slideInEnterDurationMs
    closeDuration: Animations.AnimationPresets.slideInEnterDurationMs
    onShouldShowChanged: {
        if (root.closing && !root.shouldShow)
            root.notificationManager.removeToast(root.toastId);
    }

    NumberAnimation on lifetimeProgress {
        duration: root.timeoutMs
        from: 1
        to: 0
        running: root.open && !root.closing && root.timeoutMs > 0
        easing.type: Easing.Linear
    }

    Timer {
        interval: root.timeoutMs
        repeat: false
        running: !root.closing && root.timeoutMs > 0
        onTriggered: root.notificationManager.dismissToast(root.toastId, "timeout")
    }

    Ui.ShellOuterShadow {
        anchors.fill: notificationCard
    }

    NotificationCard {
        id: notificationCard

        x: root.shadowPadding
        y: root.shadowPadding
        width: root.toastWidth
        height: root.cardHeight
        title: root.title
        body: root.body
        appName: root.appName
        appLabel: root.appName
        appIcon: root.appIcon
        desktopEntry: root.desktopEntry
        image: root.image
        urgency: root.urgency
        imagePlacement: "side"
        fontFamily: Theme.Theme.notificationToastFontFamily
        fontSize: Theme.Theme.notificationToastFontSize
        appIconSize: 16
        imagePreviewSize: 56
        leadingPadding: 28
        horizontalPadding: 12
        verticalPadding: 8
        bodyMaximumLineCount: root.image.length > 0 ? 3 : 4
        bottomBarProgress: root.lifetimeProgress
        showRightBorder: false
    }

    MouseArea {
        anchors.fill: notificationCard
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        enabled: !root.closing
        onClicked: root.notificationManager.dismissToast(root.toastId, "click")
    }
}
