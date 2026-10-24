pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The session's notification server. Notifications stay in the notification
// area above the calendar (NotificationList, in DateClock's menu) until they
// are dismissed; new ones also pop up as toasts (NotificationToasts) for a
// while. Clicking a toast opens the area scrolled to that notification.
//
// Transient notifications don't belong in a notification area: they go away
// with their toast (or when the area closes, if it was open when they came).
Singleton {
    id: notificationCenter

    // Oldest first.
    readonly property var notifications: notificationServer.trackedNotifications.values
    readonly property int count: notifications.length

    // Notifications shown as toasts, oldest first.
    readonly property var toasts: notifications.filter(n => toastIds.includes(n.id))
    property var toastIds: []
    readonly property int maxToasts: 4
    // For notifications that don't ask for a timeout of their own.
    readonly property int defaultToastTimeout: 6000
    // Toasts don't time out while the pointer is over them.
    property bool toastsHovered: false

    // Only critical notifications pop up as toasts.
    property alias doNotDisturb: persisted.doNotDisturb

    // Whether the notification area (DateClock's menu) is open. No toasts are
    // shown meanwhile: new notifications appear at the top of the area.
    property bool areaOpen: false
    // The notification to highlight and scroll to in the area, or -1.
    property int focusedId: -1

    // Asks DateClock to open its menu.
    signal areaRequested
    // Asks the notification area to scroll to focusedId.
    signal focusRequested
    // Asks DateClock to show its reply prompt for the notification.
    signal replyRequested(var notification)

    // Icons may come as a theme icon name, a path or a URL.
    function iconSource(icon) {
        if (!icon) {
            return "";
        }
        if (icon.startsWith("/")) {
            return `file://${icon}`;
        }
        if (icon.includes("://")) {
            return icon;
        }
        return Quickshell.iconPath(icon, true);
    }

    // How long the notification stays as a toast, in ms; 0 means until it is
    // clicked or dismissed. Notifications report expireTimeout in ms (not in
    // seconds, as Quickshell's docs say), -1 meaning "up to the server".
    function toastTimeout(notification) {
        if (notification.urgency === NotificationUrgency.Critical) {
            return 0;
        }
        return notification.expireTimeout > 0 ? notification.expireTimeout : notificationCenter.defaultToastTimeout;
    }

    // E.g. "now", "5 min ago", "14:03" (today) or "23 Oct 14:03".
    function ageText(notification) {
        let receivedAt = persisted.receivedAt[notification.id];
        let received = new Date(receivedAt === undefined ? Date.now() : receivedAt);
        let now = clock.date;
        let minutes = Math.floor((now - received) / 60000);
        if (minutes < 1) {
            return "now";
        }
        if (minutes < 60) {
            return `${minutes} min ago`;
        }
        if (received.toDateString() === now.toDateString()) {
            return Qt.formatTime(received, "hh:mm");
        }
        return Qt.formatDateTime(received, "d MMM hh:mm");
    }

    // Returns whether the notification is shown as a toast now.
    function showToast(notification) {
        if (notificationCenter.areaOpen) {
            return false;
        }
        if (notificationCenter.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) {
            return false;
        }
        let ids = notificationCenter.toastIds.filter(id => id !== notification.id);
        ids.push(notification.id);
        notificationCenter.setToastIds(ids.slice(-notificationCenter.maxToasts));
        return true;
    }

    function hideToast(id) {
        if (notificationCenter.toastIds.includes(id)) {
            notificationCenter.setToastIds(notificationCenter.toastIds.filter(toastId => toastId !== id));
        }
    }

    function setToastIds(ids) {
        let removed = notificationCenter.toastIds.filter(id => !ids.includes(id));
        notificationCenter.toastIds = ids;
        if (removed.length === 0 || notificationCenter.areaOpen) {
            return;
        }
        // Later: this may run while a new notification is being added, and
        // the list changing before it is in would drop its toast (see
        // onNotificationsChanged).
        Qt.callLater(() => notificationCenter.expireTransient(removed));
    }

    function expireTransient(ids) {
        // Copied by filter(): expiring removes them from `notifications`.
        for (let notification of notificationCenter.notifications.filter(n => n.transient && ids.includes(n.id))) {
            notification.expire();
        }
    }

    // Opens the notification area on the notification (a clicked toast).
    function showInArea(notification) {
        notificationCenter.focusedId = notification.id;
        // Later: opening the area removes the toast that is being clicked.
        Qt.callLater(() => {
            notificationCenter.areaRequested();
            notificationCenter.focusRequested();
        });
    }

    // Called by DateClock as its menu opens and closes.
    function areaOpened() {
        notificationCenter.areaOpen = true;
        notificationCenter.setToastIds([]);
    }

    function areaClosed() {
        notificationCenter.areaOpen = false;
        notificationCenter.focusedId = -1;
        notificationCenter.expireTransient(notificationCenter.notifications.map(n => n.id));
    }

    function dismissAll() {
        for (let notification of notificationCenter.notifications.slice()) {
            notification.dismiss();
        }
    }

    // Survives config reloads, like the notifications themselves (keepOnReload).
    PersistentProperties {
        id: persisted
        reloadableId: "notificationCenter"

        property bool doNotDisturb: false
        // Notification id -> when it arrived (ms since the epoch).
        property var receivedAt: ({})
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    NotificationServer {
        id: notificationServer
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            // Notifications from before a reload are only re-emitted.
            if (!notification.lastGeneration) {
                let shownAsToast = notificationCenter.showToast(notification);
                if (notification.transient && !shownAsToast && !notificationCenter.areaOpen) {
                    // Not tracking it discards it.
                    return;
                }
                let receivedAt = {};
                for (let tracked of notificationCenter.notifications) {
                    let time = persisted.receivedAt[tracked.id];
                    if (time !== undefined) {
                        receivedAt[tracked.id] = time;
                    }
                }
                receivedAt[notification.id] = Date.now();
                persisted.receivedAt = receivedAt;
            }
            notification.tracked = true;
        }
    }

    // Closed notifications leave no stale ids behind to take up toast slots.
    onNotificationsChanged: {
        let ids = notificationCenter.notifications.map(n => n.id);
        if (notificationCenter.toastIds.some(id => !ids.includes(id))) {
            notificationCenter.toastIds = notificationCenter.toastIds.filter(id => ids.includes(id));
        }
    }

    // A toast timer for each notification.
    Variants {
        model: notificationCenter.notifications

        Timer {
            id: toastTimer

            required property var modelData
            readonly property bool shownAsToast: notificationCenter.toastIds.includes(modelData.id)

            interval: notificationCenter.toastTimeout(modelData)
            running: shownAsToast && interval > 0 && !notificationCenter.toastsHovered
            onTriggered: notificationCenter.hideToast(modelData.id)

            // A notification that was replaced (same id, new content, e.g. a
            // progress update) pops up again.
            function showAgain() {
                if (notificationCenter.showToast(toastTimer.modelData) && toastTimer.running) {
                    toastTimer.restart();
                }
            }

            property Connections updates: Connections {
                target: toastTimer.modelData

                function onSummaryChanged() {
                    toastTimer.showAgain();
                }

                function onBodyChanged() {
                    toastTimer.showAgain();
                }
            }
        }
    }
}
