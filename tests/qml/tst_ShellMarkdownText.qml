import QtQuick
import QtTest
import "../../ui/ShellMarkdownTextLogic.js" as MarkdownLogic
import "../../modules/panes/ai/AiMessageBubbleLogic.js" as MessageLogic

TestCase {
    id: testCase

    name: "ShellMarkdownText"
    when: windowShown
    width: 640
    height: 480

    Component {
        id: markdownComponent

        TextEdit {
            width: 520
            readOnly: true
            selectByMouse: true
            selectByKeyboard: true
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.MarkdownText
        }
    }

    function test_unfenced_content_uses_native_markdown() {
        const markdown = "# Heading\n\n**Bold** and _emphasis_ with `inline code`.\n\n" +
            "- first\n- second\n\n| Name | Value |\n| --- | --- |\n| Link | [Qt](https://www.qt.io) |\n\n" +
            "Plain URL: https://example.com/docs";
        const item = createTemporaryObject(markdownComponent, testCase, { text: markdown });
        verify(item);
        wait(0);

        compare(item.textFormat, TextEdit.MarkdownText);
        compare(item.readOnly, true);
        compare(item.selectByMouse, true);
        verify(item.text.includes("# Heading"));
        verify(item.text.includes("**Bold**"));
        verify(item.text.includes("|Name|Value|"));
        verify(item.text.includes("[Qt](https://www.qt.io)"));
        verify(item.text.includes("<https://example.com/docs>"));
    }

    function test_mixed_markdown_and_fenced_code_stays_separate() {
        const source = "## Before\n\n```qml\nText { text: \"hello\" }\n```\n\n- After";
        const blocks = MarkdownLogic.parseBlocks(source);
        compare(blocks.length, 3);
        compare(blocks[0].type, "text");
        compare(blocks[1].type, "code");
        compare(blocks[1].language, "qml");
        compare(blocks[1].text, "Text { text: \"hello\" }");
        compare(blocks[2].type, "text");
    }

    function test_images_render_as_links_without_changing_code() {
        const remoteImage = "![tracking pixel](https://example.com/pixel.png)";
        const localImage = "![diagram](file:///tmp/diagram.png)";
        const referenceImage = "![preview][asset]\n\n[asset]: http://127.0.0.1/private.png";

        compare(MarkdownLogic.renderImagesAsLinks(remoteImage), "[tracking pixel](https://example.com/pixel.png)");
        compare(MarkdownLogic.renderImagesAsLinks(localImage), "[diagram](file:///tmp/diagram.png)");
        compare(MarkdownLogic.renderImagesAsLinks(referenceImage), "[preview][asset]\n\n[asset]: http://127.0.0.1/private.png");
        compare(MarkdownLogic.renderImagesAsLinks("![](https://example.com/image.png)"), "[image](https://example.com/image.png)");
        compare(MarkdownLogic.renderImagesAsLinks("<img alt=\"preview\" src=\"https://example.com/image.png\">"), "[preview](https://example.com/image.png)");
        compare(MarkdownLogic.renderImagesAsLinks("<IMG SRC='file:///tmp/image.png'>"), "[image](file:///tmp/image.png)");
        compare(MarkdownLogic.renderImagesAsLinks("`![literal](https://example.com/image.png)`"), "`![literal](https://example.com/image.png)`");
        compare(MarkdownLogic.renderImagesAsLinks("\\`![escaped delimiters](https://example.com/image.png)\\`"), "\\`[escaped delimiters](https://example.com/image.png)\\`");
        compare(MarkdownLogic.renderImagesAsLinks("\\![escaped](https://example.com/image.png)"), "\\![escaped](https://example.com/image.png)");
        compare(MarkdownLogic.renderImagesAsLinks("unmatched ` then ![image](https://example.com/image.png)"), "unmatched ` then [image](https://example.com/image.png)");
        verify(!MarkdownLogic.renderImagesAsLinks("!![image](https://example.com/image.png)").includes("![image]"));

        const item = createTemporaryObject(markdownComponent, testCase, {
            text: MarkdownLogic.renderImagesAsLinks(remoteImage)
        });
        verify(item);
        wait(0);
        verify(item.text.includes("[tracking pixel](https://example.com/pixel.png)"));
        verify(!item.text.includes("![tracking pixel]"));
    }

    function test_images_stay_literal_in_native_markdown_code_blocks() {
        const tildeFence = "~~~markdown\n![diagram](https://example.com/diagram.png)\n<img src=\"https://example.com/other.png\">\n~~~";
        const indented = "    ![diagram](https://example.com/diagram.png)\n\t<img src=\"https://example.com/other.png\">";
        const indentedBlock = MarkdownLogic.parseBlocks(indented);

        compare(MarkdownLogic.renderImagesAsLinks(tildeFence), tildeFence);
        compare(MarkdownLogic.renderImagesAsLinks(indented), indented);
        compare(indentedBlock.length, 1);
        compare(indentedBlock[0].text, indented);
        compare(MarkdownLogic.renderImagesAsLinks(indentedBlock[0].text), indented);
        compare(MarkdownLogic.renderImagesAsLinks("Paragraph\n\n    ![image](https://example.com/image.png)"), "Paragraph\n\n    ![image](https://example.com/image.png)");
        compare(MarkdownLogic.renderImagesAsLinks("Paragraph\n    ![image](https://example.com/image.png)"), "Paragraph\n    [image](https://example.com/image.png)");
    }

    function test_only_http_links_are_external() {
        compare(MarkdownLogic.isExternalLink("https://example.com"), true);
        compare(MarkdownLogic.isExternalLink("HTTP://example.com"), true);
        compare(MarkdownLogic.isExternalLink("mailto:user@example.com"), false);
        compare(MarkdownLogic.isExternalLink("file:///tmp/example"), false);
        compare(MarkdownLogic.isExternalLink("javascript:alert(1)"), false);
        compare(MarkdownLogic.isExternalLink("/relative/path"), false);
    }

    function test_message_copy_uses_exact_raw_content() {
        const raw = "# Raw heading\n\n```js\nconst value = `$HOME`;\n```\n";
        const message = { content: raw, pending: true };

        compare(MessageLogic.rawContent(message), raw);
        compare(MessageLogic.canCopy(message), true);
        compare(MessageLogic.copyArguments(message)[4], raw);
        compare(MessageLogic.shouldShowCopied(false), false);
        compare(MessageLogic.shouldShowCopied(true), true);
    }

    function test_message_copy_empty_and_streaming_states() {
        const empty = { content: "", pending: true };
        const partial = { content: "partial **stream**", pending: true };

        compare(MessageLogic.canCopy(empty), false);
        compare(MessageLogic.canCopy(partial), true);
        compare(MessageLogic.copyArguments(partial)[4], "partial **stream**");
    }
}
