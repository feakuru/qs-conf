import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    implicitWidth: clockText.implicitWidth + 20
    Layout.fillHeight: true

    StyledText {
        id: clockText
        text: Qt.formatDateTime(systemClock.date, "ddd dd MMM hh:mm:ss")

        SystemClock {
            id: systemClock
            precision: SystemClock.Seconds
        }
    }
}
