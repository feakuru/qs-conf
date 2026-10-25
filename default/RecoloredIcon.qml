import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    property alias source: originalIcon.source
    property alias iconWidth: originalIcon.width
    property alias iconHeight: originalIcon.height
    property alias iconColor: recoloredIcon.color
    property color outlineColor: "transparent"
    // Optional small icon over the bottom-left corner, in the same colour.
    // Its outline should match the background, so that it cuts the badge out
    // of the icon underneath and the two shapes don't merge.
    property alias badgeSource: badgeIcon.source
    property color badgeOutlineColor: "transparent"

    implicitWidth: originalIcon.width
    implicitHeight: originalIcon.height

    // The icon and its badge, drawn together so that they share one shadow.
    // Larger than the icon to leave room for the badge and the outlines that
    // stick out of it.
    Item {
        id: iconShape
        anchors.centerIn: parent
        width: originalIcon.width + 12
        height: originalIcon.height + 12

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
            anchors.fill: recoloredIcon
            source: recoloredIcon
            visible: outlineColor.a > 0
            transparentBorder: true
            radius: 2
            samples: 5
            spread: 0.8
            color: outlineColor
        }

        IconImage {
            id: badgeIcon
            visible: source.toString().length > 0
            anchors.left: originalIcon.left
            anchors.bottom: originalIcon.bottom
            anchors.leftMargin: -3
            anchors.bottomMargin: -3
            width: originalIcon.width / 2
            height: originalIcon.height / 2
        }

        Glow {
            anchors.fill: badgeIcon
            source: badgeIcon
            visible: badgeIcon.visible
            transparentBorder: true
            radius: 2
            samples: 5
            spread: 0.8
            color: badgeOutlineColor
        }

        ColorOverlay {
            anchors.fill: badgeIcon
            source: badgeIcon
            visible: badgeIcon.visible
            color: recoloredIcon.color
        }
    }

    DropShadow {
        anchors.fill: iconShape
        source: iconShape
        horizontalOffset: AppConstants.iconShadowOffset
        verticalOffset: AppConstants.iconShadowOffset
        radius: AppConstants.iconShadowRadius
        color: AppConstants.iconShadowColor
    }
}
