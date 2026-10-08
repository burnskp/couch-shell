pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../services" as Services
import "../theme" as Theme

Item {
    id: root

    required property string appIcon
    required property string desktopEntry
    required property string appName
    property int size: 16

    readonly property var iconSources: Services.TrayIconResolver.notificationIconCandidates(root.appIcon, root.desktopEntry, root.appName)
    property int iconSourceIndex: 0
    readonly property string activeIconSource: iconSourceIndex < iconSources.length ? iconSources[iconSourceIndex] : ""
    readonly property bool usingFallbackIcon: activeIconSource === Services.TrayIconResolver.defaultIconSource

    width: root.size
    height: root.size
    clip: true

    onIconSourcesChanged: iconSourceIndex = 0

    IconImage {
        id: appIconImage

        anchors.fill: parent
        source: root.activeIconSource
        visible: !root.usingFallbackIcon

        onStatusChanged: {
            if (status !== Image.Error)
                return;

            if (root.iconSourceIndex < root.iconSources.length - 1)
                root.iconSourceIndex += 1;
            else
                root.iconSourceIndex = root.iconSources.length;
        }
    }

    ShaderEffectSource {
        id: fallbackIconSource

        anchors.fill: parent
        sourceItem: appIconImage
        visible: false
        hideSource: false
        live: true
    }

    MultiEffect {
        anchors.fill: parent
        source: fallbackIconSource
        visible: root.usingFallbackIcon
        colorization: 1
        colorizationColor: Theme.Theme.subtext1
    }
}
