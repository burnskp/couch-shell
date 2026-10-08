function parseBlocks(markdown) {
	const source = markdown || "";
	const lines = source.split("\n");
	const blocks = [];
	let textLines = [];
	let codeLines = [];
	let inCode = false;
	let language = "";

	function pushText() {
		while (textLines.length > 0 && /^[ \t]*$/.test(textLines[0]))
			textLines.shift();
		while (
			textLines.length > 0 &&
			/^[ \t]*$/.test(textLines[textLines.length - 1])
		)
			textLines.pop();
		if (textLines.length > 0)
			blocks.push({ type: "text", text: textLines.join("\n") });
		textLines = [];
	}

	function pushCode() {
		blocks.push({
			type: "code",
			text: codeLines.join("\n"),
			language: language,
		});
		codeLines = [];
		language = "";
	}

	for (let i = 0; i < lines.length; i++) {
		const line = lines[i];
		const fenceLine = line.replace(/^\s+/, "");
		if (fenceLine.indexOf("```") === 0) {
			if (inCode) {
				pushCode();
				inCode = false;
			} else {
				pushText();
				inCode = true;
				language = fenceLine.slice(3).trim();
			}
			continue;
		}

		if (inCode) codeLines.push(line);
		else textLines.push(line);
	}

	if (inCode) pushCode();
	else pushText();

	return blocks;
}

function isExternalLink(link) {
	return /^https?:\/\//i.test(String(link || "").trim());
}

function isEscaped(source, index) {
	let backslashCount = 0;
	for (let i = index - 1; i >= 0 && source[i] === "\\"; i--) backslashCount++;

	return backslashCount % 2 === 1;
}

function hasClosingBacktickRun(source, start, runLength) {
	for (let i = start; i < source.length; ) {
		if (source[i] !== "`") {
			i++;
			continue;
		}

		let end = i + 1;
		while (end < source.length && source[end] === "`") end++;

		if (end - i === runLength) return true;

		i = end;
	}

	return false;
}

function markdownCodeBlockRanges(source) {
	const ranges = [];
	const lines = [];
	let lineStart = 0;

	for (let i = 0; i <= source.length; i++) {
		if (i !== source.length && source[i] !== "\n") continue;

		let textEnd = i;
		if (textEnd > lineStart && source[textEnd - 1] === "\r") textEnd--;
		lines.push({
			start: lineStart,
			end: i < source.length ? i + 1 : i,
			text: source.slice(lineStart, textEnd),
		});
		lineStart = i + 1;
	}

	let fence = null;
	let rangeStart = -1;
	let inIndentedCode = false;
	let paragraphOpen = false;

	function pushRange(end) {
		if (rangeStart >= 0 && end > rangeStart)
			ranges.push({ start: rangeStart, end: end });
		rangeStart = -1;
	}

	function openingFence(line) {
		const match = /^ {0,3}(`{3,}|~{3,})(.*)$/.exec(line);
		if (!match || (match[1][0] === "`" && match[2].indexOf("`") >= 0))
			return null;

		return { character: match[1][0], length: match[1].length };
	}

	function isClosingFence(line, activeFence) {
		const match = /^ {0,3}(`+|~+)[ \t]*$/.exec(line);
		return (
			!!match &&
			match[1][0] === activeFence.character &&
			match[1].length >= activeFence.length
		);
	}

	for (let i = 0; i < lines.length; i++) {
		const line = lines[i];

		if (fence) {
			if (isClosingFence(line.text, fence)) {
				pushRange(line.end);
				fence = null;
				paragraphOpen = false;
			}
			continue;
		}

		const newFence = openingFence(line.text);
		if (newFence) {
			if (inIndentedCode) {
				pushRange(line.start);
				inIndentedCode = false;
			}
			fence = newFence;
			rangeStart = line.start;
			continue;
		}

		const blank = /^[ \t]*$/.test(line.text);
		const indented = /^(?: {4}|\t)/.test(line.text);

		if (inIndentedCode) {
			if (blank || indented) continue;

			pushRange(line.start);
			inIndentedCode = false;
		}

		if (indented && !paragraphOpen) {
			rangeStart = line.start;
			inIndentedCode = true;
		} else if (blank) {
			paragraphOpen = false;
		} else {
			paragraphOpen = true;
		}
	}

	if (fence || inIndentedCode) pushRange(source.length);

	return ranges;
}

function htmlTagEnd(source, start) {
	let quote = "";
	for (let i = start + 1; i < source.length; i++) {
		const character = source[i];
		if (quote.length > 0) {
			if (character === quote) quote = "";
		} else if (character === '"' || character === "'") {
			quote = character;
		} else if (character === ">") {
			return i;
		}
	}

	return -1;
}

function htmlAttribute(tag, name) {
	const pattern = new RegExp(
		"\\b" + name + "\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s\"'=<>`]+))",
		"i",
	);
	const match = pattern.exec(tag);
	if (!match) return "";

	return match[1] || match[2] || match[3] || "";
}

function markdownLink(label, target) {
	const safeLabel = String(label || "image").replace(/([\\[\]])/g, "\\$1");
	const safeTarget = String(target || "")
		.replace(/([\\()])/g, "\\$1")
		.replace(/[\r\n]/g, "");
	return safeTarget.length > 0
		? "[" + safeLabel + "](" + safeTarget + ")"
		: safeLabel;
}

function htmlImageLink(source, start) {
	if (source.slice(start, start + 4).toLowerCase() !== "<img") return null;

	const boundary = source[start + 4] || "";
	if (boundary.length > 0 && !/[\s/>]/.test(boundary)) return null;

	const end = htmlTagEnd(source, start);
	if (end < 0) return null;

	const tag = source.slice(start, end + 1);
	return {
		end: end,
		text: markdownLink(
			htmlAttribute(tag, "alt") || "image",
			htmlAttribute(tag, "src"),
		),
	};
}

function renderImagesAsLinks(markdown) {
	const source = String(markdown || "");
	const codeBlockRanges = markdownCodeBlockRanges(source);
	let result = "";
	let codeDelimiterLength = 0;
	let codeBlockIndex = 0;

	for (let i = 0; i < source.length; ) {
		while (
			codeBlockIndex < codeBlockRanges.length &&
			i >= codeBlockRanges[codeBlockIndex].end
		)
			codeBlockIndex++;

		if (
			codeBlockIndex < codeBlockRanges.length &&
			i >= codeBlockRanges[codeBlockIndex].start
		) {
			const codeBlockEnd = codeBlockRanges[codeBlockIndex].end;
			result += source.slice(i, codeBlockEnd);
			i = codeBlockEnd;
			codeDelimiterLength = 0;
			continue;
		}

		if (
			source[i] === "`" &&
			(codeDelimiterLength > 0 || !isEscaped(source, i))
		) {
			let end = i + 1;
			while (end < source.length && source[end] === "`") end++;

			const runLength = end - i;
			if (codeDelimiterLength === runLength) codeDelimiterLength = 0;
			else if (
				codeDelimiterLength === 0 &&
				hasClosingBacktickRun(source, end, runLength)
			)
				codeDelimiterLength = runLength;

			result += source.slice(i, end);
			i = end;
			continue;
		}

		if (codeDelimiterLength === 0 && source[i] === "<") {
			const imageLink = htmlImageLink(source, i);
			if (imageLink) {
				result += imageLink.text;
				i = imageLink.end + 1;
				continue;
			}
		}

		if (
			codeDelimiterLength === 0 &&
			source[i] === "!" &&
			source[i + 1] === "[" &&
			!isEscaped(source, i)
		) {
			if (result[result.length - 1] === "!")
				result = result.slice(0, -1) + "&#33;";
			if (source[i + 2] === "]") {
				result += "[image]";
				i += 3;
			} else {
				i++;
			}
			continue;
		}

		result += source[i];
		i++;
	}

	return result;
}
