import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dropdownItem
    Layout.minimumHeight: 42
    Layout.fillWidth: true
    color: dropdownItemMouseArea.containsMouse ? AppConstants.focusedSolidBgColor : "transparent"
    border.width: 1
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
