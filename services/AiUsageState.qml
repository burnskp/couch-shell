pragma Singleton

import QtQuick
import "." as Services
import "AiUsageLogic.js" as Logic

Item {
    id: root

    // Future adapters publish this same provider/window model; auth stays with each provider.
    property var providers: [emptyProvider()]
    readonly property var provider: providers[0]
    property real now: Date.now()
    property string accountKey: ""
    property bool resetRefreshRequested: false
    readonly property bool authenticated: Services.AiChatService.configured && !Services.AiChatService.authenticatedWorkBlocked
    readonly property bool pollingEnabled: Services.BarManager.visible && authenticated && !Services.AiChatService.loginBusy
    readonly property var summary: Logic.summary(provider, now)
    readonly property bool stale: provider.windows.length > 0 && (provider.status !== "ready" || Logic.expired(provider, now))
    readonly property string message: !authenticated ? "Sign in through Couch AI to track your subscription."
        : provider.error || (stale ? "Refreshing usage… Previous reading is stale."
        : provider.status === "loading" ? "Loading subscription usage…" : "")

    function emptyProvider() {
        return { id: "openai-codex", name: "ChatGPT", plan: "", status: "idle", updatedAt: 0, error: "", windows: [] };
    }

    function refresh() {
        if (!root.pollingEnabled)
            return;
        root.now = Date.now();
        if (Services.AiChatService.requestUsage())
            root.providers = [Object.assign({}, root.provider, { status: "loading", error: "" })];
    }

    function syncAccount() {
        const key = root.authenticated ? Services.AiChatService.accountId + ":" + Services.AiChatService.authenticationEpoch : "";
        if (key !== root.accountKey || !root.authenticated) {
            Services.AiChatService.cancelUsage();
            root.accountKey = key;
            root.providers = [root.emptyProvider()];
            root.resetRefreshRequested = false;
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
        target: Services.AiChatService
        function onStatusUpdated() { root.syncAccount(); }
        function onUsageReceived(provider) {
            root.now = Date.now();
            root.providers = [Object.assign({}, provider, { status: "ready", error: "" })];
            // A server can briefly return the previous window after reset. Retry on the normal interval.
            root.resetRefreshRequested = Logic.expired(root.provider, root.now);
        }
        function onUsageFailed(message) {
            root.providers = [Object.assign({}, root.provider, { status: "error", error: message })];
        }
    }

    Timer {
        interval: 60000
        running: root.pollingEnabled
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: countdownTimer
        interval: Math.max(1, Logic.nextTick(root.provider.windows, root.now))
        running: root.pollingEnabled && root.provider.windows.length > 0
        repeat: true
        onTriggered: {
            root.now = Date.now();
            if (!root.resetRefreshRequested && Logic.expired(root.provider, root.now)) {
                root.resetRefreshRequested = true;
                root.refresh();
            }
        }
    }

    Component.onCompleted: root.syncAccount()
}
