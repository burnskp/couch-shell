import QtQuick
import Quickshell
import "../../services" as Services
import "../../modules/bar/widgets" as Widgets
import "../../modules/bar/popups" as Popups

ShellRoot {
    id: root
    property int phase: 0
    property int ticks: 0
    property bool lateUsage: false

    function fail(message) {
        console.error("USAGE_FAILURE: " + message);
        Qt.quit();
    }

    Item {
        Widgets.AiUsageWidget { id: firstWidget }
        Widgets.AiUsageWidget { id: secondWidget; y: 40 }
        Popups.AiUsageHover { id: hover; width: 292; y: 80 }
    }

    Connections {
        target: Services.AiChatService
        function onUsageReceived(provider) {
            if (root.phase === 3 || root.phase === 8)
                root.lateUsage = true;
        }
    }

    Timer {
        interval: 30
        repeat: true
        running: true
        onTriggered: {
            root.ticks++;
            const state = Services.AiUsageState;
            const service = Services.AiChatService;
            if (root.ticks > 350) {
                root.fail("Timed out in phase " + root.phase);
                return;
            }
            if (root.phase === 0) {
                if (state.provider.status !== "ready" || service.usageBusy)
                    return;
                if (firstWidget.valueText !== "0:01" || secondWidget.valueText !== firstWidget.valueText || hover.implicitHeight <= 0 || firstWidget.width <= 0) {
                    root.fail("Initial shared chip and hover layout: " + firstWidget.valueText);
                    return;
                }
                root.phase = 1;
            } else if (root.phase === 1) {
                if (!service.usageBusy)
                    return;
                if (firstWidget.valueText !== "Unk" || service.requestUsage()) {
                    root.fail("Reset did not refresh once or allowed duplicate requests");
                    return;
                }
                root.phase = 2;
                root.ticks = 0;
            } else if (root.phase === 2) {
                // Let the hanging helper start before cancelling it.
                if (root.ticks < 10)
                    return;
                root.phase = 3;
                Services.BarManager.hide();
                root.ticks = 0;
            } else if (root.phase === 3) {
                if (root.ticks < 10)
                    return;
                if (service.usageBusy || service.requestUsage() || root.lateUsage || state.claudeBusy) {
                    root.fail("Hidden work or late output survived cancellation");
                    return;
                }
                root.phase = 4;
                Services.BarManager.show();
            } else if (root.phase === 4) {
                if (state.provider.status !== "ready" || service.usageBusy || state.providerById("claude").status !== "ready")
                    return;
                if (firstWidget.valueText !== "70%") {
                    root.fail("Show did not refresh usage");
                    return;
                }
                const codexGlyph = firstWidget.iconGlyph;
                state.selectNext();
                if (firstWidget.valueText !== "40%" || secondWidget.valueText !== "40%" || firstWidget.iconGlyph !== codexGlyph || state.title !== "Claude") {
                    root.fail("Switching did not show Claude usage: " + firstWidget.valueText);
                    return;
                }
                // Refreshing usage must not change the selected provider.
                state.refreshClaude();
                if (!state.claudeBusy || state.selectedProviderId !== "claude") {
                    root.fail("Claude refresh did not start or changed the selection");
                    return;
                }
                root.phase = 9;
            } else if (root.phase === 9) {
                if (state.claudeBusy || state.provider.status !== "ready")
                    return;
                if (state.selectedProviderId !== "claude" || firstWidget.valueText !== "40%") {
                    root.fail("Claude refresh switched the shown provider");
                    return;
                }
                state.selectNext();
                if (firstWidget.valueText !== "70%" || state.selectedProviderId !== "openai-codex") {
                    root.fail("Switching back did not show ChatGPT usage");
                    return;
                }
                service.applyStatus({ configured: true, accountId: "replacement" });
                if (state.provider.windows.length !== 0) {
                    root.fail("Account switch retained the previous quota");
                    return;
                }
                root.phase = 5;
            } else if (root.phase === 5) {
                if (state.provider.status !== "ready" || service.usageBusy)
                    return;
                state.refresh();
                root.phase = 6;
            } else if (root.phase === 6) {
                if (state.provider.status !== "error" || service.usageBusy)
                    return;
                if (firstWidget.valueText !== "Unk" || !state.stale || state.provider.windows.length !== 1 || service.lastError !== "") {
                    root.fail("Failure did not retain stale hover data separately from chat errors");
                    return;
                }
                state.refresh();
                root.ticks = 0;
                root.phase = 7;
            } else if (root.phase === 7) {
                if (root.ticks < 10)
                    return;
                root.phase = 8;
                service.logout();
                root.ticks = 0;
            } else if (root.phase === 8) {
                if (root.ticks < 10 || service.logoutBusy)
                    return;
                if (service.usageBusy || state.provider.windows.length || root.lateUsage || service.lastError !== "" || service.requestUsage()) {
                    root.fail("Logout did not clear usage and reject late output");
                    return;
                }
                console.log("USAGE_OK");
                Qt.quit();
            }
        }
    }
}
