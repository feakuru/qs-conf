import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Rectangle {
    color: "transparent"
    property alias source: originalIcon.source
    property alias iconWidth: originalIcon.width
    property alias iconHeight: originalIcon.height
    property alias iconColor: recoloredIcon.color
    property real preferredWidth: originalIcon.width

    IconImage {
        id: originalIcon
        anchors.centerIn: parent
    }

    ColorOverlay {
        id: recoloredIcon
        anchors.fill: originalIcon
        source: originalIcon
    }

    DropShadow {
        anchors.fill: recoloredIcon
        source: recoloredIcon
        horizontalOffset: 2
        verticalOffset: 2
        radius: 8.0
        color: Qt.rgba(0.1, 0.1, 0.1, 1)
    }
}
