function transcriptIsVisible(activeTranscriptCount) {
	return Number(activeTranscriptCount || 0) > 0;
}

function notificationPreview(text) {
	const compact = String(text || "")
		.replace(/\s+/g, " ")
		.trim();
	if (compact.length === 0) return "The response has finished writing.";
	if (compact.length > 180) return compact.slice(0, 177).trim() + "…";
	return compact;
}

function streamUpdateOverrides(message, pending) {
	return {
		content: (message.content || "") + (pending.content || ""),
		reasoning: (message.reasoning || "") + (pending.reasoning || ""),
		pending: true,
	};
}
