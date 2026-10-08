import QtQuick
import Quickshell
import "../../ui" as Ui

ShellRoot {
    id: root
    readonly property string url: Quickshell.env("COUCH_MARKDOWN_URL")
    readonly property var samples: [
        "`\n\n![paragraph](" + url + ")\n\n`",
        "<!--\n~~~\n-->\n![comment](" + url + ")\n~~~",
        "![ordinary](" + url + ")",
        "![reference][asset]\n\n[asset]: " + url,
        "<img src=\"" + url + "\">"
    ]
    property int sample: 0
    property int prefix: 0

    function findItem(item, name) {
        if (item.objectName === name)
            return item;
        for (const child of item.children || []) {
            const found = findItem(child, name);
            if (found)
                return found;
        }
        return null;
    }

    function fail(message) {
        console.error("MARKDOWN_FAILURE: " + message);
        Qt.quit();
    }

    FloatingWindow {
        visible: true
        width: 600
        height: 480
        Ui.ShellMarkdownText {
            id: markdown
            width: 560
            text: root.samples[0]
        }
        Ui.ShellMarkdownText {
            id: code
            width: 560
            y: 240
            text: "```sh\n" + Quickshell.env("COUCH_COPY_TEXT") + "\n```"
        }
    }

    Timer {
        interval: 5
        running: true
        repeat: true
        onTriggered: {
            if (root.sample < root.samples.length) {
                markdown.text = root.samples[root.sample].slice(0, ++root.prefix);
                if (root.prefix >= root.samples[root.sample].length) {
                    root.prefix = 0;
                    root.sample += 1;
                }
                return;
            }
            stop();
            markdown.text = "# Heading\n\n**Bold** and *emphasis*";
            const prose = root.findItem(markdown, "markdownProseBlock");
            if (!prose || !prose.resourceGuardInstalled) {
                root.fail("Prose guard was not installed");
                return;
            }
            prose.selectAll();
            if (prose.selectedText.indexOf("Bold") < 0 || prose.selectedText.indexOf("**") >= 0) {
                root.fail("Formatted prose cannot be selected");
                return;
            }
            if (markdown.openExternalLink("file:///tmp/secret") || markdown.openExternalLink("javascript:alert(1)") || !markdown.isExternalLink("https://example.com")) {
                root.fail("Clicked-link restriction failed");
                return;
            }
            const codeBlock = root.findItem(code, "markdownCodeBlock");
            if (!codeBlock) {
                root.fail("Code block missing");
                return;
            }
            codeBlock.parent.copyCode();
            finish.start();
        }
    }
    Timer {
        id: finish
        interval: 300
        onTriggered: {
            console.log("MARKDOWN_OK");
            Qt.quit();
        }
    }
}
