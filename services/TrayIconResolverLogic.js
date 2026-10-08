function isNonEmptyString(value) {
	return typeof value === "string" && value.length > 0;
}

function pushUnique(list, value) {
	if (isNonEmptyString(value) && list.indexOf(value) === -1) list.push(value);
}

function normalizedSource(icon) {
	if (!isNonEmptyString(icon)) return "";

	if (
		icon.startsWith("image://") ||
		icon.startsWith("file://") ||
		icon.startsWith("qrc:/")
	)
		return icon;

	if (icon.indexOf("?path=") !== -1) {
		const [name, path] = icon.split("?path=");
		const fileName = name.slice(name.lastIndexOf("/") + 1);
		const normalizedPath = path.endsWith("/") ? path.slice(0, -1) : path;
		return `file://${normalizedPath}/${fileName}`;
	}

	if (icon.startsWith("/")) return `file://${icon}`;

	return icon;
}

function isSourceLikeIcon(icon) {
	return (
		isNonEmptyString(icon) &&
		(icon.startsWith("/") ||
			icon.startsWith("file://") ||
			icon.startsWith("image://") ||
			icon.startsWith("qrc:/") ||
			icon.indexOf("://") !== -1 ||
			icon.indexOf("?path=") !== -1)
	);
}

function sourceCandidates(icon, resolvedThemeIcon, defaultIconSource) {
	if (!isNonEmptyString(icon)) return [defaultIconSource];

	const candidates = [];

	pushUnique(candidates, resolvedThemeIcon);

	if (isSourceLikeIcon(icon)) pushUnique(candidates, normalizedSource(icon));

	pushUnique(candidates, defaultIconSource);

	return candidates;
}

function notificationIconCandidates(
	appCandidates,
	desktopCandidates,
	defaultIconSource,
) {
	const candidates = [];

	for (const candidate of appCandidates || []) {
		if (candidate !== defaultIconSource) pushUnique(candidates, candidate);
	}

	for (const candidate of desktopCandidates || []) {
		if (candidate !== defaultIconSource) pushUnique(candidates, candidate);
	}

	pushUnique(candidates, defaultIconSource);
	return candidates;
}
