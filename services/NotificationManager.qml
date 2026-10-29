pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell.Services.Notifications
import "." as Services
import "NotificationLogic.js" as NotificationLogic

QtObject {
    id: root

    readonly property int defaultTimeoutMs: 5000
    property var toasts: ListModel {
        id: toastModel
    }
    property var history: ListModel {
        id: historyModel
    }

    property bool dndEnabled: false
    property bool historyOpen: false
    property var historyScreen: null
    property int unreadCount: 0
    property int statusNotificationCount: 0

    property int nextToastId: 1
    property int nextHistoryId: 1
    property int maxHistoryEntries: Services.ShellConfig.notificationHistoryLimit
    property var historyIdsByRemoteId: ({})
    property var historyIdsByRollupKey: ({})
    property var toastIdsByRemoteId: ({})
    property var barManagerConnections: Connections {
        target: Services.BarManager

        function onVisibleChanged() {
            if (!Services.BarManager.visible)
                root.closeHistory();
        }
    }

    readonly property bool hasNotifications: historyModel.count > 0
    readonly property bool hasStatusNotifications: root.statusNotificationCount > 0
    readonly property bool hasUnread: root.unreadCount > 0
    readonly property string statusIconGlyph: {
        if (root.dndEnabled)
            return root.hasStatusNotifications ? "󰂛" : "󰪓";

        return root.hasStatusNotifications ? "󱅫" : "󰂜";
    }
    readonly property string urgencyLow: "low"
    readonly property string urgencyNormal: "normal"
    readonly property string urgencyCritical: "critical"

    function isHistoryVisibleOnScreen(screen) {
        return root.historyOpen && root.historyScreen === screen;
    }

    function toggleHistory(screen) {
        if (root.isHistoryVisibleOnScreen(screen)) {
            root.closeHistory();
            return;
        }

        root.openHistory(screen);
    }

    function openHistory(screen) {
        Services.SystemMenuManager.close();
        root.historyScreen = screen;
        root.historyOpen = true;
        root.markAllRead();
    }

    function closeHistory() {
        root.historyOpen = false;
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
    }

    function clearHistory() {
        historyModel.clear();
        root.historyIdsByRemoteId = ({});
        root.historyIdsByRollupKey = ({});
        root.unreadCount = 0;
        root.statusNotificationCount = 0;
    }

    function markAllRead() {
        for (let index = 0; index < historyModel.count; index += 1) {
            historyModel.setProperty(index, "read", true);
            historyModel.setProperty(index, "unreadRollupCount", 0);
        }

        root.unreadCount = 0;
    }

    function recordNotification(payload) {
        const normalizedPayload = normalizeNotificationPayload(payload || {});

        upsertHistoryEntry(normalizedPayload);

        if (!normalizedPayload.skipToast && !root.dndEnabled)
            upsertToastEntry(normalizedPayload);
    }

    function dismissToast(toastId, reason) {
        const index = indexOfToast(toastId);

        if (index < 0 || toastModel.get(index).closing)
            return;

        toastModel.setProperty(index, "closingReason", (reason ?? "timeout").toString());
        toastModel.setProperty(index, "closing", true);
    }

    function removeToast(toastId) {
        const index = indexOfToast(toastId);

        if (index >= 0) {
            const remoteId = toastModel.get(index).remoteId;

            if (remoteId.length > 0 && root.toastIdsByRemoteId[remoteId] === toastId)
                delete root.toastIdsByRemoteId[remoteId];

            toastModel.remove(index);
        }
    }

    function indexOfToast(toastId) {
        for (let index = 0; index < toastModel.count; index += 1) {
            if (toastModel.get(index).toastId === toastId)
                return index;
        }

        return -1;
    }

    function normalizeNotificationPayload(payload) {
        return NotificationLogic.normalizeNotificationPayload(payload || {}, {
            historyOpen: root.historyOpen,
            defaultTimeoutMs: root.defaultTimeoutMs,
            low: root.urgencyLow,
            normal: root.urgencyNormal,
            critical: root.urgencyCritical,
            notificationUrgency: NotificationUrgency
        });
    }

    function insertToast(payload) {
        const toastId = root.nextToastId;

        root.nextToastId += 1;

        toastModel.insert(0, {
            toastId: toastId,
            remoteId: payload.remoteId,
            title: payload.title,
            body: payload.body,
            appName: payload.appName,
            appIcon: payload.appIcon,
            desktopEntry: payload.desktopEntry,
            image: payload.image,
            urgency: payload.urgency,
            timeoutMs: payload.timeoutMs,
            closingReason: "timeout",
            closing: false
        });

        if (payload.remoteId.length > 0)
            root.toastIdsByRemoteId[payload.remoteId] = toastId;

        return toastId;
    }

    function upsertToastEntry(payload) {
        const existingToastId = root.toastIdsByRemoteId[payload.remoteId] ?? -1;

        if (existingToastId >= 0) {
            const existingIndex = indexOfToast(existingToastId);

            if (existingIndex >= 0)
                toastModel.remove(existingIndex);
        }

        return insertToast(payload);
    }

    function indexOfHistory(historyId) {
        for (let index = 0; index < historyModel.count; index += 1) {
            if (historyModel.get(index).historyId === historyId)
                return index;
        }

        return -1;
    }

    function historyRollupKey(payload) {
        return JSON.stringify([
            payload.title,
            payload.body,
            payload.appName,
            payload.appIcon,
            payload.desktopEntry,
            payload.image,
            payload.urgency
        ]);
    }

    function upsertHistoryEntry(payload) {
        const rollupKey = historyRollupKey(payload);
        const existingHistoryId = (payload.remoteId.length > 0 ? root.historyIdsByRemoteId[payload.remoteId] : -1) ?? -1;
        let existingIndex = existingHistoryId >= 0 ? indexOfHistory(existingHistoryId) : -1;
        let rolledUp = false;
        let targetHistoryId = existingHistoryId;

        if (existingIndex < 0) {
            targetHistoryId = root.historyIdsByRollupKey[rollupKey] ?? -1;
            existingIndex = targetHistoryId >= 0 ? indexOfHistory(targetHistoryId) : -1;
            rolledUp = existingIndex >= 0;
        }

        if (existingIndex >= 0) {
            const existing = historyModel.get(existingIndex);
            const existingRollupKey = historyRollupKey(existing);

            adjustNotificationCounts(existing, -1);
            const existingUnreadRollupCount = Math.max(0, Number(existing.unreadRollupCount ?? (existing.read ? 0 : 1)));
            const nextRollupCount = Math.max(1, Number(existing.rollupCount ?? 1)) + (rolledUp ? 1 : 0);
            const nextUnreadRollupCount = rolledUp
                ? existingUnreadRollupCount + (payload.read ? 0 : 1)
                : payload.read ? 0 : Math.max(1, existingUnreadRollupCount);

            if (existingRollupKey !== rollupKey && root.historyIdsByRollupKey[existingRollupKey] === targetHistoryId)
                delete root.historyIdsByRollupKey[existingRollupKey];

            historyModel.setProperty(existingIndex, "title", payload.title);
            historyModel.setProperty(existingIndex, "body", payload.body);
            historyModel.setProperty(existingIndex, "appName", payload.appName);
            historyModel.setProperty(existingIndex, "appIcon", payload.appIcon);
            historyModel.setProperty(existingIndex, "desktopEntry", payload.desktopEntry);
            historyModel.setProperty(existingIndex, "image", payload.image);
            historyModel.setProperty(existingIndex, "urgency", payload.urgency);
            historyModel.setProperty(existingIndex, "timestampMs", payload.timestampMs);
            historyModel.setProperty(existingIndex, "read", nextUnreadRollupCount === 0);
            historyModel.setProperty(existingIndex, "rollupCount", nextRollupCount);
            historyModel.setProperty(existingIndex, "unreadRollupCount", nextUnreadRollupCount);
            adjustNotificationCounts(historyModel.get(existingIndex), 1);

            if (payload.remoteId.length > 0)
                root.historyIdsByRemoteId[payload.remoteId] = targetHistoryId;

            root.historyIdsByRollupKey[rollupKey] = targetHistoryId;

            if (existingIndex > 0)
                historyModel.move(existingIndex, 0, 1);

            return targetHistoryId;
        }

        const historyId = root.nextHistoryId;

        root.nextHistoryId += 1;

        historyModel.insert(0, {
            historyId: historyId,
            remoteId: payload.remoteId,
            title: payload.title,
            body: payload.body,
            appName: payload.appName,
            appIcon: payload.appIcon,
            desktopEntry: payload.desktopEntry,
            image: payload.image,
            urgency: payload.urgency,
            timestampMs: payload.timestampMs,
            read: payload.read,
            rollupCount: 1,
            unreadRollupCount: payload.read ? 0 : 1
        });

        if (payload.remoteId.length > 0)
            root.historyIdsByRemoteId[payload.remoteId] = historyId;

        root.historyIdsByRollupKey[rollupKey] = historyId;

        adjustNotificationCounts(historyModel.get(0), 1);

        while (historyModel.count > Math.max(1, root.maxHistoryEntries))
            removeHistoryAt(historyModel.count - 1);

        return historyId;
    }

    function removeHistory(historyId) {
        const index = indexOfHistory(historyId);

        if (index >= 0)
            removeHistoryAt(index);
    }

    function removeHistoryAt(index) {
        const notification = historyModel.get(index);
        const historyId = notification.historyId;
        const remoteId = notification.remoteId;
        const rollupKey = historyRollupKey(notification);

        if (remoteId.length > 0 && root.historyIdsByRemoteId[remoteId] === historyId)
            delete root.historyIdsByRemoteId[remoteId];

        if (root.historyIdsByRollupKey[rollupKey] === historyId)
            delete root.historyIdsByRollupKey[rollupKey];

        adjustNotificationCounts(notification, -1);
        historyModel.remove(index);
    }

    function adjustNotificationCounts(notification, sign) {
        const contribution = NotificationLogic.countContribution(notification, root.urgencyLow);

        root.unreadCount += sign * contribution.unreadCount;
        root.statusNotificationCount += sign * contribution.statusNotificationCount;
    }

    function notificationTimeoutFromServer(expireTimeout) {
        return NotificationLogic.notificationTimeoutFromServer(expireTimeout, root.defaultTimeoutMs);
    }

    function dismissNotification(remoteId) {
        const toastId = root.toastIdsByRemoteId[remoteId] ?? -1;

        if (toastId >= 0)
            root.dismissToast(toastId);
    }

    property QtObject notificationServer: NotificationServer {
        id: notificationServer

        actionsSupported: false
        bodyImagesSupported: false
        bodyMarkupSupported: false
        bodySupported: true
        imageSupported: true
        inlineReplySupported: false
        keepOnReload: true
        persistenceSupported: true

        onNotification: notification => {
            const remoteId = notification.id.toString();
            const timeoutMs = root.notificationTimeoutFromServer(notification.expireTimeout);

            notification.tracked = true;

            notification.closed.connect(function() {
                root.dismissNotification(remoteId);
            });

            root.recordNotification({
                remoteId: remoteId,
                title: notification.summary,
                body: notification.body,
                appName: notification.appName,
                appIcon: notification.appIcon,
                desktopEntry: notification.desktopEntry,
                image: notification.image,
                urgency: notification.urgency,
                timeoutMs: timeoutMs,
                timestampMs: Date.now(),
                read: root.historyOpen,
                skipToast: notification.lastGeneration
            });
        }
    }

}
