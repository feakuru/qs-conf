import QtQuick
import Quickshell

Rectangle {
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor

    StyledText {
        text: Qt.formatDateTime(systemClock.date, "ddd dd MMM hh:mm:ss")

        SystemClock {
            id: systemClock
            precision: SystemClock.Seconds
        }
    }
}
