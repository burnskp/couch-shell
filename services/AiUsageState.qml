pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "." as Services
import "AiUsageLogic.js" as Logic

Item {
    id: root

    // Every provider publishes the same provider/window model; auth stays with each provider.
    property var providers: [emptyProvider("openai-codex", "ChatGPT"), emptyProvider("claude", "Claude")]
    // Only select() changes this; usage refreshes replace provider records but keep the selection.
    property string selectedProviderId: Services.ShellConfig.aiUsageDefaultProvider === "claude" ? "claude" : "openai-codex"
    readonly property var provider: providerById(selectedProviderId)
    readonly property string title: providerTitle(provider)
    // The hover lists the selected provider first, then the rest unless configured to show only it.
    readonly property var hoverProviders: Services.ShellConfig.aiUsageHoverProviders === "current" ? [provider]
        : [provider].concat(providers.filter(entry => entry.id !== provider.id))
    property real now: Date.now()
    property string accountKey: ""
    property var resetRefreshRequested: ({})
    readonly property bool authenticated: Services.AiChatService.configured && !Services.AiChatService.authenticatedWorkBlocked
    readonly property bool pollingEnabled: Services.BarManager.visible && authenticated && !Services.AiChatService.loginBusy
    readonly property var summary: Logic.summary(provider, now)
    readonly property bool stale: providerStale(provider)
    readonly property string message: providerMessage(provider)
    property var activeClaudeProcess: null
    readonly property bool claudeBusy: activeClaudeProcess !== null

    function emptyProvider(id, name) {
        return { id: id, name: name, plan: "", status: "idle", updatedAt: 0, error: "", windows: [] };
    }

    function providerTitle(entry) {
        return entry.id === "claude" ? "Claude" : "ChatGPT · Codex";
    }

    function providerStale(entry) {
        return entry.windows.length > 0 && (entry.status !== "ready" || Logic.expired(entry, root.now));
    }

    function providerMessage(entry) {
        return entry.id === "openai-codex" && !root.authenticated ? "Sign in through Couch AI to track your subscription."
            : entry.error || (root.providerStale(entry) ? "Refreshing usage… Previous reading is stale."
            : entry.status === "loading" ? "Loading subscription usage…" : "");
    }

    function providerById(id) {
        return root.providers.find(entry => entry.id === id) || root.providers[0];
    }

    function setProvider(id, patch) {
        root.providers = root.providers.map(entry => entry.id === id ? Object.assign({}, entry, patch) : entry);
    }

    function setResetRequested(id, requested) {
        const next = Object.assign({}, root.resetRefreshRequested);
        next[id] = requested;
        root.resetRefreshRequested = next;
    }

    function select(id) {
        if (root.providers.some(entry => entry.id === id))
            root.selectedProviderId = id;
    }

    function selectNext() {
        const ids = root.providers.map(entry => entry.id);
        root.select(ids[(ids.indexOf(root.selectedProviderId) + 1) % ids.length]);
    }

    function refresh() {
        if (!root.pollingEnabled)
            return;
        root.now = Date.now();
        if (Services.AiChatService.requestUsage())
            root.setProvider("openai-codex", { status: "loading", error: "" });
    }

    function refreshClaude() {
        if (root.claudeBusy || !Services.BarManager.visible)
            return;
        root.now = Date.now();
        root.activeClaudeProcess = claudeProcessComponent.createObject(root);
        root.activeClaudeProcess.exec(Services.AiChatService.helperCommand("claude-usage"));
        root.setProvider("claude", { status: "loading", error: "" });
    }

    function cancelClaude() {
        const process = root.activeClaudeProcess;
        root.activeClaudeProcess = null;
        if (process) {
            process.running = false;
            process.destroy();
        }
    }

    function claudeFailed(message) {
        root.setProvider("claude", { status: "error", error: message });
    }

    function syncAccount() {
        const key = root.authenticated ? Services.AiChatService.accountId + ":" + Services.AiChatService.authenticationEpoch : "";
        if (key !== root.accountKey || !root.authenticated) {
            Services.AiChatService.cancelUsage();
            root.accountKey = key;
            root.setProvider("openai-codex", root.emptyProvider("openai-codex", "ChatGPT"));
            root.setResetRequested("openai-codex", false);
        }
        root.refresh();
    }

    onAuthenticatedChanged: {
        if (!authenticated)
            root.syncAccount();
        else
            Qt.callLater(root.syncAccount);
    }

    onPollingEnabledChanged: {
        if (pollingEnabled)
            Qt.callLater(root.syncAccount);
        else {
            Services.AiChatService.cancelUsage();
            if (!root.authenticated)
                root.syncAccount();
        }
    }

    Connections {
        target: Services.BarManager
        function onVisibleChanged() {
            if (Services.BarManager.visible)
                Qt.callLater(root.refreshClaude);
            else
                root.cancelClaude();
        }
    }

    Connections {
        target: Services.AiChatService
        function onStatusUpdated() { root.syncAccount(); }
        function onUsageReceived(provider) {
            root.now = Date.now();
            root.setProvider("openai-codex", Object.assign({}, provider, { id: "openai-codex", status: "ready", error: "" }));
            // A server can briefly return the previous window after reset. Retry on the normal interval.
            root.setResetRequested("openai-codex", Logic.expired(root.providerById("openai-codex"), root.now));
        }
        function onUsageFailed(message) {
            root.setProvider("openai-codex", { status: "error", error: message });
        }
    }

    Component {
        id: claudeProcessComponent
        Process {
            id: claudeProcess
            property bool received: false
            readonly property bool current: root.activeClaudeProcess === claudeProcess && Services.BarManager.visible

            stdout: StdioCollector {
                onStreamFinished: {
                    if (!claudeProcess.current)
                        return;
                    claudeProcess.received = true;
                    try {
                        const event = JSON.parse(this.text);
                        if (event.type === "usage" && event.provider && Array.isArray(event.provider.windows) && event.provider.windows.length) {
                            root.now = Date.now();
                            root.setProvider("claude", Object.assign({}, event.provider, { id: "claude", status: "ready", error: "" }));
                            root.setResetRequested("claude", Logic.expired(root.providerById("claude"), root.now));
                        } else {
                            // The claude-usage helper only reports fixed, credential-free messages.
                            root.claudeFailed(event.type === "error" && typeof event.message === "string" && event.message.length
                                ? event.message : "Claude usage unavailable");
                        }
                    } catch (error) {
                        root.claudeFailed("Invalid Claude usage response");
                    }
                }
            }
            // Do not forward helper stderr, which can contain authentication details.
            stderr: StdioCollector {}
            function finish() {
                if (root.activeClaudeProcess !== claudeProcess)
                    return;
                if (claudeProcess.current && !claudeProcess.received)
                    root.claudeFailed("Claude usage helper failed");
                root.activeClaudeProcess = null;
                claudeProcess.destroy();
            }
            onRunningChanged: {
                if (!running)
                    Qt.callLater(claudeProcess.finish);
            }
        }
    }

    Timer {
        interval: 25000
        running: root.claudeBusy
        onTriggered: {
            root.cancelClaude();
            root.claudeFailed("Claude usage request timed out");
        }
    }

    Timer {
        interval: Services.ShellConfig.aiUsageRefreshInterval * 1000
        running: Services.BarManager.visible
        repeat: true
        onTriggered: {
            root.refresh();
            root.refreshClaude();
        }
    }

    Timer {
        id: countdownTimer
        readonly property var windows: root.providers.reduce((all, entry) => all.concat(entry.windows), [])
        interval: Math.max(1, Logic.nextTick(windows, root.now))
        running: Services.BarManager.visible && windows.length > 0
        repeat: true
        onTriggered: {
            root.now = Date.now();
            for (const entry of root.providers) {
                if (root.resetRefreshRequested[entry.id] || !Logic.expired(entry, root.now))
                    continue;
                root.setResetRequested(entry.id, true);
                if (entry.id === "claude")
                    root.refreshClaude();
                else
                    root.refresh();
            }
        }
    }

    Component.onCompleted: {
        root.syncAccount();
        root.refreshClaude();
    }
}
