import QtQuick

// An audio device in a list to pick the default one from; the current
// default is highlighted. Clicking runs `action`.
UsageMenuItem {
    property var node: null
    property bool isDefault: false

    // The first row is at the top of its scroll area, but still follows the
    // rows above it.
    showSeparator: true
    // Device names often only differ at the end ("... HDMI 1 Output").
    labelElide: Text.ElideMiddle
    labelColor: isDefault ? AppConstants.indicatorOnColor : AppConstants.styledTextColor
    valueText: isDefault ? "default" : ""
}
