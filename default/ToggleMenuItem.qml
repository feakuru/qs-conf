import QtQuick

// A menu row with a switch and a label; a click calls `toggle`. While not
// `available` (the option doesn't apply), it is faded and can't be switched.
DropdownMenuItem {
    id: toggleMenuItem

    property string text: ""
    property bool checked: false
    property bool available: true
    property var toggle: () => {}

    opacity: available ? 1 : 0.4
    action: () => {
        if (toggleMenuItem.available) {
            toggleMenuItem.toggle();
        }
    }

    RecoloredIcon {
        id: switchIcon
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        iconWidth: 22
        iconHeight: 22
        source: Qt.resolvedUrl(toggleMenuItem.checked ? "assets/icons/fontawesome/solid/toggle-on.svg" : "assets/icons/fontawesome/solid/toggle-off.svg")
        iconColor: toggleMenuItem.checked ? AppConstants.indicatorOnColor : AppConstants.mutedIconColor
    }

    StyledText {
        anchors.centerIn: undefined
        anchors.left: switchIcon.right
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 15
        elide: Text.ElideRight
        text: toggleMenuItem.text
    }
}
