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
    property color outlineColor: "transparent"
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

    // A tight, near-solid glow acts as a contour around the icon shape.
    Glow {
        id: iconOutline
        anchors.fill: recoloredIcon
        source: recoloredIcon
        visible: outlineColor.a > 0
        transparentBorder: true
        radius: 2
        samples: 5
        spread: 0.8
        color: outlineColor
    }

    DropShadow {
        anchors.fill: recoloredIcon
        source: iconOutline.visible ? iconOutline : recoloredIcon
        horizontalOffset: AppConstants.iconShadowOffset
        verticalOffset: AppConstants.iconShadowOffset
        radius: AppConstants.iconShadowRadius
        color: AppConstants.iconShadowColor
    }
}
