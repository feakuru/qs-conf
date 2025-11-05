import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Rectangle {
    id: dropdownToggle
    color: dropdownToggleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor

    property alias menuWidth: dropdownMenuWindow.implicitWidth
    property alias menuAnchors: dropdownMenuWindow.anchors
    property alias menuColumns: dropdownMenuBody.columns
    property alias menuRows: dropdownMenuBody.rows
    property alias toggleText: dropdownToggleText.text
    property alias toggleTextFont: dropdownToggleText.font
    property alias toggleTextColor: dropdownToggleText.color
    property alias toggleTextHorizontalAlignment: dropdownToggleText.horizontalAlignment
    property alias toggleIconSource: dropdownToggleIcon.source
    property alias toggleIconColor: recoloredIcon.color
    property alias toggleMouseAreaContainsMouse: dropdownToggleMouseArea.containsMouse
    property real preferredWidth: dropdownToggleText.width + (dropdownToggleIcon.visible ? dropdownToggleIcon.width : 0) + 20
    property list<Item> menuContent
    property bool disableDisappearanceOnNoFocus: false

    function toggleMenuVisibility() {
        dropdownMenuWindow.visible = !dropdownMenuWindow.visible;
    }

    menuAnchors.right: true

    RowLayout {
        spacing: 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
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
            dropdownToggle.toggleMenuVisibility();
        }
    }

    PanelWindow {
        id: dropdownMenuWindow
        focusable: true
        visible: false
        margins {
            right: {
                let centerOfToggle = Screen.desktopAvailableWidth - dropdownToggle.x - (dropdownToggle.width / 2);
                let targetPosition = centerOfToggle - (dropdownToggle.menuWidth / 2);
                let rightmostPosition = Screen.desktopAvailableWidth - dropdownToggle.menuWidth;
                parseInt(Math.min(rightmostPosition, Math.max(targetPosition, 10)));
            }
        }

        implicitHeight: dropdownMenuBody.childrenRect.height

        color: AppConstants.solidBgColor

        Component.onCompleted: {
            for (let c of dropdownToggle.menuContent) {
                c.parent = dropdownMenuBody;
            }
        }

        MouseArea {
            id: dropdownMenuWindowArea
            anchors.fill: parent
            propagateComposedEvents: true
            hoverEnabled: true
            onEntered: {
                if (dropdownToggle.disableDisappearanceOnNoFocus) {
                    return;
                }
                dropdownMenuWindow.visible = Qt.binding(() => {
                    if (dropdownMenuWindowArea.containsMouse) {
                        return true;
                    }
                    dropdownMenuWindow.visible = false;
                    return false;
                });
            }
            GridLayout {
                id: dropdownMenuBody
                anchors.fill: parent
                columnSpacing: 0
                rowSpacing: 0
                columns: 1
            }
        }
    }
}
