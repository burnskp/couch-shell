function isVisibleWorkspace(workspace) {
	if (!workspace || typeof workspace.id !== "number") {
		return false;
	}

	const name = typeof workspace.name === "string" ? workspace.name : "";
	return workspace.id > 0 && !name.startsWith("special:");
}

function displayName(workspace) {
	if (!workspace) {
		return "?";
	}

	const name = typeof workspace.name === "string" ? workspace.name : "";
	const trimmed = name.trim();

	if (trimmed.length === 0 || trimmed.startsWith("special:")) {
		return String(workspace.id ?? "?");
	}

	const numberedName = trimmed.match(/^\d+[:\s-]+(.+)$/);
	if (numberedName?.[1]) {
		return numberedName[1];
	}

	return trimmed;
}

function sortWorkspaces(workspaces) {
	return (workspaces || [])
		.filter(isVisibleWorkspace)
		.slice()
		.sort((left, right) => {
			if (left.id !== right.id) {
				return left.id - right.id;
			}

			return displayName(left).localeCompare(displayName(right));
		});
}
