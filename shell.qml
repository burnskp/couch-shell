//@ pragma UseQApplication
//@ pragma AppId io.github.burnskp.couchshell
//@ pragma DataDir $BASE/couch-shell
//@ pragma StateDir $BASE/couch-shell
//@ pragma CacheDir $BASE/couch-shell
import Quickshell
import "modules/bar" as Bar
import "modules/notifications" as Notifications
import "modules/panes" as Panes
import "modules/picker" as Picker

ShellRoot {
    Bar.IdleInhibitorWindow {}

    Variants {
        model: Quickshell.screens

        Bar.TopBar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Notifications.NotificationOverlay {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Panes.LeftPane {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Panes.RightPane {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Notifications.NotificationHistoryPanel {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Bar.SystemMenuPanel {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Picker.PickerOverlay {
            required property var modelData
            screen: modelData
        }
    }
}
