pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell
import "../../animations" as Animations
import "../../theme" as Theme

Item {
    id: root

    property var anchorWindow: null
    property Item anchorSurface: null
    property var trackedWidgets: []
    property int openDelay: 500
    property int closeDelay: 120
    property var hoveredWidgetItem: null
    property var activeHoverWidgetItem: null
    property bool hoverPopupHovered: false
    property bool hoverPopupOpenRequested: false
    readonly property bool hoverPopupContentReady: hoverPopupContentLoader.status === Loader.Ready && hoverPopupContentLoader.item !== null
    readonly property bool hoverPopupLayoutReady: root.hoverPopupWidth > 1 && hoverPopupLayer.implicitHeight > 1
    readonly property bool hoverPopupOpenReady: hoverPopupContentReady && hoverPopupLayoutReady
    readonly property rect hoveredWidgetAnchorRect: {
        const widget = activeHoverWidgetItem;

        if (!widget || !anchorSurface)
            return Qt.rect(0, 0, 0, 0);

        const point = widget.mapToItem(anchorSurface, 0, 0);
        return Qt.rect(point.x, point.y, widget.width, widget.height);
    }
    readonly property bool hoverPopupAnimating: !!hoverPopupLayer && (hoverPopupLayer.running || hoverPopupLayer.progress > 0.001)
    readonly property bool hoverPopupContentActive: hoverPopupOpenRequested || hoverPopupAnimating
    readonly property bool hoverPopupDisplayRequested: hoverPopupOpenRequested && hoverPopupOpenReady
    readonly property bool hoverPopupWindowVisible: hoverPopupDisplayRequested || hoverPopupAnimating
    readonly property Component hoverPopupComponent: activeHoverWidgetItem && activeHoverWidgetItem.hoverPopupEnabled ? activeHoverWidgetItem.hoverPopup : null
    readonly property string hoverPopupOpenAnimationPreset: activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupOpenAnimationStyle : Animations.AnimationRegistry.smoke
    readonly property string hoverPopupCloseAnimationPreset: activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupCloseAnimationStyle : Animations.AnimationRegistry.smoke
    readonly property real hoverPopupPreferredWidth: activeHoverWidgetItem && activeHoverWidgetItem.hoverPopupEnabled ? activeHoverWidgetItem.hoverPopupWidth : 220
    readonly property real hoverPopupWidth: Math.max(1, hoverPopupPreferredWidth)
    readonly property real hoverPopupMinX: anchorSurface ? anchorSurface.x : 0
    readonly property real hoverPopupMaxX: anchorSurface ? Math.max(hoverPopupMinX, anchorSurface.x + anchorSurface.width - hoverPopupWidth) : hoverPopupMinX
    readonly property real hoverPopupX: Math.max(hoverPopupMinX, Math.min(hoverPopupMaxX, Math.round(hoveredWidgetAnchorRect.x + (hoveredWidgetAnchorRect.width / 2) - (hoverPopupWidth / 2))))
    readonly property real hoverPopupY: Math.round(hoveredWidgetAnchorRect.y + hoveredWidgetAnchorRect.height + (activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupOffsetY : 0))
    readonly property int hoverPopupCollapsedWidth: activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupCollapsedWidth : Theme.Theme.moduleLeadingWidth * 2
    readonly property int hoverPopupAnimationDuration: activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupAnimationDuration : -1
    readonly property int hoverPopupOpenAnimationDuration: activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupOpenAnimationDuration : -1
    readonly property int hoverPopupCloseAnimationDuration: activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupCloseAnimationDuration : -1
    readonly property int hoverPopupNotchWidth: 36
    readonly property int hoverPopupNotchHeight: 14
    readonly property int hoverPopupShadowPadding: Theme.Theme.outerShadowEffectivePadding
    readonly property real hoverPopupNotchCenterX: Math.max(hoverPopupNotchWidth / 2, Math.min(hoverPopupWidth - (hoverPopupNotchWidth / 2), Math.round(hoveredWidgetAnchorRect.x + (hoveredWidgetAnchorRect.width / 2) - hoverPopupX)))
    readonly property string activePopupKey: hoverPopupWindowVisible && activeHoverWidgetItem ? activeHoverWidgetItem.hoverPopupKey : ""

    function normalizedHoverWidgetItem(widgetItem) {
        if (!widgetItem || !widgetItem.hovered || !widgetItem.hoverPopupEnabled)
            return null;

        return widgetItem;
    }

    function findHoveredWidgetItem() {
        const candidates = root.trackedWidgets || [];

        for (const candidate of candidates) {
            if (candidate && candidate.hovered && candidate.hoverPopupEnabled)
                return candidate;
        }

        return null;
    }

    function syncHoveredWidgetItem() {
        const nextHoveredWidgetItem = root.findHoveredWidgetItem();
        root.hoveredWidgetItem = nextHoveredWidgetItem;

        if (root.hoverPopupHovered && root.hoverPopupOpenRequested) {
            hoverPopupOpenTimer.stop();
            hoverPopupCloseTimer.stop();
            return;
        }

        if (nextHoveredWidgetItem === root.activeHoverWidgetItem && root.hoverPopupOpenRequested) {
            hoverPopupOpenTimer.stop();
            hoverPopupCloseTimer.stop();
            return;
        }

        if (nextHoveredWidgetItem) {
            if (root.activeHoverWidgetItem && root.hoverPopupOpenRequested)
                hoverPopupCloseTimer.restart();
            else
                hoverPopupCloseTimer.stop();

            hoverPopupOpenTimer.restart();
            return;
        }

        hoverPopupOpenTimer.stop();

        if (root.activeHoverWidgetItem && root.hoverPopupOpenRequested)
            hoverPopupCloseTimer.restart();
        else
            root.syncActiveHoverWidgetItem();
    }

    function syncActiveHoverWidgetItem() {
        if (!root.hoverPopupOpenRequested && !root.hoverPopupAnimating)
            root.activeHoverWidgetItem = null;
    }

    function syncHoverPopupOpenState() {
        hoverPopupLayer.open = root.hoverPopupDisplayRequested;
        root.syncActiveHoverWidgetItem();
    }

    onTrackedWidgetsChanged: syncHoveredWidgetItem()

    Instantiator {
        model: root.trackedWidgets || []

        delegate: Connections {
            required property var modelData

            target: modelData
            ignoreUnknownSignals: true

            function onHoveredChanged() {
                root.syncHoveredWidgetItem();
            }

            function onVisibleChanged() {
                root.syncHoveredWidgetItem();
            }

            function onHoverPopupEnabledChanged() {
                root.syncHoveredWidgetItem();
            }
        }
    }

    Timer {
        id: hoverPopupOpenTimer

        interval: root.openDelay
        repeat: false
        onTriggered: {
            const nextHoveredWidgetItem = root.normalizedHoverWidgetItem(root.hoveredWidgetItem);

            if (nextHoveredWidgetItem) {
                hoverPopupCloseTimer.stop();
                root.activeHoverWidgetItem = nextHoveredWidgetItem;
                root.hoverPopupOpenRequested = true;
            }
        }
    }

    Timer {
        id: hoverPopupCloseTimer

        interval: root.closeDelay
        repeat: false
        onTriggered: {
            root.hoverPopupOpenRequested = false;
            root.hoverPopupHovered = false;
        }
    }

    PopupWindow {
        id: hoverPopup

        anchor.window: root.anchorWindow
        anchor.rect.x: root.hoverPopupX - root.hoverPopupShadowPadding
        anchor.rect.y: root.hoverPopupY - root.hoverPopupShadowPadding
        implicitWidth: Math.max(1, root.hoverPopupWidth + (root.hoverPopupShadowPadding * 2))
        implicitHeight: Math.max(1, hoverPopupLayer.implicitHeight)
        visible: root.hoverPopupWindowVisible
        color: Theme.Theme.transparent

        Animations.AnimationSelector {
            id: hoverPopupLayer

            anchors.fill: parent
            openPreset: root.hoverPopupOpenAnimationPreset
            closePreset: root.hoverPopupCloseAnimationPreset
            open: false
            collapsedWidth: root.hoverPopupCollapsedWidth
            duration: root.hoverPopupAnimationDuration
            openDuration: root.hoverPopupOpenAnimationDuration
            closeDuration: root.hoverPopupCloseAnimationDuration

            HoverHandler {
                onHoveredChanged: {
                    root.hoverPopupHovered = hovered && root.hoverPopupOpenRequested;

                    if (root.hoverPopupHovered)
                        hoverPopupCloseTimer.stop();

                    root.syncHoveredWidgetItem();
                }
            }

            Item {
                id: hoverPopupContentStack

                width: parent ? parent.width : 0
                implicitHeight: (root.hoverPopupShadowPadding * 2) + root.hoverPopupNotchHeight + hoverPopupContentLoader.implicitHeight
                height: implicitHeight

                Loader {
                    id: hoverPopupContentLoader

                    x: root.hoverPopupShadowPadding
                    y: root.hoverPopupShadowPadding + root.hoverPopupNotchHeight
                    width: Math.max(1, root.hoverPopupWidth)
                    height: Math.max(1, implicitHeight)
                    active: root.hoverPopupContentActive
                    sourceComponent: root.hoverPopupComponent
                }

                Canvas {
                    id: hoverPopupNotch

                    width: root.hoverPopupNotchWidth
                    height: root.hoverPopupNotchHeight + 2
                    x: root.hoverPopupShadowPadding + root.hoverPopupNotchCenterX - (width / 2)
                    y: root.hoverPopupShadowPadding

                    onPaint: {
                        const ctx = getContext("2d");
                        const w = width;
                        const h = root.hoverPopupNotchHeight;
                        ctx.reset();

                        ctx.fillStyle = Theme.Theme.popupBackground;
                        ctx.beginPath();
                        ctx.moveTo(0, h);
                        ctx.lineTo(w / 2, 0);
                        ctx.lineTo(w, h);
                        ctx.closePath();
                        ctx.fill();

                        // Cover the popup frame's top border under the notch so the pointer
                        // reads as one continuous filled surface rather than a rotated square.
                        ctx.fillRect(1, h - 1, w - 2, 3);

                        ctx.strokeStyle = Theme.Theme.popupBorder;
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(0.5, h + 0.5);
                        ctx.lineTo(w / 2, 0.5);
                        ctx.lineTo(w - 0.5, h + 0.5);
                        ctx.stroke();
                    }
                }
            }

            Component.onCompleted: open = root.hoverPopupDisplayRequested
        }

        onVisibleChanged: {
            if (!visible) {
                root.hoverPopupHovered = false;
                root.syncActiveHoverWidgetItem();
            }
        }
    }

    Connections {
        target: root

        function onHoverPopupAnimatingChanged() {
            root.syncActiveHoverWidgetItem();
        }

        function onHoverPopupOpenRequestedChanged() {
            root.syncHoverPopupOpenState();
        }

        function onHoverPopupOpenReadyChanged() {
            root.syncHoverPopupOpenState();
        }
    }
}
