import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

Rectangle {
    id: outerRect
    color: "transparent"
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: parent.width * 0.2
    anchors.rightMargin: parent.width * 0.2

    StyledText {
        id: windowTitle
        text: {
            let topLevel = Hyprland.activeToplevel;
            let waylandToplevel = ToplevelManager.activeToplevel; // because hyprland may not report the window as closed

            if (
                topLevel == null
                || waylandToplevel == null
                || (
                    Hyprland.focusedWorkspace != null
                    && topLevel.workspace != null
                    && topLevel.workspace.id != Hyprland.focusedWorkspace.id
                )
            ) {
                return "";
            }

            let maxTitleLength = outerRect.width / this.font.pixelSize;
            let fullTitle = topLevel.title;
            if (fullTitle.length > maxTitleLength) {
                return fullTitle.slice(0, maxTitleLength) + '...';
            }
            return fullTitle;
        }
    }
}
