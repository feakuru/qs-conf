import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: dropdownToggle
    color: dropdownToggleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    default property alias children: dropdownMenuBody.children
    property alias menuWidth: dropdownMenuWindow.implicitWidth
    property alias menuAnchors: dropdownMenuWindow.anchors
    property alias toggleText: dropdownToggleText.text
    property alias toggleTextFont: dropdownToggleText.font
    property alias toggleTextColor: dropdownToggleText.color
    property alias toggleTextHorizontalAlignment: dropdownToggleText.horizontalAlignment
    property real preferredWidth: dropdownToggleText.text.split("\n")[0].length * 0.7 * dropdownToggleText.font.pixelSize + 12
    menuAnchors.right: true

    StyledText {
        id: dropdownToggleText
        anchors.centerIn: null
        anchors.fill: parent
        anchors.margins: 7
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
        margins {
            right: parseInt(Screen.desktopAvailableWidth - dropdownToggle.x - dropdownToggle.menuWidth)
        }

        implicitHeight: dropdownMenuBody.childrenRect.height

        color: AppConstants.solidBgColor

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
