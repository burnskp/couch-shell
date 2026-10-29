# Notifications

This document explains the internal notification flow built around `services/NotificationManager.qml`.

Use this guide before adding new notification overlays, history views, or parallel notification state.

## Purpose

`NotificationManager` is the shared notification controller for:

- toast state
- notification history state
- unread and status counts
- do-not-disturb state
- notification server event ingestion

New notification UI should consume this singleton instead of creating local notification models.

## Import

```qml
import "../services" as Services
```

## Shared State

Models:

- `toasts`
- `history`

Visibility and routing state:

- `historyOpen`
- `historyScreen`

Status state:

- `dndEnabled`
- `unreadCount`
- `statusNotificationCount`
- `hasNotifications`
- `hasStatusNotifications`
- `hasUnread`
- `statusIconGlyph`

Urgency constants:

- `urgencyLow`
- `urgencyNormal`
- `urgencyCritical`

## Primary Operations

History visibility:

- `isHistoryVisibleOnScreen(screen)`
- `toggleHistory(screen)`
- `openHistory(screen)`
- `closeHistory()`

History and read state:

- `clearHistory()`
- `markAllRead()`
- `removeHistory(historyId)`

Toast lifecycle:

- `dismissToast(toastId, reason)`
- `removeToast(toastId)`

Global toggles:

- `toggleDnd()`

Most UI callers should use the higher-level helpers above instead of mutating model rows directly.

## Typical Patterns

### Toggle the history panel for a screen

```qml
Services.NotificationManager.toggleHistory(root.barScreen)
```

### Bind a panel to the active screen

```qml
readonly property bool isTargetScreen: Services.NotificationManager.historyScreen === root.screen

Component.onCompleted: {
    panelAnimation.open = Services.NotificationManager.historyOpen && isTargetScreen
}
```

### Bind a toast repeater

```qml
Repeater {
    model: Services.NotificationManager.toasts
}
```

## Toasts vs History

Use `toasts` when:

- rendering transient notifications
- showing close animations before removal

Use `history` when:

- rendering the persistent notification list
- showing unread state or bulk history actions

The manager keeps these in sync when notifications arrive, update, or close.

History keeps at most `maxHistoryEntries` rows (from `ShellConfig.notificationHistoryLimit`,
the `notifications.historyLimit` Nix option, default 200). Inserting past the cap evicts
the oldest rows through `removeHistoryAt()`, which also clears their remote-id and
rollup-key lookups.

`unreadCount` and `statusNotificationCount` are maintained incrementally: every history
mutation subtracts the old row's `NotificationLogic.countContribution()` and adds the new
one through `adjustNotificationCounts()`. Do not reintroduce full-history recounts on
arrival; new mutation paths should adjust counts the same way.

## DND and Status Display

Use these shared fields rather than recomputing notification status in the UI:

- `dndEnabled`
- `statusIconGlyph`
- `unreadCount`
- `hasStatusNotifications`

This keeps the status cluster, history panel, and any future notification entry points consistent.

## When To Extend `NotificationManager`

Extend the singleton when:

- adding new shared notification state
- changing toast or history lifecycle behavior
- changing notification count or unread logic
- adding another view that should share the same notification models

Do not create a second notification store for:

- a new toast surface
- a new history panel treatment
- an alternate status button

Those should all consume the existing manager.

## Related Reusable Pieces

- use `Components.NotificationAppIcon` for notification app icons
- use `Services.TrayIconResolver.notificationIconCandidates(...)` only when you need lower-level icon resolution behavior

## Reference Usages

- `modules/notifications/NotificationOverlay.qml`
- `modules/notifications/NotificationHistoryPanel.qml`
- `modules/notifications/ToastItem.qml`
- `modules/bar/widgets/StatusClusterWidget.qml`
