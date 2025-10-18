import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: dropdownToggle
    color: dropdownToggleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    default property alias children: dropdownMenuBody.children
    property alias menuAnchors: dropdownMenuWindow.anchors
    property alias menuMargins: dropdownMenuWindow.margins
    required property string toggleText
    required property color toggleTextColor
    required property real menuWidth

    StyledText {
        color: dropdownToggle.toggleTextColor
        text: dropdownToggle.toggleText
    }

    MouseArea {
        id: dropdownToggleMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouseEvent => {
            dropdownMenuWindow.visible = !dropdownMenuWindow.visible;
        }
    }

    PanelWindow {
        id: dropdownMenuWindow
        focusable: true
        visible: false

        implicitWidth: dropdownToggle.menuWidth
        implicitHeight:             (dropdownMenuBody.children.length - 1) * 42
        

        color: AppConstants.bgColor

        MouseArea {
            id: dropdownMenuWindowArea
            anchors.fill: parent
            propagateComposedEvents: true
            hoverEnabled: true
            onEntered: {
                dropdownMenuWindow.visible = Qt.binding(() => {
                    if (dropdownMenuWindowArea.containsMouse) {
                        return true;
                    }
                    dropdownMenuWindow.visible = false;
                    return false;
                });
            }
            ColumnLayout {
                id: dropdownMenuBody
                anchors.fill: parent
                spacing: 0
            }
        }
    }
}
