import QtQuick
import Quickshell

// The time, with the date in two small lines before it (e.g. "SAT" over
// "24 OCT"). Opens the notification area and a calendar below it. A dot in
// the corner shows that there are notifications.
DropdownMenu {
    id: dateClock

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    toggleText: Qt.formatDateTime(systemClock.date, "hh:mm:ss")
    toggleTextWidest: "00:00:00"
    toggleLeadingText: Qt.formatDateTime(systemClock.date, "ddd\ndd MMM").toUpperCase()
    toggleLeadingTextWidest: "00 MMM"
    // Small enough that the two lines don't take up the bar's full height.
    toggleLeadingTextFont.pixelSize: 12
    toggleLeadingTextHorizontalAlignment: Text.AlignHCenter
    // As far from the time as from the widget's edge.
    contentSpacing: horizontalPadding

    menuWidth: 450
    opensUpward: true

    onMenuVisibleChanged: {
        if (menuVisible) {
            // Always open on the current month.
            calendarView.showToday();
            NotificationCenter.areaOpened();
        } else {
            NotificationCenter.areaClosed();
        }
    }

    Connections {
        target: NotificationCenter

        function onAreaRequested() {
            if (!dateClock.menuVisible) {
                dateClock.openMenu();
            }
        }

        function onReplyRequested(notification) {
            replyPrompt.ask(notification);
        }
    }

    NotificationReplyPrompt {
        id: replyPrompt
    }

    // Within the button's padding, so it doesn't cover the time.
    Rectangle {
        visible: NotificationCenter.count > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        width: 7
        height: width
        radius: width / 2
        color: NotificationCenter.doNotDisturb ? AppConstants.indicatorOffColor : AppConstants.indicatorOnColor
    }

    // More sections (e.g. calendar events) are meant to go between the
    // notifications and the calendar.
    menuContent: [
        NotificationList {},
        CalendarView {
            id: calendarView
            today: Qt.formatDate(systemClock.date, "yyyy-MM-dd")
        }
    ]
}
