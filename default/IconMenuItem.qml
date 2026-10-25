import QtQuick

// A menu item showing one or more icons and an optional label, centred.
DropdownMenuItem {
    id: iconMenuItem
    property list<string> iconNames: []
    property color iconColor: AppConstants.iconColor
    // Optional small icon drawn over the bottom-left corner of each icon.
    property string badgeIconName: ""
    property string text: ""
    property int textPixelSize: 22

    Row {
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: iconMenuItem.iconNames
            delegate: RecoloredIcon {
                anchors.verticalCenter: parent.verticalCenter
                iconWidth: 26
                iconHeight: 26
                source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/${modelData}.svg`)
                iconColor: iconMenuItem.iconColor
                badgeSource: iconMenuItem.badgeIconName.length > 0 ? Qt.resolvedUrl(`assets/icons/fontawesome/solid/${iconMenuItem.badgeIconName}.svg`) : ""
                badgeOutlineColor: iconMenuItem.color.a > 0 ? iconMenuItem.color : AppConstants.solidBgColor
            }
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            text: iconMenuItem.text
            font.pixelSize: iconMenuItem.textPixelSize
        }
    }
}
