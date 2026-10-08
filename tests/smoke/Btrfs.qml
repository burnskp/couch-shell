import Quickshell
import QtQuick
import "../../services" as Services
import "../../modules/bar/popups" as Popups

ShellRoot {
    id: root
    property int stage: 0
    property bool failed: false
    function check(condition, message) {
        if (!condition) {
            failed = true;
            console.error("COUCH_SHELL_SMOKE_FAILURE: " + message);
            Qt.quit();
        }
    }
    Popups.DiskHover {
        id: popup
        width: 320
    }
    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            if (root.failed) return;
            if (root.stage === 0) {
                root.check(Services.SystemStatsState.btrfsPollingActive, "Btrfs polling did not start");
                root.check(Services.SystemStatsState.btrfsQueryRunning, "Btrfs client did not start immediately");
                Services.BarManager.hide();
            } else if (root.stage === 1) {
                root.check(!Services.SystemStatsState.btrfsPollingActive, "Btrfs timer stayed active while hidden");
                root.check(!Services.SystemStatsState.btrfsQueryRunning, "Btrfs client was not cancelled");
                Services.BarManager.show();
            } else if (root.stage === 2) {
                root.check(Services.SystemStatsState.btrfsQueryRunning, "Btrfs client did not restart on show");
            } else if (root.stage === 8) {
                root.check(Services.SystemStatsState.btrfsCards.length === 1, "Btrfs report did not render");
                root.check(Services.SystemStatsState.btrfsQueryRunning, "Btrfs interval did not refresh");
                root.check(popup.implicitHeight > 0 && popup.implicitHeight < 800, "Btrfs popup height was not capped");
                root.check(Services.SystemStatsState.diskPaths.length === 1, "Btrfs mode queried manual popup paths");
                console.info("COUCH_SHELL_BTRFS_SMOKE_OK");
                Qt.quit();
            }
            root.stage++;
        }
    }
}
