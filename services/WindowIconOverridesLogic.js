function normalizedString(value) {
	return value === undefined || value === null ? "" : String(value).trim();
}

function lowercaseString(value) {
	return normalizedString(value).toLowerCase();
}

function pushUnique(values, value) {
	const stringValue = normalizedString(value);
	if (!stringValue.length || values.indexOf(stringValue) !== -1) return;

	values.push(stringValue);
}

function identifiersFor(toplevel) {
	const identifiers = [];

	if (!toplevel) return identifiers;

	pushUnique(identifiers, toplevel.initialClass);
	pushUnique(identifiers, toplevel.class);
	pushUnique(identifiers, toplevel.wayland?.appId);
	pushUnique(identifiers, toplevel.appId);
	pushUnique(identifiers, toplevel.lastIpcObject?.initialClass);
	pushUnique(identifiers, toplevel.lastIpcObject?.class);
	pushUnique(identifiers, toplevel.lastIpcObject?.appId);
	pushUnique(identifiers, toplevel.lastIpcObject?.wm_class);

	return identifiers;
}

function titlesFor(toplevel) {
	const titles = [];

	if (!toplevel) return titles;

	pushUnique(titles, toplevel.initialTitle);
	pushUnique(titles, toplevel.title);
	pushUnique(titles, toplevel.lastIpcObject?.initialTitle);
	pushUnique(titles, toplevel.lastIpcObject?.title);

	return titles;
}

function glyphFor(toplevel, rules) {
	const identifiers = identifiersFor(toplevel).map((identifier) =>
		lowercaseString(identifier),
	);
	const titles = titlesFor(toplevel).map((title) => lowercaseString(title));

	for (const rule of rules || []) {
		if (identifiers.indexOf(lowercaseString(rule.initialClass)) === -1)
			continue;

		if (
			rule.initialTitleContains &&
			!titles.some((title) =>
				title.includes(lowercaseString(rule.initialTitleContains)),
			)
		)
			continue;

		return normalizedString(rule.glyph);
	}

	return "";
}
