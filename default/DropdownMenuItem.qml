import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dropdownItem
    Layout.minimumHeight: 42
    Layout.fillWidth: true
    // `pressed` matters on touch screens, where hovering never happens and
    // therefore gives no feedback at all.
    color: dropdownItemHover.hovered || dropdownItemMouseArea.pressed ? AppConstants.focusedSolidBgColor : "transparent"
    property var action: () => {}
    // Rows below the first one get a separator above them.
    property bool showSeparator: y > 0

    Separator {
        vertical: false
        thickness: 1
        visible: dropdownItem.showSeparator
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
    }

    // Hover is tracked with a HoverHandler rather than MouseArea.hoverEnabled:
    // a hover-enabled MouseArea accepts hover events, which stops them from
    // reaching the menu's own HoverHandler (see DropdownMenu.qml).
    HoverHandler {
        id: dropdownItemHover
    }

    MouseArea {
        id: dropdownItemMouseArea
        anchors.fill: parent
        onClicked: evt => {
            dropdownItem.action(evt);
        }
    }
}
