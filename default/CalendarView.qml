import QtQuick
import QtQuick.Layouts

// A month calendar for dropdown menus: a header with the month name and
// previous/today/next buttons, then a grid of days with today highlighted.
// Weeks start on the locale's first day of the week.
//
// The grid always has 6 rows, so the menu keeps its height across months.
ColumnLayout {
    id: calendarView

    // Today as "yyyy-MM-dd". A string rather than a date, so bindings that
    // depend on it only update when the day actually changes.
    property string today: Qt.formatDate(new Date(), "yyyy-MM-dd")

    // The month shown; shownMonth is 0-based, like in JS dates.
    property int shownYear: new Date().getFullYear()
    property int shownMonth: new Date().getMonth()

    readonly property var locale: Qt.locale()
    readonly property bool showingCurrentMonth: today.slice(0, 7) === Qt.formatDate(new Date(shownYear, shownMonth, 1, 12), "yyyy-MM")
    // Days of the previous month shown before the 1st.
    readonly property int leadingDays: (new Date(shownYear, shownMonth, 1, 12).getDay() - locale.firstDayOfWeek + 7) % 7

    function showToday() {
        let now = new Date();
        calendarView.shownYear = now.getFullYear();
        calendarView.shownMonth = now.getMonth();
    }

    function shiftMonth(delta) {
        let first = new Date(calendarView.shownYear, calendarView.shownMonth + delta, 1, 12);
        calendarView.shownYear = first.getFullYear();
        calendarView.shownMonth = first.getMonth();
    }

    Layout.fillWidth: true
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 8
        Layout.minimumHeight: 42
        spacing: 4

        StyledText {
            anchors.centerIn: undefined
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 18
            text: `${calendarView.locale.standaloneMonthName(calendarView.shownMonth, Locale.LongFormat)} ${calendarView.shownYear}`.toUpperCase()
        }

        WindowActionButton {
            iconName: "calendar-day"
            enabledAction: !calendarView.showingCurrentMonth
            action: () => calendarView.showToday()
        }

        WindowActionButton {
            iconName: "chevron-left"
            action: () => calendarView.shiftMonth(-1)
        }

        WindowActionButton {
            iconName: "chevron-right"
            action: () => calendarView.shiftMonth(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.bottomMargin: 6
        columns: 7
        uniformCellWidths: true
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: 7
            delegate: StyledText {
                anchors.centerIn: undefined
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 4
                font.pixelSize: 12
                color: AppConstants.mutedIconColor
                text: calendarView.locale.dayName((calendarView.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).toUpperCase()
            }
        }

        Repeater {
            // A fixed number of cells that only have their dates swapped.
            model: 42
            delegate: Item {
                id: dayCell
                required property int index
                readonly property date cellDate: new Date(calendarView.shownYear, calendarView.shownMonth, 1 - calendarView.leadingDays + index, 12)
                readonly property bool inShownMonth: cellDate.getMonth() === calendarView.shownMonth
                readonly property bool isToday: Qt.formatDate(cellDate, "yyyy-MM-dd") === calendarView.today

                Layout.fillWidth: true
                implicitHeight: 38

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width
                    radius: width / 2
                    visible: dayCell.isToday
                    color: AppConstants.accentColor
                    border.width: 1
                    border.color: AppConstants.indicatorBorderColor
                }

                StyledText {
                    font.pixelSize: 16
                    color: dayCell.inShownMonth ? AppConstants.styledTextColor : AppConstants.mutedIconColor
                    text: dayCell.cellDate.getDate()
                }
            }
        }
    }
}
