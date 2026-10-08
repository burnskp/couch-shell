function maxTitleBlockWidth(
	windowChipMinWidth,
	moduleLeadingWidth,
	windowMaxWidth,
) {
	return Math.max(
		windowChipMinWidth - moduleLeadingWidth,
		windowMaxWidth - moduleLeadingWidth,
	);
}

function titleBlockWidth(
	titleImplicitWidth,
	modulePadding,
	windowChipMinWidth,
	moduleLeadingWidth,
	windowMaxWidth,
) {
	const minWidth = windowChipMinWidth - moduleLeadingWidth;
	const maxWidth = maxTitleBlockWidth(
		windowChipMinWidth,
		moduleLeadingWidth,
		windowMaxWidth,
	);
	return Math.min(
		Math.max(titleImplicitWidth + modulePadding * 2, minWidth),
		maxWidth,
	);
}

function chipWidth(
	titleImplicitWidth,
	modulePadding,
	moduleLeadingWidth,
	windowChipMinWidth,
	windowMaxWidth,
) {
	const titleWidth = titleBlockWidth(
		titleImplicitWidth,
		modulePadding,
		windowChipMinWidth,
		moduleLeadingWidth,
		windowMaxWidth,
	);
	return Math.min(
		Math.max(moduleLeadingWidth + titleWidth, windowChipMinWidth),
		windowMaxWidth,
	);
}

function availableTitleBlockWidth(
	availableWidth,
	windowCount,
	moduleGap,
	moduleLeadingWidth,
	windowChipMinWidth,
	windowMaxWidth,
) {
	if (availableWidth <= 0 || windowCount <= 0)
		return maxTitleBlockWidth(
			windowChipMinWidth,
			moduleLeadingWidth,
			windowMaxWidth,
		);

	const gapWidth = Math.max(0, windowCount - 1) * moduleGap;
	const leadingWidth = windowCount * moduleLeadingWidth;
	const titleSpace = Math.floor(
		(availableWidth - gapWidth - leadingWidth) / windowCount,
	);
	return Math.max(
		0,
		Math.min(
			titleSpace,
			maxTitleBlockWidth(
				windowChipMinWidth,
				moduleLeadingWidth,
				windowMaxWidth,
			),
		),
	);
}

function constrainedTitleBlockWidth(
	titleImplicitWidth,
	modulePadding,
	windowChipMinWidth,
	moduleLeadingWidth,
	windowMaxWidth,
	availableWidth,
	windowCount,
	moduleGap,
) {
	return Math.min(
		titleBlockWidth(
			titleImplicitWidth,
			modulePadding,
			windowChipMinWidth,
			moduleLeadingWidth,
			windowMaxWidth,
		),
		availableTitleBlockWidth(
			availableWidth,
			windowCount,
			moduleGap,
			moduleLeadingWidth,
			windowChipMinWidth,
			windowMaxWidth,
		),
	);
}

function constrainedChipWidth(
	titleImplicitWidth,
	modulePadding,
	moduleLeadingWidth,
	windowChipMinWidth,
	windowMaxWidth,
	availableWidth,
	windowCount,
	moduleGap,
) {
	return (
		moduleLeadingWidth +
		constrainedTitleBlockWidth(
			titleImplicitWidth,
			modulePadding,
			windowChipMinWidth,
			moduleLeadingWidth,
			windowMaxWidth,
			availableWidth,
			windowCount,
			moduleGap,
		)
	);
}
