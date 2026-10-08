import QtQuick
import "." as Animations

Item {
    id: root

    default property alias contentData: contentContainer.data
    property string preset: ""
    property string openPreset: ""
    property string closePreset: ""
    property bool open: false
    property int duration: -1
    property int openDuration: -1
    property int closeDuration: -1
    property int easingType: Animations.AnimationPresets.easeOutCubic
    property real collapsedWidth: width
    property real startX: Number.NaN
    property real endX: 0
    property var activeAnimationItem: null

    readonly property string normalizedOpenPreset: Animations.AnimationRegistry.normalizePreset(openPreset || preset || Animations.AnimationRegistry.smoke)
    readonly property string normalizedClosePreset: Animations.AnimationRegistry.normalizePreset(closePreset || preset || normalizedOpenPreset)
    property bool running: false
    property bool shouldShow: false
    property string phase: "close"
    property real progress: 0

    readonly property Component hoverRevealAnimationComponent: hoverRevealAnimationDefinition
    readonly property Component slideInAnimationComponent: slideInAnimationDefinition
    readonly property Component smokeAnimationComponent: smokeAnimationDefinition

    implicitWidth: 0
    implicitHeight: contentContainer.implicitHeight

    function componentForPreset(presetName) {
        switch (presetName) {
        case Animations.AnimationRegistry.hoverReveal:
            return root.hoverRevealAnimationComponent;
        case Animations.AnimationRegistry.slideIn:
            return root.slideInAnimationComponent;
        case Animations.AnimationRegistry.smoke:
        default:
            return root.smokeAnimationComponent;
        }
    }

    function defaultDurationForPreset(presetName) {
        switch (presetName) {
        case Animations.AnimationRegistry.hoverReveal:
            return Animations.AnimationPresets.hoverRevealDurationMs;
        case Animations.AnimationRegistry.slideIn:
            return Animations.AnimationPresets.slideInEnterDurationMs;
        case Animations.AnimationRegistry.smoke:
        default:
            return Animations.AnimationPresets.smokeDurationMs;
        }
    }

    function resolvedDuration(durationOverride, presetName) {
        if (durationOverride >= 0)
            return durationOverride;

        if (root.duration >= 0)
            return root.duration;

        return root.defaultDurationForPreset(presetName);
    }

    function syncAnimationItem(item, shouldOwnSource, shouldBeVisible, presetName, durationOverride, isOpenAnimation) {
        if (!item)
            return;

        item.open = root.open;

        const resolvedDuration = root.resolvedDuration(durationOverride, presetName);

        if ("duration" in item)
            item.duration = resolvedDuration;

        if ("enterDuration" in item && isOpenAnimation)
            item.enterDuration = resolvedDuration;

        if ("exitDuration" in item && !isOpenAnimation)
            item.exitDuration = resolvedDuration;

        item.easingType = root.easingType;
        item.sourceItem = shouldOwnSource ? contentContainer : null;
        item.visible = shouldBeVisible;

        if ("collapsedWidth" in item)
            item.collapsedWidth = root.collapsedWidth;

        if ("startX" in item)
            item.startX = root.startX;

        if ("endX" in item)
            item.endX = root.endX;
    }

    function syncDerivedState() {
        const item = root.activeAnimationItem;
        root.running = !!item && !!item.running;
        root.shouldShow = !!item && !!item.shouldShow;
        root.phase = !!item ? item.phase : "close";
        root.progress = !!item ? item.progress : 0;
    }

    function syncActiveAnimationItem() {
        root.activeAnimationItem = root.open ? openAnimationLoader.item : closeAnimationLoader.item;
        root.syncDerivedState();
    }

    function syncAnimations() {
        syncAnimationItem(openAnimationLoader.item, root.open, root.open, root.normalizedOpenPreset, root.openDuration, true);
        syncAnimationItem(closeAnimationLoader.item, !root.open, !root.open, root.normalizedClosePreset, root.closeDuration, false);
        root.syncActiveAnimationItem();
    }

    onOpenChanged: syncAnimations()
    onDurationChanged: syncAnimations()
    onOpenDurationChanged: syncAnimations()
    onCloseDurationChanged: syncAnimations()
    onEasingTypeChanged: syncAnimations()
    onCollapsedWidthChanged: syncAnimations()
    onNormalizedOpenPresetChanged: syncAnimations()
    onNormalizedClosePresetChanged: syncAnimations()
    Component.onCompleted: syncAnimations()

    Connections {
        target: openAnimationLoader.item
        ignoreUnknownSignals: true

        function onRunningChanged() {
            root.syncDerivedState();
        }

        function onShouldShowChanged() {
            root.syncDerivedState();
        }

        function onPhaseChanged() {
            root.syncDerivedState();
        }

        function onProgressChanged() {
            root.syncDerivedState();
        }
    }

    Connections {
        target: closeAnimationLoader.item
        ignoreUnknownSignals: true

        function onRunningChanged() {
            root.syncDerivedState();
        }

        function onShouldShowChanged() {
            root.syncDerivedState();
        }

        function onPhaseChanged() {
            root.syncDerivedState();
        }

        function onProgressChanged() {
            root.syncDerivedState();
        }
    }

    Item {
        id: contentContainer

        implicitWidth: 0
        implicitHeight: childrenRect.height
        width: root.width
        height: root.height > 0 ? root.height : implicitHeight
    }

    Component {
        id: hoverRevealAnimationDefinition
        Animations.HoverRevealAnimation {}
    }

    Component {
        id: slideInAnimationDefinition
        Animations.SlideIn {}
    }

    Component {
        id: smokeAnimationDefinition
        Animations.SmokeAnimation {}
    }

    Loader {
        id: openAnimationLoader

        anchors.fill: parent
        active: true
        sourceComponent: root.componentForPreset(root.normalizedOpenPreset)
        onLoaded: root.syncAnimations()
    }

    Loader {
        id: closeAnimationLoader

        anchors.fill: parent
        active: true
        sourceComponent: root.componentForPreset(root.normalizedClosePreset)
        onLoaded: root.syncAnimations()
    }
}
