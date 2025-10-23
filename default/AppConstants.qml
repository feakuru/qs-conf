pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property color bgColor: Qt.rgba(0.3, 0.3, 0.3, 0.5)
    property color solidBgColor: Qt.rgba(0.2, 0.2, 0.2, 0.9)
    property color focusedBgColor: Qt.rgba(0.4, 0.4, 0.4, 0.9)
    property color focusedSolidBgColor: Qt.rgba(0.3, 0.3, 0.4, 0.9)
    property color styledTextColor: "white"
    property color styledTextOutlineColor: Qt.rgba(0.2, 0.2, 0.2, 0.7)
    property color accentColor: Qt.rgba(0.5, 0.5, 0.7, 0.5)
    property color indicatorBorderColor: Qt.rgba(0.5, 0.5, 0.5, 0.5)
    property color indicatorBarColor: Qt.rgba(0.5, 0.5, 1, 0.8)
    property color indicatorOnColor: "lightblue"
    property color indicatorOffColor: "gray"
    property color bluetoothColor: "#0082FC"

    property string defaultFont: "FiraCode Nerd Font"
}
