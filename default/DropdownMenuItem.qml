import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dropdownItem
    Layout.minimumHeight: 42
    Layout.fillWidth: true
    // `pressed` matters on touch screens, where `containsMouse` never becomes
    // true and hovering therefore gives no feedback at all.
    color: dropdownItemMouseArea.containsMouse || dropdownItemMouseArea.pressed ? AppConstants.focusedSolidBgColor : "transparent"
    border.width: 1
    radius: 0
    property var action: () => {}

    MouseArea {
        id: dropdownItemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: evt => {
            dropdownItem.action(evt);
        }
    }
}
