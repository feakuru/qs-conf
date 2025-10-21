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
    property real preferredWidth: {
        dropdownToggleText.text.split("\n")[0].length * 0.7 * dropdownToggleText.font.pixelSize + (dropdownToggleIcon.source != "" ? (dropdownToggleIcon.width + 16) : 0);
    }
    menuAnchors.right: true

    RowLayout {
        spacing: 0
        anchors.fill: parent
        Rectangle {
            color: "transparent"
            Layout.fillHeight: true
            Layout.preferredWidth: dropdownToggleIcon.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: dropdownToggleIcon.source != ""
            IconImage {
                id: dropdownToggleIcon
                anchors.centerIn: parent
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
            Layout.preferredWidth: dropdownToggleText.width + 12
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
            right: {
                let centerOfToggle = Screen.desktopAvailableWidth - dropdownToggle.x - (dropdownToggle.width / 2);
                parseInt(Math.max(centerOfToggle - (dropdownToggle.menuWidth / 2), 10))
            }
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
