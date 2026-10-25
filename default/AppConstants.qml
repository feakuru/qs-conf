pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Single switch driving every colour below; see ThemeMode.qml.
    readonly property bool isDark: ThemeMode.isDark

    readonly property color bgColor: isDark ? Qt.rgba(0.3, 0.3, 0.3, 0.5) : Qt.rgba(0.88, 0.88, 0.88, 0.6)
    readonly property color solidBgColor: isDark ? Qt.rgba(0.2, 0.2, 0.2, 0.9) : Qt.rgba(0.95, 0.95, 0.95, 0.95)
    // solidBgColor while pressed: lighter on dark theme, darker on light theme.
    readonly property color pressedSolidBgColor: isDark ? Qt.rgba(0.32, 0.32, 0.32, 0.9) : Qt.rgba(0.82, 0.82, 0.82, 0.95)
    readonly property color focusedBgColor: isDark ? Qt.rgba(0.4, 0.4, 0.4, 0.9) : Qt.rgba(0.75, 0.75, 0.75, 0.9)
    readonly property color focusedSolidBgColor: isDark ? Qt.rgba(0.3, 0.3, 0.4, 0.9) : Qt.rgba(0.8, 0.8, 0.88, 0.95)
    // Cards (e.g. notifications) inside a solidBgColor menu.
    readonly property color cardBgColor: isDark ? Qt.rgba(0.26, 0.26, 0.26, 0.9) : Qt.rgba(0.89, 0.89, 0.89, 0.95)
    readonly property color styledTextColor: isDark ? "#E8EAED" : "#2D2F31"
    readonly property color styledTextOutlineColor: isDark ? Qt.rgba(0.2, 0.2, 0.2, 0.7) : Qt.rgba(1, 1, 1, 0.35)
    readonly property color accentColor: isDark ? Qt.rgba(0.5, 0.5, 0.7, 0.5) : Qt.rgba(0.35, 0.35, 0.6, 0.5)
    readonly property color indicatorBorderColor: isDark ? Qt.rgba(0.5, 0.5, 0.5, 0.5) : Qt.rgba(0.4, 0.4, 0.4, 0.4)
    // Opacity of the load bars, both on the bar widgets and in their menus.
    readonly property real loadBarAlpha: 0.5
    readonly property color indicatorBarColor: isDark ? Qt.rgba(0.5, 0.5, 1, loadBarAlpha) : Qt.rgba(0.25, 0.25, 0.75, loadBarAlpha)
    readonly property color memoryBarColor: isDark ? Qt.rgba(1, 0.7, 0.4, loadBarAlpha) : Qt.rgba(0.9, 0.5, 0.15, loadBarAlpha)
    // Horizontal gap between the load bars on bar widgets and the widget's
    // edges, so they don't run into the separators.
    readonly property int loadBarInset: 4
    readonly property color indicatorOnColor: isDark ? "lightblue" : "steelblue"
    readonly property color indicatorOffColor: isDark ? "gray" : Qt.rgba(0.45, 0.45, 0.45, 1)
    readonly property color bluetoothColor: "#0082FC"
    readonly property color dangerColor: isDark ? "#FF6B6B" : "#C62828"
    // Bars of things that are off, e.g. a muted volume.
    readonly property color mutedBarColor: Qt.rgba(indicatorOffColor.r, indicatorOffColor.g, indicatorOffColor.b, loadBarAlpha)
    readonly property color dangerBarColor: Qt.rgba(dangerColor.r, dangerColor.g, dangerColor.b, loadBarAlpha)
    // Dims the screen behind full-screen dialogs.
    readonly property color dialogScrimColor: Qt.rgba(0, 0, 0, 0.5)

    // Default tint for monochrome SVG icons; mutedIconColor is for de-emphasis.
    readonly property color iconColor: isDark ? "#BDC1C6" : "#5F6368"
    readonly property color mutedIconColor: isDark ? "#80868B" : "#9AA0A6"

    // Icon drop shadow: pronounced on dark backgrounds, soft and tight on light ones.
    readonly property color iconShadowColor: isDark ? Qt.rgba(0.1, 0.1, 0.1, 1) : Qt.rgba(0, 0, 0, 0.18)
    readonly property real iconShadowOffset: isDark ? 2 : 1
    readonly property real iconShadowRadius: isDark ? 8 : 3
    // Contour for coloured (non-text-coloured) icons that would otherwise blend into a light background.
    readonly property color iconOutlineColor: isDark ? "transparent" : "#3C4043"

    property string defaultFont: "FiraCode Nerd Font"

    readonly property int barHeight: 42

    // First external output if any is connected, otherwise the first screen.
    // Connector names vary (DP-1, DP-3, HDMI-A-1, ...), so detect internal
    // panels by prefix instead of matching a specific external name.
    readonly property var primaryScreen: {
        let screens = Quickshell.screens;
        let isInternal = s => /^(eDP|LVDS|DSI)/.test(s.name);
        return screens.find(s => !isInternal(s)) || screens[0];
    }
}
