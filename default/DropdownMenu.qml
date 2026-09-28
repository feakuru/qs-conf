import QtQuick
import QtQuick.Controls
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
    property alias toggleIconColor: dropdownToggleIcon.iconColor
    property alias toggleMouseAreaContainsMouse: dropdownToggleMouseArea.containsMouse
    property real preferredWidth: dropdownToggleText.width + (dropdownToggleIcon.visible ? dropdownToggleIcon.width : 0) + 20
    property list<Item> menuContent
    property list<Item> menuFooter
    property bool disableDisappearanceOnNoFocus: false
    property bool keepInitialMenuHeight: false
    property alias menuVisible: dropdownMenuWindow.visible
    property alias menuFlickable: dropdownMenuFlickable
    property real initialMenuHeight: 0

    function captureInitialMenuHeight() {
        if (!keepInitialMenuHeight || initialMenuHeight > 0 || !dropdownMenuWindow.visible) {
            return;
        }
        if (dropdownMenuBody.childrenRect.height <= 0 || (menuFooter.length > 0 && dropdownMenuFooter.childrenRect.height <= 0)) {
            return;
        }
        initialMenuHeight = (dropdownMenuBody.childrenRect.height + dropdownMenuFooter.childrenRect.height);
    }

    function scrollMenuItemIntoView(item) {
        if (!item) {
            return;
        }
        let flickable = dropdownMenuFlickable;
        if (item.y < flickable.contentY) {
            flickable.contentY = item.y;
        } else if (item.y + item.height > flickable.contentY + flickable.height) {
            flickable.contentY = item.y + item.height - flickable.height;
        }
    }

    function toggleMenuVisibility() {
        dropdownMenuWindow.visible = !dropdownMenuWindow.visible;
    }

    menuAnchors.right: true

    RowLayout {
        spacing: 0
        anchors.fill: parent
        Rectangle {
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        RecoloredIcon {
            id: dropdownToggleIcon
            Layout.fillHeight: true
            Layout.preferredWidth: preferredWidth
            Layout.rightMargin: 5
            visible: source !== ""
            iconWidth: 32
            iconHeight: 32
        }
        Rectangle {
            color: "transparent"
            visible: dropdownToggleText.text.length > 0
            Layout.fillHeight: true
            Layout.preferredWidth: dropdownToggleText.width
            StyledText {
                id: dropdownToggleText
            }
        }
        Rectangle {
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                let foundScreen = Quickshell.screens.find(s => s.name == "DP-1") || Quickshell.screens[0];
                let centerOfToggle = foundScreen.width - dropdownToggle.x - (dropdownToggle.width / 2);
                let targetPosition = centerOfToggle - (dropdownToggle.menuWidth / 2);
                let rightmostPosition = foundScreen.width - dropdownToggle.menuWidth;
                parseInt(Math.min(rightmostPosition, Math.max(targetPosition, 10)));
            }
        }

        implicitHeight: {
            if (dropdownToggle.initialMenuHeight > 0) {
                return dropdownToggle.initialMenuHeight;
            }
            return dropdownMenuBody.childrenRect.height + dropdownMenuFooter.childrenRect.height;
        }
        onVisibleChanged: Qt.callLater(dropdownToggle.captureInitialMenuHeight)

        color: AppConstants.solidBgColor

        Component.onCompleted: {
            for (let c of dropdownToggle.menuContent) {
                c.parent = dropdownMenuBody;
            }
            for (let c of dropdownToggle.menuFooter) {
                c.parent = dropdownMenuFooter;
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
            Flickable {
                id: dropdownMenuFlickable
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: dropdownMenuFooter.top
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: dropdownMenuBody.childrenRect.height

                ScrollBar.vertical: ScrollBar {
                    id: dropdownMenuScrollBar
                    policy: dropdownMenuFlickable.contentHeight > dropdownMenuFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                GridLayout {
                    id: dropdownMenuBody
                    width: dropdownMenuFlickable.width - (dropdownMenuScrollBar.policy === ScrollBar.AlwaysOn ? dropdownMenuScrollBar.width : 0)
                    onChildrenRectChanged: Qt.callLater(dropdownToggle.captureInitialMenuHeight)
                    columnSpacing: 0
                    rowSpacing: 0
                    columns: 1
                }
            }
            ColumnLayout {
                id: dropdownMenuFooter
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                onChildrenRectChanged: Qt.callLater(dropdownToggle.captureInitialMenuHeight)
                spacing: 0
            }
        }
    }
}
