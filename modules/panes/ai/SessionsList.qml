pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Item {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool showSearch: true
    property bool showNewChatButton: false
    property bool useFillHeightList: true
    property bool active: true
    property int maxListHeight: 260
    property string heading: "Sessions"
    property int headingLeftInset: 0
    property var groups: ["Pinned", "Today", "Yesterday", "Older"]
    property string highlightedSessionId: ""
    implicitHeight: contentColumn.implicitHeight

    function focusSearch() {
        if (!root.showSearch || !root.active)
            return;

        Qt.callLater(function() {
            searchField.input.forceActiveFocus();
        });
    }

    function visibleSessions() {
        const items = [];

        for (const group of root.groups) {
            const groupSessions = root.paneState.filteredSessionsForGroup(group);
            for (const session of groupSessions)
                items.push(session);
        }

        return items;
    }

    function syncHighlight() {
        const sessions = root.visibleSessions();
        if (sessions.length === 0) {
            root.highlightedSessionId = "";
            return;
        }

        for (const session of sessions) {
            if (session.id === root.paneState.activeSessionId) {
                root.highlightedSessionId = session.id;
                return;
            }
        }

        if (root.highlightedSessionId.length === 0)
            root.highlightedSessionId = sessions[0].id;
    }

    function moveHighlight(delta) {
        const sessions = root.visibleSessions();
        if (sessions.length === 0) {
            root.highlightedSessionId = "";
            return;
        }

        let currentIndex = 0;
        for (let index = 0; index < sessions.length; index++) {
            if (sessions[index].id === root.highlightedSessionId) {
                currentIndex = index;
                break;
            }
        }

        const nextIndex = Math.max(0, Math.min(sessions.length - 1, currentIndex + delta));
        root.highlightedSessionId = sessions[nextIndex].id;
    }

    function selectHighlighted() {
        if (root.highlightedSessionId.length === 0)
            return;

        root.paneState.selectSession(root.highlightedSessionId);
    }

    component SessionRow: Rectangle {
        id: sessionRow

        required property var session
        readonly property bool isActive: root.paneState.activeSessionId === session.id
        readonly property bool isHighlighted: root.highlightedSessionId === session.id

        color: sessionRow.isActive ? Theme.Theme.crust : (sessionRow.isHighlighted ? Theme.Theme.mantle : Theme.Theme.transparent)
        radius: 0
        implicitHeight: sessionContent.implicitHeight + 8
        border.width: sessionRow.isHighlighted && !sessionRow.isActive ? 1 : 0
        border.color: Theme.Theme.surface1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: sessionRow.isActive ? 2 : 0
            color: Theme.Theme.accent
            visible: width > 0
            radius: 0
        }

        RowLayout {
            id: sessionContent

            anchors.fill: parent
            anchors.leftMargin: Theme.Theme.listGap + 2
            anchors.rightMargin: Theme.Theme.listGap + 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.Theme.listGap + 2

            Rectangle {
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                color: sessionRow.session.pinned ? Theme.Theme.accent : Theme.Theme.surface1
                radius: 0
            }

            Ui.ShellText {
                Layout.fillWidth: true
                text: sessionRow.session.title
                style: root.shellStyle
                elide: Text.ElideRight
            }

            Ui.ShellText {
                role: "muted"
                text: sessionRow.session.updatedLabel
                style: root.shellStyle
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.highlightedSessionId = sessionRow.session.id
            onClicked: root.paneState.selectSession(sessionRow.session.id)
        }
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        spacing: Theme.Theme.listGap + 4

        RowLayout {
            Layout.fillWidth: true
            visible: root.heading.length > 0

            Item {
                Layout.preferredWidth: root.headingLeftInset
                Layout.preferredHeight: 1
                visible: root.headingLeftInset > 0
            }

            Ui.ShellText {
                text: root.heading
                role: "heading"
                style: root.shellStyle
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Ui.ShellTextField {
            id: searchField

            Layout.fillWidth: true
            visible: root.showSearch
            style: root.shellStyle
            placeholderText: "Search sessions..."
            text: root.paneState.sessionQuery
            input.onTextChanged: {
                root.paneState.sessionQuery = text;
                root.syncHighlight();
            }
            input.Keys.onDownPressed: function(event) {
                root.moveHighlight(1);
                event.accepted = true;
            }
            input.Keys.onUpPressed: function(event) {
                root.moveHighlight(-1);
                event.accepted = true;
            }
            input.Keys.onReturnPressed: function(event) {
                root.selectHighlighted();
                event.accepted = true;
            }
            input.Keys.onEnterPressed: function(event) {
                root.selectHighlighted();
                event.accepted = true;
            }
        }

        Flickable {
            id: listFlickable

            Layout.fillWidth: true
            Layout.fillHeight: root.useFillHeightList
            implicitHeight: root.useFillHeightList ? Math.min(contentHeight, root.maxListHeight) : (root.visibleSessions().length > 0 ? listContent.implicitHeight : emptyState.implicitHeight)
            clip: true
            contentWidth: width
            contentHeight: root.visibleSessions().length > 0 ? listContent.implicitHeight : emptyState.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: listContent

                width: parent.width
                spacing: Theme.Theme.listGap + 3
                visible: root.visibleSessions().length > 0

                Repeater {
                    model: root.groups

                    delegate: ColumnLayout {
                        id: sessionSection

                        required property string modelData
                        readonly property var sectionSessions: root.paneState.filteredSessionsForGroup(modelData)
                        Layout.fillWidth: true
                        spacing: Theme.Theme.listGap
                        visible: sectionSessions.length > 0

                        Ui.ShellText {
                            text: sessionSection.modelData
                            role: "muted"
                            style: root.shellStyle
                        }

                        Repeater {
                            model: sessionSection.sectionSessions

                            delegate: SessionRow {
                                required property var modelData
                                width: listContent.width
                                session: modelData
                            }
                        }
                    }
                }
            }

            Ui.ShellEmptyState {
                id: emptyState

                parent: listFlickable.contentItem
                width: parent.width
                style: root.shellStyle
                title: "No matching sessions"
                body: root.paneState.sessionQuery.trim().length > 0 ? "Try a different search query or start a new chat." : "No sessions yet. Start a new chat to populate this list."
                visible: root.visibleSessions().length === 0
            }
        }

        Ui.ShellButton {
            Layout.fillWidth: true
            visible: root.showNewChatButton
            style: root.shellStyle
            variant: "accent"
            text: "+ New Chat"
            onClicked: root.paneState.createNewChat()
        }
    }

    onVisibleChanged: {
        if (visible)
            root.syncHighlight();
    }
}
