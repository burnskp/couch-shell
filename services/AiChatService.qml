pragma Singleton

import QtQml
import QtQuick
import Quickshell.Io
import "." as Services

Item {
    id: root

    property bool logoutBusy: false
    property bool authenticatedWorkBlocked: false
    property int authenticationEpoch: 0
    property bool statusBusy: false
    property bool loginBusy: false
    property bool chatBusy: false
    property bool stateLoadBusy: false
    property bool stateSaveBusy: false
    property bool configured: false
    property bool expired: false
    property string accountId: ""
    property string authFile: ""
    property string authUrl: ""
    property string loginMessage: ""
    property string lastError: ""
    readonly property string defaultModel: "gpt-5.5"
    readonly property string defaultReasoning: "medium"
    property var codexModels: []
    property bool modelsLoadBusy: false
    property bool modelsRefreshBusy: false
    property string modelsFile: ""
    property real modelsUpdatedAt: 0
    property string modelsSource: "none"

    property string activeSessionId: ""
    property string activeMessageId: ""
    property string activeTitleSessionId: ""
    property string pendingPayload: ""
    property string pendingTitlePayload: ""
    property string pendingStatePayload: ""
    property string queuedStatePayload: ""
    property bool titleBusy: false

    signal chatEvent(string sessionId, string messageId, var event)
    signal titleEvent(string sessionId, var event)
    signal loginEvent(var event)
    signal stateLoaded(var state, var event)
    signal stateSaved(var event)
    signal statePersistenceError(string message)
    signal modelsLoaded(var models, var event)
    signal modelsRefreshed(var models, var event)
    signal modelsRefreshError(string message)
    signal statusUpdated()

    function helperCommand(subcommand) {
        const configuredHelper = Services.ShellConfig.aiCodexHelper;
        if (configuredHelper.length > 0 && configuredHelper.indexOf("__") !== 0)
            return [configuredHelper, subcommand];

        return ["node", "tools/couch-ai-codex.mjs", subcommand];
    }

    function parseLine(line) {
        const trimmed = line.trim();
        if (trimmed.length === 0)
            return null;

        try {
            return JSON.parse(trimmed);
        } catch (error) {
            return {
                type: "error",
                message: "Invalid helper output: " + trimmed
            };
        }
    }

    function applyStatus(event) {
        if (!event)
            return;

        root.configured = !!event.configured;
        root.expired = !!event.expired;
        root.accountId = event.accountId || "";
        root.authFile = event.authFile || root.authFile;
        root.statusUpdated();
    }

    function applyModels(event) {
        root.codexModels = Array.isArray(event.models) ? event.models : [];
        root.modelsFile = event.path || root.modelsFile;
        root.modelsUpdatedAt = typeof event.updatedAt === "number" ? event.updatedAt : 0;
        root.modelsSource = event.source || "none";
    }

    function refreshStatus() {
        if (root.statusBusy || root.logoutBusy || root.authenticatedWorkBlocked)
            return;

        root.statusBusy = true;
        statusProcess.requestEpoch = root.authenticationEpoch;
        statusProcess.exec(root.helperCommand("status"));
    }

    function login() {
        if (root.loginBusy || root.logoutBusy)
            return;

        root.lastError = "";
        root.authUrl = "";
        root.loginMessage = "Waiting for browser approval…";
        root.loginBusy = true;
        loginProcess.requestEpoch = root.authenticationEpoch;
        loginProcess.exec(root.helperCommand("login"));
    }

    function logout() {
        if (root.logoutBusy)
            return;

        root.authenticatedWorkBlocked = true;
        root.authenticationEpoch += 1;
        root.logoutBusy = true;
        root.lastError = "";
        if (root.chatBusy)
            root.chatEvent(root.activeSessionId, root.activeMessageId, { type: "error", message: "Response cancelled by logout." });
        if (root.titleBusy)
            root.titleEvent(root.activeTitleSessionId, { type: "error", message: "Title generation cancelled by logout." });
        chatProcess.running = false;
        titleProcess.running = false;
        modelsRefreshProcess.running = false;
        loginProcess.running = false;
        statusProcess.running = false;
        root.authUrl = "";
        root.loginMessage = "";
        logoutProcess.exec(root.helperCommand("logout"));
    }

    function sendChat(sessionId, messageId, request) {
        if (root.authenticatedWorkBlocked || !root.configured)
            return false;
        if (root.chatBusy) {
            root.chatEvent(sessionId, messageId, {
                type: "error",
                message: "A Codex response is already streaming."
            });
            return false;
        }

        root.lastError = "";
        root.activeSessionId = sessionId;
        root.activeMessageId = messageId;
        root.pendingPayload = JSON.stringify(request || {});
        root.chatBusy = true;
        chatProcess.requestEpoch = root.authenticationEpoch;
        chatProcess.exec(root.helperCommand("chat"));
        return true;
    }

    function generateTitle(sessionId, request) {
        if (root.titleBusy || root.authenticatedWorkBlocked || !root.configured)
            return false;

        root.lastError = "";
        root.activeTitleSessionId = sessionId;
        root.pendingTitlePayload = JSON.stringify(request || {});
        root.titleBusy = true;
        titleProcess.requestEpoch = root.authenticationEpoch;
        titleProcess.exec(root.helperCommand("chat"));
        return true;
    }

    function loadState() {
        if (root.stateLoadBusy)
            return false;

        root.lastError = "";
        root.stateLoadBusy = true;
        stateLoadProcess.exec(root.helperCommand("state-load"));
        return true;
    }

    function saveState(state) {
        const payload = JSON.stringify(state || {});

        if (root.stateSaveBusy) {
            root.queuedStatePayload = payload;
            return false;
        }

        root.lastError = "";
        root.pendingStatePayload = payload;
        root.stateSaveBusy = true;
        stateSaveProcess.exec(root.helperCommand("state-save"));
        return true;
    }

    function loadModels() {
        if (root.modelsLoadBusy)
            return false;

        root.lastError = "";
        root.modelsLoadBusy = true;
        modelsLoadProcess.requestEpoch = root.authenticationEpoch;
        modelsLoadProcess.exec(root.helperCommand("models-load"));
        return true;
    }

    function refreshModels() {
        if (root.modelsRefreshBusy || root.authenticatedWorkBlocked || !root.configured)
            return false;

        root.lastError = "";
        root.modelsRefreshBusy = true;
        modelsRefreshProcess.requestEpoch = root.authenticationEpoch;
        modelsRefreshProcess.exec(root.helperCommand("models-refresh"));
        return true;
    }

    Process {
        id: logoutProcess
        property bool removalConfirmed: false
        onStarted: removalConfirmed = false
        stdout: SplitParser {
            onRead: function(data) {
                const event = root.parseLine(data);
                if (!event)
                    return;
                if (event.type === "logout_complete") {
                    logoutProcess.removalConfirmed = true;
                    root.configured = false;
                    root.expired = false;
                    root.accountId = "";
                    root.codexModels = [];
                    root.modelsUpdatedAt = 0;
                    root.modelsSource = "none";
                    root.statusUpdated();
                } else if (event.type === "error") {
                    root.lastError = event.message || "Credential removal failed";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    root.lastError = this.text.trim();
            }
        }
        // Quickshell metadata omits QProcess::ExitStatus.
        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            root.logoutBusy = false;
            if ((exitCode !== 0 || !removalConfirmed) && root.lastError.length === 0)
                root.lastError = "Credential removal failed";
        }
        // qmllint enable signal-handler-parameters
        onRunningChanged: {
            // FailedToStart emits runningChanged without exited.
            if (!running && root.logoutBusy) {
                root.logoutBusy = false;
                root.lastError = "Could not start credential removal helper";
            }
        }
    }

    Process {
        id: statusProcess
        property int requestEpoch: -1

        stdout: StdioCollector {
            onStreamFinished: {
                if (statusProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const event = root.parseLine(line);
                    if (!event)
                        continue;

                    if (event.type === "status") {
                        root.applyStatus(event);
                    } else if (event.type === "error") {
                        root.lastError = event.message || "Codex helper failed";
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (statusProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                if (this.text.trim().length > 0)
                    root.lastError = this.text.trim();
            }
        }

        onRunningChanged: {
            if (!running)
                root.statusBusy = false;
        }
    }

    Process {
        id: loginProcess
        property int requestEpoch: -1

        stdout: SplitParser {
            onRead: function(data) {
                if (loginProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                const event = root.parseLine(data);
                if (!event)
                    return;

                if (event.type === "auth_url") {
                    root.authUrl = event.url || "";
                    root.loginMessage = "Waiting for browser approval…";
                    if (root.authUrl.length > 0)
                        Qt.openUrlExternally(root.authUrl);
                } else if (event.type === "login_progress") {
                    root.loginMessage = event.message || "Completing login…";
                } else if (event.type === "login_complete") {
                    root.authenticatedWorkBlocked = false;
                    root.loginMessage = "Signed in.";
                    root.applyStatus(event);
                    root.refreshModels();
                } else if (event.type === "error")
                    root.lastError = event.message || "Codex login failed";

                root.loginEvent(event);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (loginProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                if (this.text.trim().length > 0)
                    root.lastError = this.text.trim();
            }
        }

        onRunningChanged: {
            if (!running) {
                root.loginBusy = false;
                root.refreshStatus();
            }
        }
    }

    Process {
        id: chatProcess
        property int requestEpoch: -1
        stdinEnabled: true

        stdout: SplitParser {
            onRead: function(data) {
                if (chatProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                const event = root.parseLine(data);
                if (!event)
                    return;

                if (event.type === "debug") {
                    const details = Object.assign({}, event);
                    delete details.type;
                    delete details.message;
                    const suffix = Object.keys(details).length > 0 ? " " + JSON.stringify(details) : "";
                    console.log("[couch-ai] " + (event.message || "debug") + suffix);
                    return;
                }

                if (event.type === "error")
                    root.lastError = event.message || "Codex chat failed";

                root.chatEvent(root.activeSessionId, root.activeMessageId, event);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (chatProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                if (this.text.trim().length > 0) {
                    root.lastError = this.text.trim();
                    root.chatEvent(root.activeSessionId, root.activeMessageId, {
                        type: "error",
                        message: root.lastError
                    });
                }
            }
        }

        onStarted: {
            chatProcess.write(root.pendingPayload + "\n");
        }

        onRunningChanged: {
            if (!running) {
                root.chatBusy = false;
                root.pendingPayload = "";
            }
        }
    }

    Process {
        id: titleProcess
        property int requestEpoch: -1
        stdinEnabled: true

        stdout: SplitParser {
            onRead: function(data) {
                if (titleProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                const event = root.parseLine(data);
                if (!event)
                    return;

                if (event.type === "debug")
                    return;

                if (event.type === "error")
                    root.lastError = event.message || "Codex title generation failed";

                root.titleEvent(root.activeTitleSessionId, event);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (titleProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                if (this.text.trim().length > 0) {
                    root.lastError = this.text.trim();
                    root.titleEvent(root.activeTitleSessionId, {
                        type: "error",
                        message: root.lastError
                    });
                }
            }
        }

        onStarted: {
            titleProcess.write(root.pendingTitlePayload + "\n");
        }

        onRunningChanged: {
            if (!running) {
                root.titleBusy = false;
                root.activeTitleSessionId = "";
                root.pendingTitlePayload = "";
            }
        }
    }

    Process {
        id: stateLoadProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const event = root.parseLine(line);
                    if (!event)
                        continue;

                    if (event.type === "state") {
                        root.stateLoaded(event.state || {}, event);
                    } else if (event.type === "error") {
                        root.lastError = event.message || "AI state load failed";
                        root.statePersistenceError(root.lastError);
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    root.lastError = this.text.trim();
                    root.statePersistenceError(root.lastError);
                }
            }
        }

        onRunningChanged: {
            if (!running)
                root.stateLoadBusy = false;
        }
    }

    Process {
        id: stateSaveProcess
        stdinEnabled: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const event = root.parseLine(line);
                    if (!event)
                        continue;

                    if (event.type === "state_saved") {
                        root.stateSaved(event);
                    } else if (event.type === "error") {
                        root.lastError = event.message || "AI state save failed";
                        root.statePersistenceError(root.lastError);
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    root.lastError = this.text.trim();
                    root.statePersistenceError(root.lastError);
                }
            }
        }

        onStarted: {
            stateSaveProcess.write(root.pendingStatePayload + "\n");
        }

        onRunningChanged: {
            if (!running) {
                root.stateSaveBusy = false;
                root.pendingStatePayload = "";
                if (root.queuedStatePayload.length > 0) {
                    const nextPayload = root.queuedStatePayload;
                    root.queuedStatePayload = "";
                    root.pendingStatePayload = nextPayload;
                    root.stateSaveBusy = true;
                    stateSaveProcess.exec(root.helperCommand("state-save"));
                }
            }
        }
    }

    Process {
        id: modelsLoadProcess
        property int requestEpoch: -1

        stdout: StdioCollector {
            onStreamFinished: {
                if (modelsLoadProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const event = root.parseLine(line);
                    if (!event)
                        continue;

                    if (event.type === "models") {
                        root.applyModels(event);
                        root.modelsLoaded(root.codexModels, event);
                    } else if (event.type === "error") {
                        root.lastError = event.message || "AI model cache load failed";
                        root.modelsRefreshError(root.lastError);
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (modelsLoadProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                if (this.text.trim().length > 0) {
                    root.lastError = this.text.trim();
                    root.modelsRefreshError(root.lastError);
                }
            }
        }

        onRunningChanged: {
            if (!running)
                root.modelsLoadBusy = false;
        }
    }

    Process {
        id: modelsRefreshProcess
        property int requestEpoch: -1

        stdout: StdioCollector {
            onStreamFinished: {
                if (modelsRefreshProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const event = root.parseLine(line);
                    if (!event)
                        continue;

                    if (event.type === "models") {
                        root.applyModels(event);
                        root.modelsRefreshed(root.codexModels, event);
                    } else if (event.type === "error") {
                        root.lastError = event.message || "AI model refresh failed";
                        root.modelsRefreshError(root.lastError);
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (modelsRefreshProcess.requestEpoch !== root.authenticationEpoch)
                    return;
                if (this.text.trim().length > 0) {
                    root.lastError = this.text.trim();
                    root.modelsRefreshError(root.lastError);
                }
            }
        }

        onRunningChanged: {
            if (!running)
                root.modelsRefreshBusy = false;
        }
    }

    Component.onCompleted: root.refreshStatus()
}
