pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Single switch driving every colour below; see ThemeMode.qml.
    readonly property bool isDark: ThemeMode.isDark

    readonly property color bgColor: isDark ? Qt.rgba(0.3, 0.3, 0.3, 0.5) : Qt.rgba(0.88, 0.88, 0.88, 0.6)
    readonly property color solidBgColor: isDark ? Qt.rgba(0.2, 0.2, 0.2, 0.9) : Qt.rgba(0.95, 0.95, 0.95, 0.95)
    readonly property color focusedBgColor: isDark ? Qt.rgba(0.4, 0.4, 0.4, 0.9) : Qt.rgba(0.75, 0.75, 0.75, 0.9)
    readonly property color focusedSolidBgColor: isDark ? Qt.rgba(0.3, 0.3, 0.4, 0.9) : Qt.rgba(0.8, 0.8, 0.88, 0.95)
    readonly property color styledTextColor: isDark ? "white" : Qt.rgba(0.1, 0.1, 0.12, 1)
    readonly property color styledTextOutlineColor: isDark ? Qt.rgba(0.2, 0.2, 0.2, 0.7) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color accentColor: isDark ? Qt.rgba(0.5, 0.5, 0.7, 0.5) : Qt.rgba(0.35, 0.35, 0.6, 0.5)
    readonly property color indicatorBorderColor: isDark ? Qt.rgba(0.5, 0.5, 0.5, 0.5) : Qt.rgba(0.4, 0.4, 0.4, 0.4)
    readonly property color indicatorBarColor: isDark ? Qt.rgba(0.5, 0.5, 1, 0.8) : Qt.rgba(0.25, 0.25, 0.75, 0.8)
    readonly property color indicatorOnColor: isDark ? "lightblue" : "steelblue"
    readonly property color indicatorOffColor: isDark ? "gray" : Qt.rgba(0.45, 0.45, 0.45, 1)
    readonly property color bluetoothColor: "#0082FC"
    readonly property color dangerColor: isDark ? "#FF6B6B" : "#C62828"

    // Default tint for monochrome SVG icons; mutedIconColor is for de-emphasis.
    readonly property color iconColor: isDark ? "lightgray" : Qt.rgba(0.18, 0.18, 0.2, 1)
    readonly property color mutedIconColor: isDark ? Qt.rgba(0.6, 0.6, 0.6, 1) : Qt.rgba(0.5, 0.5, 0.5, 1)

    property string defaultFont: "FiraCode Nerd Font"
}
