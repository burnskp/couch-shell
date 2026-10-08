import QtQuick
import Quickshell
import "../../services" as Services

ShellRoot {
    id: root
    property int phase: 0
    property bool lateEvent: false
    readonly property bool removalFails: Quickshell.env("COUCH_TEST_REMOVE_FAIL") !== "0"

    function fail(message) {
        console.error("AUTH_FAILURE: " + message);
        Qt.quit();
    }
    Connections {
        target: Services.AiChatService
        function onChatEvent(sessionId, messageId, event) {
            if (event.type === "text_delta")
                root.lateEvent = true;
        }
        function onTitleEvent(sessionId, event) {
            if (event.type === "text_delta")
                root.lateEvent = true;
        }
        function onModelsRefreshed(models, event) {
            root.lateEvent = true;
        }
    }
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            const service = Services.AiChatService;
            if (root.phase === 0) {
                if (!service.configured)
                    return;
                service.sendChat("session", "message", {});
                service.generateTitle("session", {});
                service.refreshModels();
                service.refreshStatus();
                root.phase = 1;
            } else if (root.phase === 1) {
                service.logout();
                if (!service.logoutBusy || !service.authenticatedWorkBlocked || !service.configured) {
                    root.fail("Logout did not block work before removing credentials");
                    return;
                }
                if (service.sendChat("late", "late", {}) || service.generateTitle("late", {}) || service.refreshModels()) {
                    root.fail("Authenticated work started during logout");
                    return;
                }
                root.phase = 2;
            } else {
                if (service.logoutBusy)
                    return;
                if (root.lateEvent || service.chatBusy || service.titleBusy || service.modelsRefreshBusy) {
                    root.fail("Cancelled helpers leaked events or remained busy");
                    return;
                }
                if (root.removalFails) {
                    if (!service.configured || service.accountId !== "original" || service.lastError !== (Quickshell.env("COUCH_TEST_REMOVE_FAIL") === "start" ? "Could not start credential removal helper" : "removal denied")) {
                        root.fail("Removal failure did not preserve account state and report error: " + service.lastError);
                        return;
                    }
                } else if (service.configured || service.accountId !== "" || service.lastError !== "") {
                    root.fail("Successful logout retained account state or late errors: " + service.lastError);
                    return;
                }
                console.log("AUTH_OK");
                Qt.quit();
            }
        }
    }
}
