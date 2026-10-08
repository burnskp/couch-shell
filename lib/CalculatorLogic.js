function evaluateDocument(text) {
	const source = typeof text === "string" ? text : "";
	const lines = source.split("\n");
	const results = [];
	let lastValidTotal = null;
	const endsWithNewline = source.endsWith("\n");

	for (let index = 0; index < lines.length; index += 1) {
		const line = lines[index];
		const isCommitted = endsWithNewline || index < lines.length - 1;
		const evaluation = evaluateLine(line, lastValidTotal, isCommitted);
		results.push(evaluation);

		if (evaluation.kind === "value") lastValidTotal = evaluation.total;
	}

	return {
		lines: results,
		currentTotal: lastValidTotal,
		currentTotalDisplay:
			lastValidTotal === null ? "" : formatNumber(lastValidTotal),
	};
}

function evaluateLine(line, previousTotal, isCommitted) {
	const source = typeof line === "string" ? line : "";
	const trimmed = source.trim();

	if (trimmed.length === 0) {
		return {
			kind: "blank",
			displayResult: "",
			total: null,
			negative: false,
		};
	}

	const continuationMatch = trimmed.match(/^([+\-*/])\s+(.+)$/);
	const firstCharacter = trimmed[0];

	try {
		let value;
		if (continuationMatch && previousTotal !== null) {
			value = parseExpressionText(
				`${formatInjectedNumber(previousTotal)} ${continuationMatch[1]} ${continuationMatch[2]}`,
			);
		} else if (
			(firstCharacter === "*" || firstCharacter === "/") &&
			previousTotal === null
		) {
			throw new Error("Missing previous total");
		} else {
			value = parseExpressionText(trimmed);
		}

		const normalizedValue = normalizeNumber(value);
		return {
			kind: "value",
			displayResult: formatNumber(normalizedValue),
			total: normalizedValue,
			negative: normalizedValue < 0,
		};
	} catch (_error) {
		if (!isCommitted && !shouldShowImmediateError(trimmed, previousTotal)) {
			return {
				kind: "pending",
				displayResult: "",
				total: null,
				negative: false,
			};
		}

		return {
			kind: "error",
			displayResult: "ERR",
			total: null,
			negative: false,
		};
	}
}

function shouldShowImmediateError(trimmedLine, _previousTotal) {
	if (/^[*/]/.test(trimmedLine)) return true;

	if (/^([+\-*/])\s+/.test(trimmedLine)) return true;

	return false;
}

function parseExpressionText(text) {
	const parser = new ExpressionParser(text);
	const value = parser.parseExpression();
	parser.skipWhitespace();

	if (!parser.atEnd()) throw new Error("Unexpected token");

	return value;
}

function formatInjectedNumber(value) {
	const normalizedValue = normalizeNumber(value);
	return normalizedValue < 0
		? `(${formatNumber(normalizedValue)})`
		: formatNumber(normalizedValue);
}

function formatNumber(value) {
	const normalizedValue = normalizeNumber(value);

	if (Math.abs(normalizedValue - Math.round(normalizedValue)) < 1e-10)
		return String(Math.round(normalizedValue));

	let formatted = normalizedValue.toFixed(10);
	formatted = formatted.replace(/\.0+$/, "");
	formatted = formatted.replace(/(\.\d*?)0+$/, "$1");
	return formatted;
}

function normalizeNumber(value) {
	if (!Number.isFinite(value)) throw new Error("Invalid number");

	return Object.is(value, -0) || Math.abs(value) < 1e-12 ? 0 : value;
}

function ExpressionParser(text) {
	this.text = typeof text === "string" ? text : "";
	this.index = 0;
}

ExpressionParser.prototype.atEnd = function () {
	return this.index >= this.text.length;
};

ExpressionParser.prototype.peek = function () {
	return this.text[this.index] || "";
};

ExpressionParser.prototype.skipWhitespace = function () {
	while (!this.atEnd() && /\s/.test(this.peek())) this.index += 1;
};

ExpressionParser.prototype.consume = function (character) {
	this.skipWhitespace();
	if (this.peek() !== character) return false;

	this.index += 1;
	return true;
};

ExpressionParser.prototype.parseExpression = function () {
	let value = this.parseTerm();

	while (true) {
		if (this.consume("+")) {
			value += this.parseTerm();
			continue;
		}

		if (this.consume("-")) {
			value -= this.parseTerm();
			continue;
		}

		break;
	}

	return value;
};

ExpressionParser.prototype.parseTerm = function () {
	let value = this.parseUnary();

	while (true) {
		if (this.consume("*")) {
			value *= this.parseUnary();
			continue;
		}

		if (this.consume("/")) {
			const divisor = this.parseUnary();
			if (divisor === 0) throw new Error("Division by zero");

			value /= divisor;
			continue;
		}

		break;
	}

	return value;
};

ExpressionParser.prototype.parseUnary = function () {
	this.skipWhitespace();

	if (this.consume("+")) return this.parseUnary();

	if (this.consume("-")) return -this.parseUnary();

	return this.parsePower();
};

ExpressionParser.prototype.parsePower = function () {
	let value = this.parsePrimary();

	if (this.consume("^")) value = value ** this.parseUnary();

	return value;
};

ExpressionParser.prototype.parsePrimary = function () {
	this.skipWhitespace();

	if (this.consume("(")) {
		const value = this.parseExpression();
		if (!this.consume(")")) throw new Error("Missing closing parenthesis");

		return value;
	}

	return this.parseNumber();
};

ExpressionParser.prototype.parseNumber = function () {
	this.skipWhitespace();
	const remainder = this.text.slice(this.index);
	const match = remainder.match(/^(?:\d+(?:\.\d*)?|\.\d+)/);

	if (!match) throw new Error("Expected number");

	this.index += match[0].length;
	return Number(match[0]);
};
