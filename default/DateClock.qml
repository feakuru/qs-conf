import QtQuick
import Quickshell

// The time, with the date in two small lines before it (e.g. "SAT" over
// "24 OCT"). Opens a calendar.
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

    // Always open on the current month.
    onMenuVisibleChanged: {
        if (menuVisible) {
            calendarView.showToday();
        }
    }

    // More sections (e.g. notifications, calendar events) are meant to go
    // above the calendar.
    menuContent: [
        CalendarView {
            id: calendarView
            today: Qt.formatDate(systemClock.date, "yyyy-MM-dd")
        }
    ]
}
