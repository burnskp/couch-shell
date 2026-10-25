pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../../services" as Services

Item {
    id: root

    readonly property string allProjectsScope: "All Projects"
    readonly property string configuredCtCommand: Services.ShellConfig.couchTasksCommand
    readonly property string ct: configuredCtCommand.length > 0 && configuredCtCommand.indexOf("__") !== 0 ? configuredCtCommand : "ct"

    property var scopes: [allProjectsScope]
    property var pendingTasks: []
    property var completedTasks: []
    property string scope: allProjectsScope
    property string expandedTodoId: ""
    property string draggingTodoId: ""
    property string dropTargetTodoId: ""
    property bool dropBeforeTarget: true
    property bool completedOpen: false
    property bool loadingProjects: false
    property bool loadingPending: false
    property bool loadingCompleted: false
    property bool mutationBusy: false
    property string lastError: ""
    property bool addPopupOpen: false
    property string newTaskProject: ""
    property string newTaskTitle: ""
    property string newTaskNotes: ""
    property string mutationErrorText: ""
    property var pendingAddedTaskNotes: null

    readonly property bool loading: loadingProjects || loadingPending || loadingCompleted

    function normalizeTask(task) {
        const id = task && task.id !== undefined && task.id !== null ? String(task.id) : "";
        const projectName = task && task.project_name !== undefined && task.project_name !== null ? String(task.project_name) : "";
        const status = task && task.status ? String(task.status) : "pending";
        return {
            id: id,
            numericId: task ? task.id : null,
            uuid: task && task.uuid ? String(task.uuid) : "",
            project_id: task && task.project_id !== undefined ? task.project_id : null,
            project_name: projectName,
            project: projectName,
            sort_order: task && task.sort_order !== undefined && task.sort_order !== null ? Number(task.sort_order) : 0,
            order: task && task.sort_order !== undefined && task.sort_order !== null ? Number(task.sort_order) : 0,
            title: task && task.title ? String(task.title) : "",
            notes: task && task.notes ? String(task.notes) : "",
            status: status,
            completed: status === "completed",
            created_at: task && task.created_at ? String(task.created_at) : "",
            updated_at: task && task.updated_at ? String(task.updated_at) : "",
            completed_at: task && task.completed_at !== undefined ? task.completed_at : null
        };
    }

    function normalizeTasks(tasks) {
        if (!Array.isArray(tasks))
            return [];

        return tasks.map(task => root.normalizeTask(task)).filter(task => task.id.length > 0);
    }

    function parseJsonTasks(text, label) {
        const trimmed = (text || "").trim();
        if (trimmed.length === 0)
            return [];

        try {
            return root.normalizeTasks(JSON.parse(trimmed));
        } catch (error) {
            root.lastError = `Unable to parse ${label}: ${error}`;
            return null;
        }
    }

    function parseProjectNames(text) {
        const trimmed = (text || "").trim();
        if (trimmed.length === 0)
            return [root.allProjectsScope];

        let projects;
        try {
            projects = JSON.parse(trimmed);
        } catch (error) {
            root.lastError = `Unable to parse projects: ${error}`;
            return null;
        }

        if (!Array.isArray(projects)) {
            root.lastError = "Unable to parse projects: expected a JSON array";
            return null;
        }

        const names = [];
        const seen = {};
        for (const rawName of projects) {
            const name = String(rawName || "").trim();
            if (name.length === 0 || seen[name])
                continue;
            seen[name] = true;
            names.push(name);
        }
        return [root.allProjectsScope].concat(names);
    }

    function projectScopes() {
        return root.scopes.filter(scopeName => scopeName !== root.allProjectsScope);
    }

    function defaultNewTaskProject() {
        if (root.isProjectScope())
            return root.scope;

        const projects = root.projectScopes();
        const inbox = projects.find(project => project.toLowerCase() === "inbox");
        return inbox || (projects.length > 0 ? projects[0] : "");
    }

    function ensureNewTaskProject() {
        const projects = root.projectScopes();
        if (projects.indexOf(root.newTaskProject) >= 0)
            return;

        root.newTaskProject = root.defaultNewTaskProject();
    }

    function openAddPopup() {
        root.refreshProjects();
        root.newTaskProject = root.defaultNewTaskProject();
        root.newTaskTitle = "";
        root.newTaskNotes = "";
        root.addPopupOpen = true;
    }

    function closeAddPopup() {
        root.addPopupOpen = false;
    }

    function isProjectScope() {
        return root.scope !== root.allProjectsScope;
    }

    function compareProjects(left, right) {
        if (left === right)
            return 0;

        const leftInbox = left.toLowerCase() === "inbox";
        const rightInbox = right.toLowerCase() === "inbox";
        if (leftInbox !== rightInbox)
            return leftInbox ? -1 : 1;
        return left.localeCompare(right);
    }

    function groupTodosByProject(todos) {
        const groups = [];
        for (const todo of todos) {
            const last = groups.length > 0 ? groups[groups.length - 1] : null;
            if (last && last.project === todo.project)
                last.todos.push(todo);
            else
                groups.push({
                    project: todo.project,
                    todos: [todo]
                });
        }
        return groups;
    }

    function visibleTodos() {
        return root.pendingTasks.slice().sort((a, b) => {
            if (a.project !== b.project)
                return root.compareProjects(a.project, b.project);
            if (a.order !== b.order)
                return a.order - b.order;
            return Number(a.id) - Number(b.id);
        });
    }

    function completedTodos() {
        return root.completedTasks.slice().sort((a, b) => {
            if (a.project !== b.project)
                return root.compareProjects(a.project, b.project);
            const left = b.completed_at || "";
            const right = a.completed_at || "";
            if (left !== right)
                return left.localeCompare(right);
            return Number(a.id) - Number(b.id);
        });
    }

    function visibleTodoGroups() {
        return root.groupTodosByProject(root.visibleTodos());
    }

    function completedTodoGroups() {
        return root.groupTodosByProject(root.completedTodos());
    }

    function projectIncomplete(project) {
        return root.pendingTasks.filter(todo => todo.project === project).sort((a, b) => a.order - b.order);
    }

    function findTodo(id) {
        const stringId = String(id);
        for (const todo of root.pendingTasks) {
            if (todo.id === stringId)
                return todo;
        }
        for (const todo of root.completedTasks) {
            if (todo.id === stringId)
                return todo;
        }
        return null;
    }

    function taskCommandId(id) {
        const todo = root.findTodo(id);
        if (!todo || (todo.uuid || "").length === 0) {
            root.lastError = "Task UUID unavailable";
            return "";
        }

        return todo.uuid;
    }

    function refreshProjects() {
        if (root.loadingProjects)
            return;

        root.loadingProjects = true;
        projectsProcess.exec([root.ct, "projects", "--json"]);
    }

    function refreshPending() {
        if (root.loadingPending)
            return;

        root.loadingPending = true;
        const command = root.isProjectScope() ? [root.ct, "list", "--json", root.scope] : [root.ct, "list", "--json"];
        pendingProcess.exec(command);
    }

    function refreshCompleted() {
        if (root.loadingCompleted)
            return;

        root.loadingCompleted = true;
        const command = root.isProjectScope() ? [root.ct, "completed", "--json", root.scope] : [root.ct, "completed", "--json"];
        completedProcess.exec(command);
    }

    function refreshAll() {
        root.refreshProjects();
        root.refreshPending();
        root.refreshCompleted();
    }

    function runCt(args) {
        if (root.mutationBusy)
            return false;

        root.lastError = "";
        root.mutationErrorText = "";
        root.mutationBusy = true;
        mutationProcess.exec([root.ct].concat(args));
        return true;
    }

    function addTask(title, project, notes) {
        const trimmed = (title || "").trim();
        const targetProject = (project || root.defaultNewTaskProject()).trim();
        const trimmedNotes = (notes || "").trim();
        if (trimmed.length === 0 || targetProject.length === 0 || root.mutationBusy)
            return false;

        if (trimmedNotes.length > 0) {
            root.pendingAddedTaskNotes = {
                project: targetProject,
                title: trimmed,
                notes: trimmedNotes
            };
        } else {
            root.pendingAddedTaskNotes = null;
        }

        const launched = root.runCt(["add", targetProject, trimmed]);
        if (launched) {
            if (root.isProjectScope() && targetProject !== root.scope) {
                root.scope = root.allProjectsScope;
                root.completedOpen = false;
            }
            root.newTaskTitle = "";
            root.newTaskNotes = "";
            root.newTaskProject = targetProject;
            root.addPopupOpen = false;
        } else {
            root.pendingAddedTaskNotes = null;
        }
        return launched;
    }

    function addTodo() {
        return root.addTask(root.newTaskTitle, root.newTaskProject, root.newTaskNotes);
    }

    function findAddedTaskForNotes(tasks) {
        if (!root.pendingAddedTaskNotes)
            return null;

        const candidates = tasks.filter(task => task.project === root.pendingAddedTaskNotes.project && task.title === root.pendingAddedTaskNotes.title && (task.notes || "").trim().length === 0);
        if (candidates.length === 0)
            return null;

        candidates.sort((a, b) => {
            if (a.order !== b.order)
                return b.order - a.order;
            return Number(b.id) - Number(a.id);
        });
        return candidates[0];
    }

    function completeTask(id) {
        if (String(id).length === 0)
            return false;

        const commandId = root.taskCommandId(id);
        if (commandId.length === 0)
            return false;

        const launched = root.runCt(["done", commandId]);
        if (launched && root.expandedTodoId === String(id))
            root.expandedTodoId = "";
        return launched;
    }

    function restoreTask(id) {
        if (String(id).length === 0)
            return false;

        const commandId = root.taskCommandId(id);
        if (commandId.length === 0)
            return false;

        return root.runCt(["undone", commandId]);
    }

    function deleteTask(id) {
        if (String(id).length === 0)
            return false;

        const commandId = root.taskCommandId(id);
        if (commandId.length === 0)
            return false;

        const launched = root.runCt(["delete", commandId]);
        if (launched && root.expandedTodoId === String(id))
            root.expandedTodoId = "";
        return launched;
    }

    function updateTask(id, title, notes) {
        const trimmedTitle = (title || "").trim();
        if (String(id).length === 0 || trimmedTitle.length === 0)
            return false;

        const commandId = root.taskCommandId(id);
        if (commandId.length === 0)
            return false;

        return root.runCt(["update", commandId, "--title", trimmedTitle, "--notes", notes || ""]);
    }

    function clearCompleted() {
        const args = root.isProjectScope() ? ["clear-completed", root.scope] : ["clear-completed"];
        const launched = root.runCt(args);
        if (launched)
            root.completedOpen = false;
        return launched;
    }

    function setScope(scopeValue) {
        if (root.scopes.indexOf(scopeValue) < 0)
            return;

        if (root.scope === scopeValue)
            return;

        root.scope = scopeValue;
        root.expandedTodoId = "";
        root.clearDragState();
        root.completedOpen = false;
        root.refreshPending();
        root.refreshCompleted();
    }

    function moveTarget(id, direction) {
        const todos = root.visibleTodos();
        const index = todos.findIndex(item => item.id === String(id));
        const targetIndex = direction === "up" ? index - 1 : index + 1;
        if (!root.isProjectScope() || index < 0 || targetIndex < 0 || targetIndex >= todos.length)
            return null;
        return todos[targetIndex];
    }

    function canMoveTodo(id, direction) {
        return root.moveTarget(id, direction) !== null && !root.mutationBusy;
    }

    function reorderTodoToPosition(id, position) {
        if (!root.isProjectScope() || String(id).length === 0 || position < 1)
            return false;

        const commandId = root.taskCommandId(id);
        if (commandId.length === 0)
            return false;

        return root.runCt(["reorder", commandId, String(position)]);
    }

    function reorderTodoRelative(draggedId, targetId, beforeTarget) {
        if (!root.isProjectScope())
            return false;

        const dragged = root.findTodo(draggedId);
        const target = root.findTodo(targetId);
        if (!dragged || !target || dragged.id === target.id || dragged.completed || target.completed || dragged.project !== target.project)
            return false;

        const ordered = root.projectIncomplete(dragged.project).filter(todo => todo.id !== dragged.id);
        let targetIndex = ordered.findIndex(todo => todo.id === target.id);
        if (targetIndex < 0)
            return false;

        if (!beforeTarget)
            targetIndex += 1;

        return root.reorderTodoToPosition(dragged.id, targetIndex + 1);
    }

    function moveTodo(id, direction) {
        if (!root.isProjectScope())
            return false;

        const todos = root.visibleTodos();
        const index = todos.findIndex(item => item.id === String(id));
        const targetIndex = direction === "up" ? index - 1 : index + 1;
        if (index < 0 || targetIndex < 0 || targetIndex >= todos.length)
            return false;

        return root.reorderTodoToPosition(id, targetIndex + 1);
    }

    function clearDragState() {
        root.draggingTodoId = "";
        root.dropTargetTodoId = "";
        root.dropBeforeTarget = true;
    }

    function setDropTarget(targetId, beforeTarget) {
        if (root.draggingTodoId.length === 0)
            return;

        root.dropTargetTodoId = String(targetId);
        root.dropBeforeTarget = beforeTarget;
    }

    Process {
        id: projectsProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const projectNames = root.parseProjectNames(this.text);
                if (projectNames !== null) {
                    root.scopes = projectNames;
                    root.ensureNewTaskProject();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.lastError = this.text.trim();
            }
        }

        onRunningChanged: if (!running) root.loadingProjects = false
    }

    Process {
        id: pendingProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const tasks = root.parseJsonTasks(this.text, "pending tasks");
                if (tasks !== null) {
                    root.pendingTasks = tasks;
                    const addedTask = root.findAddedTaskForNotes(tasks);
                    if (addedTask && !root.mutationBusy) {
                        const commandId = root.taskCommandId(addedTask.id);
                        if (commandId.length > 0) {
                            const notes = root.pendingAddedTaskNotes.notes;
                            root.pendingAddedTaskNotes = null;
                            root.runCt(["update", commandId, "--notes", notes]);
                        }
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.lastError = this.text.trim();
            }
        }

        onRunningChanged: if (!running) root.loadingPending = false
    }

    Process {
        id: completedProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const tasks = root.parseJsonTasks(this.text, "completed tasks");
                if (tasks !== null)
                    root.completedTasks = tasks;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.lastError = this.text.trim();
            }
        }

        onRunningChanged: if (!running) root.loadingCompleted = false
    }

    Process {
        id: mutationProcess

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.mutationErrorText = this.text.trim();
            }
        }

        onRunningChanged: {
            if (!running) {
                root.mutationBusy = false;
                if (root.mutationErrorText.length > 0) {
                    root.pendingAddedTaskNotes = null;
                    root.lastError = root.mutationErrorText;
                    console.warn("[couch-tasks] " + root.lastError);
                } else {
                    root.refreshAll();
                }
            }
        }
    }

    Component.onCompleted: root.refreshAll()
}
