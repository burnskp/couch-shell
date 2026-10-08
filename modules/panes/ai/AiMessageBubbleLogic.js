function rawContent(message) {
	return message && typeof message.content === "string" ? message.content : "";
}

function canCopy(message) {
	return rawContent(message).length > 0;
}

function copyArguments(message) {
	return [
		"sh",
		"-c",
		'printf %s "$1" | wl-copy && printf copied',
		"sh",
		rawContent(message),
	];
}

function shouldShowCopied(succeeded) {
	return succeeded === true;
}
