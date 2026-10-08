pragma Singleton

import QtQuick
import Quickshell.Io
import QtQml

Item {
    id: root

    property string username: ""
    property string hostname: ""

    readonly property string displayLabel: {
        if (username.length && hostname.length)
            return username + "@" + hostname;

        return username.length ? username : hostname;
    }

    function parseIdentity(output) {
        const lines = (output || "").split(/\r?\n/);

        for (const line of lines) {
            const separatorIndex = line.indexOf("=");
            if (separatorIndex === -1)
                continue;

            const key = line.slice(0, separatorIndex).trim();
            const value = line.slice(separatorIndex + 1).trim();

            if (key === "username")
                root.username = value;
            else if (key === "hostname")
                root.hostname = value;
        }
    }

    Process {
        id: identityProcess
        command: ["sh", "-lc", 'printf "username=%s\\nhostname=%s\\n" "$(id -un 2>/dev/null)" "$(hostname -s 2>/dev/null || hostname 2>/dev/null)"']

        stdout: StdioCollector {
            onStreamFinished: root.parseIdentity(this.text)
        }
    }

    Component.onCompleted: identityProcess.running = true
}
