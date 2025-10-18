import QtQuick
import Quickshell.Hyprland

Rectangle {
    color: "transparent"
    anchors.fill: parent

    StyledText {
        id: windowTitle
        text: (Hyprland.activeToplevel != null && Hyprland.activeToplevel.workspace.id == Hyprland.focusedWorkspace.id) ? (Hyprland.activeToplevel.title.slice(0, 50) + (Hyprland.activeToplevel.title.length > 50 ? '...' : '')) : ''
    }
}
