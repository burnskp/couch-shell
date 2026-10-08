pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../animations" as Animations
import "../../services" as Services
import "../../theme" as Theme

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    property bool pickerVisible: false
    readonly property var picker: Services.PickerService.currentConfig
    readonly property bool showList: Services.PickerService.mode !== Services.PickerService.modeInputOnly
    readonly property bool showPreview: Services.PickerService.mode === Services.PickerService.modePreview
    readonly property bool anchored: picker && picker.presentation === Services.PickerService.presentationAnchored
    readonly property string styleVariant: root.picker && root.picker.styleVariant ? root.picker.styleVariant : "default"
    readonly property string previewLayout: root.picker && root.picker.previewLayout ? root.picker.previewLayout : "sideBalanced"
    readonly property color accentColor: root.picker && root.picker.accentColor ? root.picker.accentColor : Theme.Theme.barAccent
    readonly property color accentWash: Qt.alpha(root.accentColor, 0.08)
    readonly property color strongAccentWash: Qt.alpha(root.accentColor, 0.14)
    readonly property var surfacePalette: root.picker && root.picker.surfaces ? root.picker.surfaces : ({})
    readonly property color selectedRowColor: root.picker && root.picker.selectedRowColor ? root.picker.selectedRowColor : root.accentWash
    readonly property bool showPreviewTitle: !root.picker || root.picker.showPreviewTitle !== false
    // qmllint disable missing-property
    readonly property var currentInputField: root.sidebarPreviewLayout ? (sidebarInputLoader.item ? sidebarInputLoader.item["textInput"] : null) : (topInputLoader.item ? topInputLoader.item["textInput"] : null)
    // qmllint enable missing-property
    readonly property real framePadding: Theme.Theme.modulePadding + 4
    readonly property real screenPadding: Theme.Theme.modulePadding * 2
    readonly property real pickerWidth: computedPickerWidth()
    readonly property real pickerHeight: computedPickerHeight()
    readonly property real pickerX: computedPickerX()
    readonly property real pickerY: computedPickerY()
    readonly property bool stackPreview: showPreview && anchored && pickerWidth < 760
    readonly property bool verticalPreviewLayout: root.previewLayout === "stackedBottom" || root.previewLayout === "stackedTop" || root.previewLayout === "stackedBalanced"
    readonly property bool previewFirst: root.previewLayout === "sidePreviewLeft" || root.previewLayout === "stackedTop"
    readonly property bool sidebarPreviewLayout: root.previewLayout === "sidebarRightPreview" || root.previewLayout === "sidebarRightPreviewWide"

    function computedPickerWidth() {
        if (!picker)
            return 320;

        const requestedWidth = showPreview ? picker.widthPreview : showList ? picker.widthList : picker.widthInputOnly;
        return Math.max(320, Math.min(root.width - (screenPadding * 2), requestedWidth));
    }

    function computedPickerHeight() {
        if (!picker)
            return 72;

        const requestedHeight = showPreview ? picker.heightPreview : showList ? picker.heightList : picker.heightInputOnly;
        const maxHeight = anchored ? Math.max(220, root.height - pickerY - screenPadding) : root.height - (screenPadding * 2);
        const minimumHeight = root.showList || root.showPreview ? 120 : 72;
        return Math.max(minimumHeight, Math.min(maxHeight, requestedHeight));
    }

    function computedPickerX() {
        if (!anchored)
            return Math.round((root.width - pickerWidth) / 2);

        const anchorCenter = Services.PickerService.anchorX + (Services.PickerService.anchorWidth / 2);
        return Math.max(screenPadding, Math.min(root.width - pickerWidth - screenPadding, Math.round(anchorCenter - (pickerWidth / 2))));
    }

    function computedPickerY() {
        if (!anchored) {
            if (root.picker && root.picker.centeredTopEdgeFraction !== undefined) {
                const topEdgeY = Math.round(root.height * root.picker.centeredTopEdgeFraction);
                return Math.max(Theme.Theme.barHeight + 20, Math.min(root.height - pickerHeight - screenPadding, topEdgeY));
            }

            return Math.max(Theme.Theme.barHeight + 20, Math.min(root.height - pickerHeight - screenPadding, Math.round((root.height - pickerHeight) / 2)));
        }

        return Math.max(Theme.Theme.barHeight + 8, Math.round(Services.PickerService.anchorY + Services.PickerService.anchorHeight + 10));
    }

    function ensureInputFocus() {
        Qt.callLater(function() {
            if (!root.pickerVisible)
                return;

            root.clearInputFocus();

            Qt.callLater(function() {
                if (!root.pickerVisible)
                    return;

                if (root.currentInputField)
                    root.currentInputField.forceActiveFocus();
            });
        });
    }

    function clearInputFocus() {
        // qmllint disable missing-property
        if (topInputLoader.item && topInputLoader.item["textInput"])
            topInputLoader.item["textInput"].focus = false;

        if (sidebarInputLoader.item && sidebarInputLoader.item["textInput"])
            sidebarInputLoader.item["textInput"].focus = false;
        // qmllint enable missing-property
    }

    function closePicker() {
        root.clearInputFocus();
        Services.PickerService.close();
    }

    function syncPickerVisibility() {
        root.pickerVisible = Services.PickerService.isVisibleOnScreen(root.screen);
    }

    function inputBadgeText() {
        switch (root.styleVariant) {
        case "utility":
            return ">";
        case "command":
            return "::";
        case "apps":
            return "A";
        case "files":
            return "~/";
        case "images":
            return "[]";
        case "markdown":
            return "#";
        default:
            return ">";
        }
    }

    function rowBadgeText(item) {
        switch (root.styleVariant) {
        case "utility":
            return ">";
        case "command":
            return "do";
        case "apps":
            return (item && item.title ? item.title.charAt(0).toUpperCase() : "A");
        case "files":
            return item && item.meta ? item.meta.toString().slice(0, 2).toUpperCase() : "F";
        case "images":
            return "img";
        case "markdown":
            return item && item.subtitle ? item.subtitle.toString().replace(/[^0-9]/g, "").slice(0, 2) || "rg" : "rg";
        default:
            return ">";
        }
    }

    function rowBackground(selected, hovered) {
        if (selected)
            return root.selectedRowColor;

        if (hovered)
            return root.styleVariant === "command" ? Qt.alpha(root.accentColor, 0.10) : Qt.alpha(Theme.Theme.surface0, 0.75);

        return root.styleVariant === "utility" ? Qt.alpha(root.surfacePalette.rowIdle || Theme.Theme.barBackground, 0.65) : Theme.Theme.transparent;
    }

    function rowBorderColor(selected) {
        return selected ? root.accentColor : (root.styleVariant === "files" || root.styleVariant === "markdown" ? Qt.alpha(Theme.Theme.subtext0, 0.35) : Theme.Theme.transparent);
    }

    function resultSurfaceColor() {
        if (root.surfacePalette.list)
            return root.surfacePalette.list;

        switch (root.styleVariant) {
        case "utility":
            return Qt.alpha(Theme.Theme.barSurface, 0.82);
        case "command":
            return Qt.alpha(root.accentColor, 0.05);
        case "apps":
            return Qt.alpha(Theme.Theme.barSurface, 0.88);
        case "files":
            return Qt.alpha(Theme.Theme.teal, 0.04);
        case "images":
            return Qt.alpha(Theme.Theme.outline, 0.06);
        case "markdown":
            return Qt.alpha(Theme.Theme.red, 0.035);
        default:
            return Theme.Theme.barSurface;
        }
    }

    function previewSurfaceColor() {
        if (root.surfacePalette.preview)
            return root.surfacePalette.preview;

        switch (root.styleVariant) {
        case "images":
            return Qt.alpha(Theme.Theme.outline, 0.08);
        case "markdown":
            return Qt.alpha(Theme.Theme.red, 0.03);
        case "command":
            return Qt.alpha(root.accentColor, 0.04);
        default:
            return Theme.Theme.barSurface;
        }
    }

    function sidePreviewRatio() {
        switch (root.previewLayout) {
        case "sideWidePreview":
            return 0.58;
        case "sidePreviewLeft":
            return 0.48;
        case "sideBalanced":
        default:
            return 0.5;
        }
    }

    function stackedPreviewRatio() {
        switch (root.previewLayout) {
        case "stackedBalanced":
            return 0.5;
        case "stackedTop":
            return 0.58;
        case "stackedBottom":
        default:
            return 0.42;
        }
    }

    function sidebarLeftRatio() {
        switch (root.previewLayout) {
        case "sidebarRightPreviewWide":
            return 0.35;
        case "sidebarRightPreview":
            return 0.40;
        default:
            return 0.44;
        }
    }

    color: Theme.Theme.transparent
    aboveWindows: true
    focusable: root.pickerVisible
    exclusionMode: ExclusionMode.Ignore
    visible: pickerAnimation.shouldShow

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Animations.AnimationSelector {
        id: pickerAnimation

        anchors.fill: parent
        open: root.pickerVisible
        openPreset: Animations.AnimationRegistry.smoke
        closePreset: Animations.AnimationRegistry.smoke
        openDuration: Animations.AnimationPresets.smokeDurationMs
        closeDuration: Animations.AnimationPresets.smokeDurationMs

        Rectangle {
            anchors.fill: parent
            color: Theme.Theme.outline
            opacity: root.anchored ? 0.08 : 0.18
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.closePicker()
        }

    Shortcut {
        sequence: "Escape"
        enabled: root.pickerVisible
        onActivated: root.closePicker()
    }

    Shortcut {
        sequence: "Down"
        enabled: root.pickerVisible && root.showList
        onActivated: Services.PickerService.moveSelection(1)
    }

    Shortcut {
        sequence: "Up"
        enabled: root.pickerVisible && root.showList
        onActivated: Services.PickerService.moveSelection(-1)
    }

    Shortcut {
        sequence: "PgDown"
        enabled: root.pickerVisible && root.showPreview
        onActivated: root.previewPager.contentY = Math.min(root.previewPager.contentY + root.previewPager.height * 0.8, root.previewPager.contentHeight - root.previewPager.height)
    }

    Shortcut {
        sequence: "PgUp"
        enabled: root.pickerVisible && root.showPreview
        onActivated: root.previewPager.contentY = Math.max(0, root.previewPager.contentY - root.previewPager.height * 0.8)
    }

    Shortcut {
        sequence: "Return"
        enabled: root.pickerVisible
        onActivated: root.closePicker()
    }

    Shortcut {
        sequence: "Enter"
        enabled: root.pickerVisible
        onActivated: root.closePicker()
    }

    Connections {
        target: Services.PickerService

        function onVisibleChanged() {
            root.syncPickerVisibility();
        }

        function onOpenScreenChanged() {
            root.syncPickerVisibility();
        }
    }

        Rectangle {
            id: pickerFrame

            x: root.pickerX
            y: root.pickerY
            width: root.pickerWidth
            height: root.pickerHeight
            color: root.surfacePalette.frame || Theme.Theme.barBackground
            radius: 0
            border.width: 1
            border.color: Qt.alpha(root.accentColor, 0.75)
            clip: true

            Rectangle {
                anchors.fill: parent
                color: root.surfacePalette.frame || (root.styleVariant === "images" ? Theme.Theme.mantle : Theme.Theme.barSurface)
                opacity: root.styleVariant === "utility" ? 0.78 : 0.34
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: root.styleVariant === "utility" ? 3 : root.styleVariant === "images" ? 28 : 20
                color: root.styleVariant === "images" ? Qt.alpha(root.accentColor, 0.24) : root.accentColor
                opacity: root.styleVariant === "utility" ? 0.85 : 0.52
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.framePadding
                spacing: Theme.Theme.listGap + 4

            Loader {
                id: topInputLoader

                Layout.fillWidth: true
                // qmllint disable missing-property
                Layout.preferredHeight: item ? item["implicitHeight"] : 40
                // qmllint enable missing-property
                active: !root.sidebarPreviewLayout
                visible: active
                sourceComponent: inputSurfaceComponent
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.showList || root.showPreview

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.Theme.listGap + 4

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: root.sidebarPreviewLayout
                        visible: root.sidebarPreviewLayout
                        spacing: Theme.Theme.listGap + 4

                        ColumnLayout {
                            Layout.preferredWidth: Math.max(280, Math.round(root.pickerWidth * root.sidebarLeftRatio()))
                            Layout.maximumWidth: Math.max(280, Math.round(root.pickerWidth * root.sidebarLeftRatio()))
                            Layout.fillHeight: true
                            spacing: Theme.Theme.listGap + 4

                            Loader {
                                id: sidebarInputLoader

                                Layout.fillWidth: true
                                // qmllint disable missing-property
                                Layout.preferredHeight: item ? item["implicitHeight"] : 40
                                // qmllint enable missing-property
                                active: root.sidebarPreviewLayout
                                visible: active
                                sourceComponent: inputSurfaceComponent
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: root.resultSurfaceColor()
                                radius: 0
                                border.width: 1
                                border.color: Qt.alpha(root.accentColor, 0.18)

                                ListView {
                                    id: sidebarResultsList

                                    anchors.fill: parent
                                    anchors.margins: 6
                                    clip: true
                                    spacing: 4
                                    model: Services.PickerService.currentItems
                                    currentIndex: Services.PickerService.selectedIndex
                                    delegate: rowDelegate
                                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: Services.PickerService.currentItems.length === 0
                                    text: "No mock items match the current query"
                                    font.family: Theme.Theme.fontFamily
                                    font.pixelSize: Theme.Theme.fontSize - 1
                                    font.weight: Font.DemiBold
                                    color: Theme.Theme.subtext0
                                }
                            }
                        }

                        Rectangle {
                            id: sidebarPreviewSurface

                            Layout.preferredWidth: Math.max(320, root.pickerWidth - Math.max(280, Math.round(root.pickerWidth * root.sidebarLeftRatio())) - (Theme.Theme.listGap + 4))
                            Layout.minimumWidth: 320
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.showPreview
                            color: root.previewSurfaceColor()
                            radius: 0
                            border.width: 1
                            border.color: Qt.alpha(root.accentColor, 0.20)

                            PreviewPane {
                                id: sidebarPreviewPane

                                anchors.fill: parent
                                anchors.margins: 8
                                visible: root.showPreview
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: !root.stackPreview && !root.verticalPreviewLayout
                        visible: !root.stackPreview && !root.verticalPreviewLayout && !root.sidebarPreviewLayout
                        spacing: Theme.Theme.listGap + 4

                        Rectangle {
                            id: leftPreviewSurface

                            Layout.preferredWidth: root.showPreview && root.previewFirst ? Math.max(260, Math.round(root.pickerWidth * root.sidePreviewRatio())) : 0
                            Layout.fillHeight: true
                            visible: root.showPreview && root.previewFirst
                            color: root.previewSurfaceColor()
                            radius: 0
                            border.width: 1
                            border.color: Qt.alpha(root.accentColor, 0.20)

                            PreviewPane {
                                id: leftPreviewPane

                                anchors.fill: parent
                                anchors.margins: 8
                                visible: root.showPreview && root.previewFirst
                            }
                        }

                        Rectangle {
                            id: resultsSurface

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.resultSurfaceColor()
                            radius: 0
                            border.width: 1
                            border.color: Qt.alpha(root.accentColor, 0.18)

                            ListView {
                                id: resultsList

                                anchors.fill: parent
                                anchors.margins: 6
                                clip: true
                                spacing: 4
                                model: Services.PickerService.currentItems
                                currentIndex: Services.PickerService.selectedIndex

                                delegate: rowDelegate

                                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: Services.PickerService.currentItems.length === 0
                                text: "No mock items match the current query"
                                font.family: Theme.Theme.fontFamily
                                font.pixelSize: Theme.Theme.fontSize - 1
                                font.weight: Font.DemiBold
                                color: Theme.Theme.subtext0
                            }
                        }

                        Rectangle {
                            id: previewSurface

                            Layout.preferredWidth: root.showPreview && !root.previewFirst ? Math.max(260, Math.round(root.pickerWidth * root.sidePreviewRatio())) : 0
                            Layout.fillHeight: true
                            visible: root.showPreview && !root.previewFirst
                            color: root.previewSurfaceColor()
                            radius: 0
                            border.width: 1
                            border.color: Qt.alpha(root.accentColor, 0.20)

                            PreviewPane {
                                id: sidePreviewPane

                                anchors.fill: parent
                                anchors.margins: 8
                                visible: root.showPreview && !root.previewFirst
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.stackPreview || root.verticalPreviewLayout
                        color: root.resultSurfaceColor()
                        radius: 0
                        border.width: 1
                        border.color: Qt.alpha(root.accentColor, 0.18)

                        Rectangle {
                            id: verticalPreviewSurface

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: root.previewFirst ? parent.top : undefined
                            anchors.bottom: root.previewFirst ? verticalDivider.top : undefined
                            visible: root.verticalPreviewLayout && root.previewFirst
                            height: Math.max(180, parent.height * root.stackedPreviewRatio())
                            color: root.previewSurfaceColor()
                            radius: 0
                            border.width: 1
                            border.color: Qt.alpha(root.accentColor, 0.20)

                            PreviewPane {
                                id: topPreviewPane

                                anchors.fill: parent
                                anchors.margins: 8
                                visible: root.verticalPreviewLayout
                            }
                        }

                        Rectangle {
                            id: verticalDivider

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: root.previewFirst ? verticalPreviewSurface.bottom : undefined
                            anchors.bottom: root.previewFirst ? undefined : previewHost.top
                            visible: root.verticalPreviewLayout
                            height: 1
                            color: Qt.alpha(root.accentColor, 0.55)
                        }

                        ListView {
                            id: stackedResultsList

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: root.verticalPreviewLayout && root.previewFirst ? verticalDivider.bottom : parent.top
                            anchors.bottom: root.verticalPreviewLayout && !root.previewFirst ? previewDivider.top : parent.bottom
                            anchors.margins: 6
                            anchors.bottomMargin: 6
                            clip: true
                            spacing: 4
                            model: Services.PickerService.currentItems
                            currentIndex: Services.PickerService.selectedIndex

                            delegate: PickerResultRow {
                                showMeta: false
                            }
                        }

                        Rectangle {
                            id: previewDivider

                            anchors.left: parent.left
                            anchors.right: parent.right
                            visible: !root.verticalPreviewLayout || !root.previewFirst
                            anchors.bottom: previewHost.top
                            height: 1
                            color: Qt.alpha(root.accentColor, 0.55)
                        }

                        Item {
                            id: previewHost

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            visible: !root.verticalPreviewLayout || !root.previewFirst
                            height: Math.max(180, parent.height * (root.verticalPreviewLayout && !root.previewFirst ? root.stackedPreviewRatio() : 0.42))

                            PreviewPane {
                                id: stackedPreviewPane

                                anchors.fill: parent
                                anchors.margins: 8
                                visible: root.showPreview
                            }
                        }
                    }
                }
            }

            }
        }
    }

    component PickerResultRow: Rectangle {
        id: pickerRow

        required property var modelData
        required property int index
        property bool showMeta: true
        property bool showSelectionStrip: false
        property bool closeOnDoubleClick: false
        property bool showBadge: root.styleVariant !== "utility" || root.showList
        readonly property bool selected: index === Services.PickerService.selectedIndex

        width: ListView.view ? ListView.view.width : 0
        height: rowColumn.implicitHeight + 12
        color: root.rowBackground(selected, rowMouse.containsMouse)
        radius: 0
        border.width: root.styleVariant === "utility" ? 0 : 1
        border.color: root.rowBorderColor(selected)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: pickerRow.showSelectionStrip ? (root.styleVariant === "utility" ? 2 : root.styleVariant === "markdown" ? 4 : 0) : 0
            color: root.accentColor
            visible: width > 0 && pickerRow.selected
        }

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Rectangle {
                id: badgeSurface

                width: root.styleVariant === "utility" ? 16 : root.styleVariant === "markdown" ? 24 : 22
                height: root.styleVariant === "utility" ? 16 : 22
                color: root.styleVariant === "images" && pickerRow.modelData.previewAccent ? pickerRow.modelData.previewAccent : root.accentColor
                radius: 0
                visible: pickerRow.showBadge

                Text {
                    anchors.centerIn: parent
                    text: root.rowBadgeText(pickerRow.modelData)
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: root.styleVariant === "markdown" ? Theme.Theme.fontSize - 3 : Theme.Theme.fontSize - 2
                    font.weight: Font.Bold
                    color: Theme.Theme.barBackground
                }
            }

            Column {
                id: rowColumn

                width: parent.width - (badgeSurface.visible ? badgeSurface.width + parent.spacing : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.styleVariant === "images" ? 4 : 2

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: Math.max(0, parent.width - (metaText.visible ? metaText.width + parent.spacing : 0))
                        text: pickerRow.modelData.title || ""
                        elide: Text.ElideRight
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: root.styleVariant === "images" ? Theme.Theme.fontSize + 1 : Theme.Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.Theme.text
                    }

                    Text {
                        id: metaText

                        text: pickerRow.modelData.meta || ""
                        visible: pickerRow.showMeta && text.length > 0
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize - 2
                        font.weight: Font.DemiBold
                        color: root.styleVariant === "files" ? root.accentColor : Theme.Theme.subtext0
                    }
                }

                Text {
                    width: parent.width
                    text: pickerRow.modelData.subtitle || ""
                    wrapMode: Text.Wrap
                    maximumLineCount: root.styleVariant === "images" ? 1 : 2
                    elide: Text.ElideRight
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize - 1
                    font.weight: Theme.Theme.fontWeight
                    color: root.styleVariant === "markdown" ? Theme.Theme.subtext1 : Theme.Theme.subtext0
                }
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: Services.PickerService.selectedIndex = pickerRow.index
            onDoubleClicked: {
                if (pickerRow.closeOnDoubleClick)
                    root.closePicker();
            }
        }
    }

    component PreviewPane: Item {
        id: previewRoot

        readonly property var selection: Services.PickerService.currentSelection
        readonly property string previewKind: selection ? (selection.previewKind || Services.PickerService.previewKindDetails) : Services.PickerService.previewKindNone
        readonly property Flickable previewScrollTarget: previewRoot.previewKind === Services.PickerService.previewKindText ? previewFlickable : null
        readonly property string previewTitleText: previewRoot.selection ? (previewRoot.selection.previewTitle || previewRoot.selection.title || "") : ""
        readonly property string previewBodyText: previewRoot.selection ? (previewRoot.selection.previewBody || "") : ""
        readonly property string detailsBodyText: previewRoot.selection ? (previewRoot.selection.previewBody || previewRoot.selection.subtitle || "") : ""

            Item {
                anchors.fill: parent
                visible: previewRoot.previewKind === Services.PickerService.previewKindNone

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(root.accentColor, 0.05)
                }

                Text {
                    anchors.centerIn: parent
                text: "Preview appears when a row is selected"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.DemiBold
                color: Theme.Theme.subtext0
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.Theme.listGap + 4
            visible: previewRoot.previewKind === Services.PickerService.previewKindDetails

            PickerPreviewHeader {
                title: previewRoot.previewTitleText
                accentColor: root.accentColor
                showHeader: root.showPreviewTitle
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: previewRoot.detailsBodyText
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignTop
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Theme.Theme.fontWeight
                color: Theme.Theme.subtext0
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.Theme.listGap + 4
            visible: previewRoot.previewKind === Services.PickerService.previewKindImage

            PickerPreviewHeader {
                title: previewRoot.previewTitleText
                accentColor: root.accentColor
                showHeader: root.showPreviewTitle
                showDivider: false
            }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: previewRoot.selection && previewRoot.selection.previewAccent ? previewRoot.selection.previewAccent : root.accentColor
                    radius: 0

                Rectangle {
                    anchors.fill: parent
                    color: Theme.Theme.barBackground
                    opacity: 0.18
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "IMAGE"
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize + 8
                        font.weight: Font.Black
                        color: Theme.Theme.barBackground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: previewRoot.previewBodyText
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize - 1
                        font.weight: Font.Bold
                        color: Theme.Theme.barBackground
                    }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.Theme.listGap + 4
            visible: previewRoot.previewKind === Services.PickerService.previewKindText

            PickerPreviewHeader {
                title: previewRoot.previewTitleText
                accentColor: root.accentColor
                showHeader: root.showPreviewTitle
            }

            Flickable {
                id: previewFlickable

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: previewText.implicitHeight

                Text {
                    id: previewText

                    width: previewFlickable.width
                    text: previewRoot.previewBodyText
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize - 1
                    font.weight: Theme.Theme.fontWeight
                    color: Theme.Theme.subtext0
                }
            }
        }
    }

    Component {
        id: inputSurfaceComponent

        PickerInputSurface {
            surfaceColor: root.surfacePalette.input || (root.styleVariant === "images" ? Qt.alpha(root.accentColor, 0.05) : root.styleVariant === "command" ? Qt.alpha(root.accentColor, 0.04) : Theme.Theme.barSurface)
            accentColor: root.accentColor
            styleVariant: root.styleVariant
            badgeText: root.inputBadgeText()
            placeholderText: root.picker ? root.picker.placeholder : ""
            onEscapePressed: root.closePicker()
        }
    }

    Component {
        id: rowDelegate

        PickerResultRow {
            showSelectionStrip: true
            closeOnDoubleClick: true
        }
    }

    readonly property Flickable previewPager: {
        if (sidePreviewPane.visible && sidePreviewPane.previewScrollTarget)
            return sidePreviewPane.previewScrollTarget;

        if (root.sidebarPreviewLayout && sidebarPreviewSurface.visible && sidebarPreviewPane.previewScrollTarget)
            return sidebarPreviewPane.previewScrollTarget;

        if (leftPreviewPane.visible && leftPreviewPane.previewScrollTarget)
            return leftPreviewPane.previewScrollTarget;

        if (topPreviewPane.visible && topPreviewPane.previewScrollTarget)
            return topPreviewPane.previewScrollTarget;

        if (stackedPreviewPane.visible && stackedPreviewPane.previewScrollTarget)
            return stackedPreviewPane.previewScrollTarget;

        return dummyPager;
    }

    Flickable {
        id: dummyPager
        visible: false
        width: 1
        height: 1
    }

    onPickerVisibleChanged: {
        if (pickerVisible)
            ensureInputFocus();
        else
            clearInputFocus();
    }

    onScreenChanged: syncPickerVisibility()

    Component.onCompleted: syncPickerVisibility()
}
