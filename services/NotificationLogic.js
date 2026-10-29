function normalizeUrgency(urgency, options) {
	switch (urgency) {
		case options.notificationUrgency.Low:
		case options.low:
		case "low":
			return options.low;
		case options.notificationUrgency.Critical:
		case options.critical:
		case "critical":
			return options.critical;
		default:
			return options.normal;
	}
}

function resolveTimeoutMs(timeoutMs, urgency, options) {
	if (normalizeUrgency(urgency, options) === options.critical) return 0;

	return Math.max(0, Number(timeoutMs ?? options.defaultTimeoutMs));
}

function notificationTimeoutFromServer(expireTimeout, defaultTimeoutMs) {
	const numericTimeout = Number(expireTimeout);

	if (!Number.isFinite(numericTimeout) || numericTimeout < 0)
		return defaultTimeoutMs;

	return Math.max(0, Math.round(numericTimeout));
}

function normalizeNotificationPayload(payload, options) {
	const title = (
		payload.title ??
		payload.summary ??
		payload.appName ??
		"Notification"
	).toString();
	const body = (payload.body ?? "").toString();
	const appName = (payload.appName ?? payload.desktopEntry ?? "").toString();
	const urgency = normalizeUrgency(payload.urgency, options);

	return {
		remoteId: (payload.remoteId ?? "").toString(),
		title: title,
		body: body,
		appName: appName,
		appIcon: (payload.appIcon ?? "").toString(),
		desktopEntry: (payload.desktopEntry ?? "").toString(),
		image: (payload.image ?? "").toString(),
		urgency: urgency,
		timeoutMs: resolveTimeoutMs(payload.timeoutMs, urgency, options),
		timestampMs: Math.max(0, Number(payload.timestampMs ?? Date.now())),
		read: Boolean(payload.read ?? options.historyOpen),
		skipToast: Boolean(payload.skipToast),
	};
}

function countContribution(notification, urgencyLow) {
	const rollupCount = Math.max(1, Number(notification.rollupCount ?? 1));
	const unreadRollupCount = Math.max(
		0,
		Number(
			notification.unreadRollupCount ?? (notification.read ? 0 : rollupCount),
		),
	);

	return {
		unreadCount: unreadRollupCount,
		statusNotificationCount:
			notification.urgency !== urgencyLow ? rollupCount : 0,
	};
}

function recomputeCounts(notifications, urgencyLow) {
	let unreadCount = 0;
	let statusNotificationCount = 0;

	for (const notification of notifications) {
		const contribution = countContribution(notification, urgencyLow);

		unreadCount += contribution.unreadCount;
		statusNotificationCount += contribution.statusNotificationCount;
	}

	return {
		unreadCount: unreadCount,
		statusNotificationCount: statusNotificationCount,
	};
}
