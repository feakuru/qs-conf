import QtQuick

// One of a row of tabs (e.g. in a RowLayout): a Font Awesome icon and a
// label, underlined while `selected`.
DropdownMenuItem {
    id: tabMenuItem

    property string iconName: ""
    property string text: ""
    property bool selected: false

    showSeparator: false

    Row {
        anchors.centerIn: parent
        spacing: 8

        RecoloredIcon {
            anchors.verticalCenter: parent.verticalCenter
            iconWidth: 18
            iconHeight: 18
            source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/${tabMenuItem.iconName}.svg`)
            iconColor: tabMenuItem.selected ? AppConstants.indicatorOnColor : AppConstants.mutedIconColor
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
            color: tabMenuItem.selected ? AppConstants.styledTextColor : AppConstants.mutedIconColor
            text: tabMenuItem.text
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: 3
        radius: 1.5
        visible: tabMenuItem.selected
        color: AppConstants.indicatorOnColor
    }
}
