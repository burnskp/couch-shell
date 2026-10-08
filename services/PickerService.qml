pragma Singleton

import QtQml
import QtQuick

QtObject {
    id: root

    readonly property string presentationCentered: "centered"
    readonly property string presentationAnchored: "anchored"
    readonly property string modeInputOnly: "inputOnly"
    readonly property string modeList: "list"
    readonly property string modePreview: "preview"
    readonly property string previewKindNone: "none"
    readonly property string previewKindDetails: "details"
    readonly property string previewKindText: "text"
    readonly property string previewKindImage: "image"

    property bool visible: false
    property var openScreen: null
    property var currentConfig: null
    property string mode: modeInputOnly
    property string query: ""
    property int selectedIndex: 0
    property real anchorX: 0
    property real anchorY: 0
    property real anchorWidth: 0
    property real anchorHeight: 0

    readonly property var currentItems: filterItems(currentConfig ? currentConfig.items : [], root.query)
    readonly property var currentSelection: currentItems.length > 0 ? currentItems[Math.max(0, Math.min(root.selectedIndex, currentItems.length - 1))] : null

    function isVisibleOnScreen(screen) {
        return root.visible && root.openScreen === screen;
    }

    function filterItems(items, queryText) {
        const normalizedQuery = (queryText || "").toString().trim().toLowerCase();

        if (normalizedQuery.length === 0)
            return items || [];

        return (items || []).filter(function(item) {
            return root.itemSearchText(item).includes(normalizedQuery);
        });
    }

    function itemSearchText(item) {
        if (!item)
            return "";

        return [
            item.title || "",
            item.subtitle || "",
            item.meta || "",
            item.search || "",
            item.previewTitle || "",
            item.previewBody || ""
        ].join(" ").toLowerCase();
    }

    function syncSelectedIndex() {
        if (root.currentItems.length === 0) {
            root.selectedIndex = 0;
            return;
        }

        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.currentItems.length - 1));
    }

    function open(screen, config, nextMode, nextAnchorX, nextAnchorY, nextAnchorWidth, nextAnchorHeight) {
        root.openScreen = screen;
        root.currentConfig = config || null;
        root.mode = nextMode || root.modeInputOnly;
        root.anchorX = nextAnchorX || 0;
        root.anchorY = nextAnchorY || 0;
        root.anchorWidth = nextAnchorWidth || 0;
        root.anchorHeight = nextAnchorHeight || 0;
        root.query = "";
        root.selectedIndex = 0;
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    function moveSelection(delta) {
        if (root.currentItems.length === 0)
            return;

        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex + delta, root.currentItems.length - 1));
    }

    onCurrentItemsChanged: syncSelectedIndex()
    onQueryChanged: root.selectedIndex = 0
}
