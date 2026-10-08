pragma Singleton

import Quickshell.Io
import "internal" as Internal

Internal.BarVisibilityState {
    id: root

    readonly property IpcHandler barIpc: IpcHandler {
        target: "bar"

        function show() {
            root.show();
        }

        function hide() {
            root.hide();
        }

        function toggle() {
            root.toggle();
        }
    }
}
