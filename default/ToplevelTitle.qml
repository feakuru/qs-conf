import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: outerRect
    color: "transparent"
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 300
    anchors.rightMargin: 300

    StyledText {
        id: windowTitle
        text: {
            let topLevel = Hyprland.activeToplevel;
            if (topLevel == null || topLevel.workspace.id != Hyprland.focusedWorkspace.id) {
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
