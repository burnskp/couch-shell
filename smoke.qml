import Quickshell
import QtQuick
import "modules/bar" as Bar
import "modules/bar/popups" as Popups
import "services" as Services
import "ui" as Ui

ShellRoot {
    id: root

    property var systemStatsState: Services.SystemStatsState
    property bool observedUnloadedBar: false

    function fail(message) {
        console.error("COUCH_SHELL_SMOKE_FAILURE: " + message);
        Qt.quit();
    }

    Item {
        id: barHost

        width: 240
        height: 32

        Loader {
            id: barContentLoader

            anchors.fill: parent
            active: Services.BarManager.visible

            sourceComponent: Component {
                Bar.BarContent {
                    anchorWindow: null
                    barScreen: null
                }
            }
        }
    }

    Popups.DiskHover {
        width: 320
    }

    Ui.ShellMarkdownText {
        width: 240
        visible: false
        text: "Smoke [link](https://example.com)"
    }

    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            Services.BarManager.hide();
            // The next scheduled poll must repopulate the widget path while hidden.
            Services.SystemStatsState.diskResults = Object.create(null);
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: false
        onTriggered: {
            if (Services.SystemStatsState.diskQueryPathsRunning.some(path => path !== Services.ShellConfig.barDiskTextPath))
                root.fail("Popup-only disk queries were not cancelled on hide");
        }
    }

    Timer {
        interval: 15500
        running: true
        repeat: false
        onTriggered: {
            if (barContentLoader.item !== null) {
                root.fail("Bar content remained loaded after hide");
                return;
            }

            if (!Services.SystemStatsState.diskPollingActive || Services.SystemStatsState.diskQueryPathsRunning.some(path => path !== Services.ShellConfig.barDiskTextPath) || Services.SystemStatsState.btrfsPollingActive || Services.SystemStatsState.btrfsQueryRunning) {
                root.fail("Hidden disk monitoring or popup cancellation failed");
                return;
            }
            if (!Object.prototype.hasOwnProperty.call(Services.SystemStatsState.diskResults, Services.ShellConfig.barDiskTextPath)) {
                root.fail("Hidden disk monitoring did not retain the widget reading");
                return;
            }
            if (Object.keys(Services.SystemStatsState.diskResults).some(path => path !== Services.ShellConfig.barDiskTextPath)) {
                root.fail("Popup-only disk results were not cleared");
                return;
            }
            root.observedUnloadedBar = true;
            Services.BarManager.show();
        }
    }

    Timer {
        interval: 16000
        running: true
        repeat: false
        onTriggered: {
            if (!root.observedUnloadedBar || barContentLoader.item === null) {
                root.fail("Bar content did not survive the hide/show cycle");
                return;
            }

            if (!Services.SystemStatsState.diskPollingActive || Services.SystemStatsState.diskRows.length !== 2) {
                root.fail("Disk polling did not resume with default rows");
                return;
            }
            if (!Services.SystemStatsState.diskResults["/"]) {
                root.fail("Disk query did not produce root filesystem capacity");
                return;
            }
            console.log("COUCH_SHELL_SMOKE_OK");
            Qt.quit();
        }
    }
}
