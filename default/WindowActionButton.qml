import QtQuick
import QtQuick.Layouts

Rectangle {
    id: windowActionButton

    property string iconName: ""
    property bool highlighted: false
    property bool enabledAction: true
    property color activeIconColor: AppConstants.indicatorOnColor
    property var action: () => {}

    implicitWidth: 30
    implicitHeight: 30
    Layout.alignment: Qt.AlignVCenter

    radius: 5
    border.width: 1
    border.color: windowActionButtonHover.hovered && windowActionButton.enabledAction ? AppConstants.indicatorBorderColor : "transparent"
    color: windowActionButtonHover.hovered && windowActionButton.enabledAction ? AppConstants.focusedBgColor : "transparent"
    opacity: windowActionButton.enabledAction ? 1.0 : 0.3

    RecoloredIcon {
        anchors.fill: parent
        iconWidth: 16
        iconHeight: 16
        source: windowActionButton.iconName === "" ? "" : Qt.resolvedUrl(`assets/icons/fontawesome/solid/${windowActionButton.iconName}.svg`)
        iconColor: windowActionButton.highlighted || windowActionButtonHover.hovered ? windowActionButton.activeIconColor : AppConstants.styledTextColor
    }

    // A HoverHandler rather than MouseArea.hoverEnabled, so hover still
    // propagates to parents (this button is also used inside dropdown menus,
    // see DropdownMenu.qml).
    HoverHandler {
        id: windowActionButtonHover
        cursorShape: windowActionButton.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    MouseArea {
        id: windowActionButtonMouseArea
        anchors.fill: parent
        onClicked: mouseEvent => {
            if (!windowActionButton.enabledAction) {
                return;
            }
            windowActionButton.action(mouseEvent);
        }
    }
}
