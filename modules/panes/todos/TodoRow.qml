pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui

Item {
    id: root

    required property var paneState
    required property var todo
    property var shellStyle: Ui.ShellStyle.segmented
    property var dragLayer: null
    readonly property bool projectScope: root.paneState.isProjectScope()
    property bool dropHover: false
    readonly property bool expanded: root.paneState.expandedTodoId === root.todo.id
    readonly property bool dragging: titleDragMouse.drag.active
    readonly property bool isDraggedTodo: root.paneState.draggingTodoId === root.todo.id
    readonly property bool isDropTarget: root.paneState.dropTargetTodoId === root.todo.id && root.paneState.draggingTodoId.length > 0
    readonly property int placeholderHeight: Math.max(18, Math.round(rowSurface.implicitHeight * 0.5))

    implicitHeight: topDropGap.implicitHeight + (root.isDraggedTodo ? 0 : rowSurface.implicitHeight) + bottomDropGap.implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: implicitHeight
    z: root.dragging ? 100 : 0

    function updateDropTarget(yPosition) {
        if (root.paneState.draggingTodoId.length === 0)
            return;

        root.paneState.setDropTarget(root.todo.id, yPosition < Math.max(root.height, root.placeholderHeight) / 2);
    }

    function beginDrag() {
        root.paneState.expandedTodoId = "";
        root.paneState.draggingTodoId = root.todo.id;
        root.paneState.setDropTarget(root.todo.id, true);

        if (!root.dragLayer)
            return;

        const mapped = rowSurface.mapToItem(root.dragLayer, 0, 0);
        rowSurface.parent = root.dragLayer;
        rowSurface.x = mapped.x;
        rowSurface.y = mapped.y;
    }

    function endDrag(dropRequested) {
        if (dropRequested)
            rowSurface.Drag.drop();

        if (rowSurface.parent !== root) {
            const mapped = rowSurface.mapToItem(root, 0, 0);
            rowSurface.parent = root;
            rowSurface.x = mapped.x;
            rowSurface.y = mapped.y;
        }

        rowSurface.x = 0;
        rowSurface.y = topDropGap.implicitHeight;
        root.paneState.clearDragState();
    }

    Rectangle {
        id: topDropGap

        width: parent.width
        implicitHeight: root.isDropTarget && root.paneState.dropBeforeTarget ? root.placeholderHeight : 0
        color: Theme.Theme.transparent
        border.width: 0
        border.color: Theme.Theme.transparent
        visible: implicitHeight > 0
    }

    Ui.ShellSurface {
        id: rowSurface

        width: root.width
        z: root.dragging ? 50 : 1
        implicitHeight: rowContent.implicitHeight + (padding * 2)
        style: root.shellStyle
        tone: root.dropHover || rowMouse.containsMouse || root.expanded ? "subtle" : "normal"
        padding: 8
        showAccentRail: true
        emphasize: root.expanded
        opacity: root.dragging ? 0.94 : 1
        Drag.active: root.dragging
        Drag.source: rowSurface
        Drag.keys: ["todo-row"]
        Drag.supportedActions: Qt.MoveAction
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Binding {
            target: rowSurface
            property: "y"
            value: topDropGap.implicitHeight
            when: !root.dragging && rowSurface.parent === root
            restoreMode: Binding.RestoreNone
        }

        ColumnLayout {
            id: rowContent

            anchors.fill: parent
            spacing: Theme.Theme.listGap + 4

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.Theme.listGap + 2

                Rectangle {
                    implicitWidth: 14
                    implicitHeight: 14
                    color: Theme.Theme.transparent
                    border.width: 1
                    border.color: Theme.Theme.barAccent

                    Ui.ShellText {
                        anchors.centerIn: parent
                        role: "accent"
                        style: root.shellStyle
                        text: root.todo.completed ? "✓" : ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.paneState.mutationBusy
                        onClicked: root.paneState.completeTask(root.todo.id)
                    }
                }

                Item {
                    id: titleBlock

                    Layout.fillWidth: true
                    implicitHeight: titleContent.implicitHeight

                    ColumnLayout {
                        id: titleContent

                        anchors.fill: parent
                        spacing: 1

                        Ui.ShellText {
                            Layout.fillWidth: true
                            role: "heading"
                            style: root.shellStyle
                            text: root.todo.title || "Untitled task"
                            wrapMode: Text.Wrap
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            visible: (root.todo.notes || "").trim().length > 0 && !root.expanded
                            role: "muted"
                            style: root.shellStyle
                            text: `notes: ${(root.todo.notes || "").replace(/\n+/g, " ")}`
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: titleDragMouse

                        anchors.fill: parent
                        z: 5
                        enabled: root.projectScope && !root.expanded && !root.paneState.mutationBusy
                        hoverEnabled: true
                        cursorShape: Qt.SizeAllCursor
                        drag.target: rowSurface
                        drag.axis: Drag.XAndYAxis
                        onPressed: root.beginDrag()
                        onReleased: root.endDrag(true)
                        onCanceled: root.endDrag(false)
                        onClicked: root.paneState.expandedTodoId = root.expanded ? "" : root.todo.id
                    }
                }

                Rectangle {
                    visible: !root.projectScope
                    implicitWidth: projectChipText.implicitWidth + 14
                    implicitHeight: 18
                    color: Qt.alpha(Theme.Theme.blue, 0.12)
                    border.width: 1
                    border.color: Theme.Theme.surface0

                    Ui.ShellText {
                        id: projectChipText

                        anchors.centerIn: parent
                        role: "label"
                        style: root.shellStyle
                        text: root.todo.project || root.todo.project_name || "project"
                    }
                }

                Ui.ShellButton {
                    style: root.shellStyle
                    variant: "ghost"
                    text: root.expanded ? "˄" : "›"
                    onClicked: root.paneState.expandedTodoId = root.expanded ? "" : root.todo.id
                }
            }

            TodoInlineEditor {
                visible: root.expanded
                Layout.fillWidth: true
                shellStyle: root.shellStyle
                paneState: root.paneState
                todo: root.todo
            }
        }
    }

    Rectangle {
        id: bottomDropGap

        width: parent.width
        y: topDropGap.implicitHeight + (root.isDraggedTodo ? 0 : rowSurface.implicitHeight)
        implicitHeight: root.isDropTarget && !root.paneState.dropBeforeTarget ? root.placeholderHeight : 0
        color: Theme.Theme.transparent
        border.width: 0
        border.color: Theme.Theme.transparent
        visible: implicitHeight > 0
    }

    DropArea {
        id: rowDropArea

        anchors.fill: parent
        keys: ["todo-row"]
        enabled: root.projectScope && root.paneState.draggingTodoId.length > 0 && !root.paneState.mutationBusy
        onEntered: function(drag) {
            root.dropHover = root.paneState.draggingTodoId !== root.todo.id;
            root.updateDropTarget(drag.y);
        }
        onPositionChanged: function(drag) {
            root.updateDropTarget(drag.y);
        }
        onExited: root.dropHover = false
        onDropped: function(drop) {
            const targetId = root.paneState.dropTargetTodoId.length > 0 ? root.paneState.dropTargetTodoId : root.todo.id;
            if (root.paneState.draggingTodoId.length > 0 && root.paneState.draggingTodoId !== targetId) {
                root.paneState.reorderTodoRelative(root.paneState.draggingTodoId, targetId, root.paneState.dropBeforeTarget);
                drop.acceptProposedAction();
            }
            root.dropHover = false;
            root.paneState.clearDragState();
        }
    }

    MouseArea {
        id: rowMouse

        anchors.fill: rowSurface
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.paneState.expandedTodoId = root.expanded ? "" : root.todo.id
    }
}
