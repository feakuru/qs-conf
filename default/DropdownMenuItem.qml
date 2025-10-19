import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: dropdownItem
    Layout.preferredHeight: 42
    Layout.fillWidth: true
    property var action: () => {}
    property alias text: dropdownItemText.text

    color: dropdownItemMouseArea.containsMouse ? AppConstants.focusedSolidBgColor : "transparent"
    border.width: 1
    StyledText {
        id: dropdownItemText
        font.pixelSize: 18
    }
    MouseArea {
        id: dropdownItemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: evt => {
            dropdownItem.action(evt);
        }
    }
}
