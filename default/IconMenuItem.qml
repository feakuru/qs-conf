import QtQuick

// A menu item showing one or more icons and an optional label, centred.
DropdownMenuItem {
    id: iconMenuItem
    property list<string> iconNames: []
    property color iconColor: AppConstants.iconColor
    property string text: ""

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
            }
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            text: iconMenuItem.text
        }
    }
}
