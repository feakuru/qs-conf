import QtQuick
import QtQuick.Layouts

Rectangle {
    id: windowActionButton

    property string iconName: ""
    property bool highlighted: false
    property bool enabledAction: true
    property color activeIconColor: AppConstants.indicatorOnColor
    property var action: () => {}

    Layout.preferredWidth: 30
    Layout.preferredHeight: 30
    Layout.alignment: Qt.AlignVCenter

    radius: 5
    border.width: 1
    border.color: windowActionButtonMouseArea.containsMouse && windowActionButton.enabledAction ? AppConstants.indicatorBorderColor : "transparent"
    color: windowActionButtonMouseArea.containsMouse && windowActionButton.enabledAction ? AppConstants.focusedBgColor : "transparent"
    opacity: windowActionButton.enabledAction ? 1.0 : 0.3

    RecoloredIcon {
        anchors.fill: parent
        iconWidth: 16
        iconHeight: 16
        source: windowActionButton.iconName === "" ? "" : Qt.resolvedUrl(`assets/icons/fontawesome/solid/${windowActionButton.iconName}.svg`)
        iconColor: windowActionButton.highlighted || windowActionButtonMouseArea.containsMouse ? windowActionButton.activeIconColor : AppConstants.styledTextColor
    }

    MouseArea {
        id: windowActionButtonMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: windowActionButton.enabledAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouseEvent => {
            if (!windowActionButton.enabledAction) {
                return;
            }
            windowActionButton.action(mouseEvent);
        }
    }
}
