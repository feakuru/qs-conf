import QtQuick
import Quickshell
import Quickshell.Widgets

// An application's icon (a desktop entry's `icon`: a theme icon name or a
// file), or the Font Awesome `fallbackIconName` if there is none or it
// can't be found.
Item {
    id: appIcon

    property string iconName: ""
    property string fallbackIconName: "rocket"
    property color fallbackColor: AppConstants.iconColor
    property int size: 22
    readonly property string iconSource: {
        if (iconName === "") {
            return "";
        }
        return iconName.startsWith("/") ? `file://${iconName}` : Quickshell.iconPath(iconName, true);
    }

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: themedIcon
        anchors.fill: parent
        visible: appIcon.iconSource !== "" && status === Image.Ready
        source: appIcon.iconSource
    }

    RecoloredIcon {
        anchors.centerIn: parent
        visible: !themedIcon.visible
        iconWidth: Math.round(appIcon.size * 0.85)
        iconHeight: Math.round(appIcon.size * 0.85)
        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/${appIcon.fallbackIconName}.svg`)
        iconColor: appIcon.fallbackColor
    }
}
