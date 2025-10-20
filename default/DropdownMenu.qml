import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

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
    property alias toggleIconSource: dropdownToggleIcon.source
    property alias toggleIconColor: recoloredIcon.color
    property real preferredWidth: dropdownToggleText.text.split("\n")[0].length * 0.8 * dropdownToggleText.font.pixelSize + (dropdownToggleIcon.source != "" ? dropdownToggleIcon.width : 0)
    menuAnchors.right: true

    RowLayout {
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        spacing: 0
        Rectangle {
            color: "transparent"
            Layout.fillHeight: true
            Layout.preferredWidth: dropdownToggleIcon.width
            IconImage {
                id: dropdownToggleIcon
                anchors.centerIn: parent
                visible: source != ""
                width: 32
                height: 32
            }
            ColorOverlay {
                id: recoloredIcon
                anchors.fill: dropdownToggleIcon
                source: dropdownToggleIcon
                color: "white"
            }
            DropShadow {
                anchors.fill: recoloredIcon
                source: recoloredIcon
                horizontalOffset: 2
                verticalOffset: 2
                radius: 8.0
                color: Qt.rgba(0.1, 0.1, 0.1, 1)
            }
        }
        Rectangle {
            color: "transparent"
            visible: dropdownToggleText.text.length > 0
            Layout.fillHeight: true
            Layout.preferredWidth: dropdownToggleText.width
            Layout.rightMargin: 8
            StyledText {
                id: dropdownToggleText
            }
        }
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
            right: parseInt(Screen.desktopAvailableWidth - dropdownToggle.x - (dropdownToggle.menuWidth / 2) - (dropdownToggle.width / 2))
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
