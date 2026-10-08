pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Rectangle {
    id: root

    property var barScreen: null
    property bool systemMenuActive: false
    readonly property var trayItems: SystemTray.items ? SystemTray.items.values : []
    readonly property var visibleTrayItems: trayItems.filter(item => item && item.status !== 0 && Services.TrayIconResolver.sourceCandidates(item.icon).length > 0)
    readonly property bool hasVisibleTrayItems: trayRow.implicitWidth > 0
    property var hoveredTrayItem: null
    property var hoverAnchorItem: null
    readonly property bool notificationPanelOpen: Services.NotificationManager.isHistoryVisibleOnScreen(root.barScreen)
    readonly property string hoveredTrayTitle: root.trayTooltipTitle(root.hoveredTrayItem)
    readonly property string hoveredTrayDescription: root.trayTooltipDescription(root.hoveredTrayItem)
    readonly property bool hoverInfoVisible: hoverAnchorItem !== null && (root.hoveredTrayTitle.length > 0 || root.hoveredTrayDescription.length > 0)
    readonly property real systemButtonX: contentRow.x + systemButton.x
    readonly property real systemButtonY: contentRow.y + systemButton.y
    readonly property real systemButtonWidth: systemButton.width
    readonly property real systemButtonHeight: systemButton.height

    signal systemButtonClicked()

    implicitHeight: Theme.Theme.moduleHeight
    implicitWidth: contentRow.implicitWidth
    color: Theme.Theme.barBackground
    radius: 0

    function trayTooltipTitle(item) {
        if (!item)
            return "";

        if (item.tooltipTitle && item.tooltipTitle.length > 0)
            return item.tooltipTitle;

        if (item.title && item.title.length > 0)
            return item.title;

        if (item.tooltipDescription && item.tooltipDescription.length > 0)
            return item.tooltipDescription;

        return item.id || "";
    }

    function trayTooltipDescription(item) {
        if (!item || !item.tooltipDescription || item.tooltipDescription.length === 0)
            return "";

        const title = root.trayTooltipTitle(item);
        return item.tooltipDescription === title ? "" : item.tooltipDescription;
    }

    function clearTrayHover() {
        hoveredTrayItem = null;
        hoverAnchorItem = null;
    }

    function clearTrayInteractionState() {
        root.clearTrayHover();
    }

    function openTrayMenu(trayButton) {
        if (!trayButton || !trayButton.modelData || !trayButton.modelData.hasMenu)
            return;

        const validWindow = QsWindow.window;
        if (!validWindow) {
            console.warn("Cannot find valid Quickshell window for tray menu");
            return;
        }

        root.clearTrayInteractionState();

        const anchorPoint = QsWindow.mapFromItem(trayButton, 0, trayButton.height + 8);
        trayButton.modelData.display(validWindow, anchorPoint.x, anchorPoint.y);
    }

    component HoverButtonBackground: Rectangle {
        required property bool hovered
        property bool active: false
        property color fillColor: Theme.Theme.barActiveSurface

        anchors.fill: parent
        color: fillColor
        opacity: active ? 0.7 : hovered ? 0.5 : 0
        radius: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    component ClusterIconButton: MouseArea {
        id: buttonRoot

        required property bool interactive
        property bool active: false
        property color activeFillColor: Theme.Theme.barActiveSurface
        default property alias contentData: contentItem.data

        Layout.preferredWidth: Theme.Theme.barIconButtonWidth
        Layout.fillHeight: true
        acceptedButtons: interactive ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton
        hoverEnabled: true
        cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        HoverButtonBackground {
            hovered: buttonRoot.containsMouse
            active: buttonRoot.active
            fillColor: buttonRoot.activeFillColor
        }

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    component TrayIconButton: MouseArea {
        id: trayButton

        required property SystemTrayItem modelData
        readonly property var iconSources: Services.TrayIconResolver.sourceCandidates(modelData.icon)
        property int iconSourceIndex: 0
        readonly property string activeIconSource: iconSourceIndex < iconSources.length ? iconSources[iconSourceIndex] : ""
        readonly property bool hasRenderableIcon: activeIconSource.length > 0

        visible: hasRenderableIcon
        acceptedButtons: hasRenderableIcon ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton
        hoverEnabled: hasRenderableIcon
        cursorShape: hasRenderableIcon ? Qt.PointingHandCursor : Qt.ArrowCursor
        implicitWidth: hasRenderableIcon ? Theme.Theme.barIconButtonWidth : 0
        implicitHeight: Theme.Theme.moduleHeight

        onIconSourcesChanged: iconSourceIndex = 0

        onEntered: {
            root.hoveredTrayItem = modelData;
            root.hoverAnchorItem = trayButton;
        }

        onExited: {
            if (root.hoveredTrayItem === modelData) {
                root.hoveredTrayItem = null;
                root.hoverAnchorItem = null;
            }
        }

        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                root.clearTrayInteractionState();

                if (modelData.onlyMenu) {
                    root.openTrayMenu(trayButton);
                } else {
                    modelData.activate();
                }
            } else if (event.button === Qt.MiddleButton) {
                root.clearTrayInteractionState();

                if (modelData.secondaryActivate)
                    modelData.secondaryActivate();
            } else if (modelData.hasMenu) {
                root.openTrayMenu(trayButton);
            }
        }

        HoverButtonBackground {
            hovered: trayButton.containsMouse
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: Theme.Theme.iconSize
            source: trayButton.activeIconSource
            opacity: trayButton.containsMouse ? 1 : 0.88

            onStatusChanged: {
                if (status !== Image.Error)
                    return;

                if (trayButton.iconSourceIndex < trayButton.iconSources.length - 1)
                    trayButton.iconSourceIndex += 1;
                else
                    trayButton.iconSourceIndex = trayButton.iconSources.length;
            }
        }
    }

    PopupWindow {
        id: hoverInfoPopup

        anchor.item: root.hoverAnchorItem || root
        readonly property int shadowPadding: Theme.Theme.outerShadowEffectivePadding

        anchor.rect.x: (root.hoverAnchorItem ? Math.round((root.hoverAnchorItem.width - hoverPopupFrame.implicitWidth) / 2) : 0) - shadowPadding
        anchor.rect.y: (root.hoverAnchorItem ? root.hoverAnchorItem.height + 6 : root.height + 6) - shadowPadding
        implicitWidth: hoverPopupFrame.implicitWidth + (shadowPadding * 2)
        implicitHeight: hoverPopupFrame.implicitHeight + (shadowPadding * 2)
        visible: root.hoverInfoVisible
        color: Theme.Theme.transparent

        Components.HoverPopupFrame {
            id: hoverPopupFrame

            anchors.centerIn: parent
            width: parent.width - (hoverInfoPopup.shadowPadding * 2)
            height: parent.height - (hoverInfoPopup.shadowPadding * 2)
            minPopupWidth: 188
            contentSpacing: root.hoveredTrayDescription.length > 0 ? 4 : 0

            Text {
                Layout.fillWidth: true
                text: root.hoveredTrayTitle
                visible: text.length > 0
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: root.hoveredTrayDescription
                visible: text.length > 0
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.text
                wrapMode: Text.Wrap
            }
        }
    }

    RowLayout {
        id: contentRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 0

        RowLayout {
            id: trayRow

            spacing: 6
            visible: root.visibleTrayItems.length > 0
            Layout.leftMargin: root.hasVisibleTrayItems ? Theme.Theme.modulePadding : 0
            Layout.preferredWidth: implicitWidth

            Repeater {
                model: root.visibleTrayItems
                delegate: TrayIconButton {}
            }
        }

        Item {
            id: traySpacer

            visible: root.hasVisibleTrayItems
            Layout.preferredWidth: root.hasVisibleTrayItems ? 2 : 0
        }

        ClusterIconButton {
            id: notificationButton

            interactive: true
            active: root.notificationPanelOpen
            onClicked: Services.NotificationManager.toggleHistory(root.barScreen)

            Text {
                anchors.centerIn: parent
                text: Services.NotificationManager.statusIconGlyph
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.barIconFontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }
        }

        ClusterIconButton {
            id: systemButton

            interactive: true
            active: root.systemMenuActive
            onClicked: root.systemButtonClicked()

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.barIconFontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }
        }
    }
}
