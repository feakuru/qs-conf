import QtQuick

// A touch-sized button of the on-screen keyboard's menu and editor: an icon
// with an optional label under it.
Rectangle {
    id: oskButton

    property string iconName: ""
    property string label: ""
    property bool highlighted: false
    property bool enabledAction: true
    property color activeIconColor: AppConstants.indicatorOnColor
    property var action: () => {}

    implicitWidth: 56
    implicitHeight: oskButton.label === "" ? 44 : 56

    radius: 6
    border.width: 1
    border.color: oskButton.highlighted ? AppConstants.indicatorOnColor : AppConstants.indicatorBorderColor
    color: buttonArea.pressed ? AppConstants.pressedSolidBgColor : oskButton.highlighted ? AppConstants.focusedSolidBgColor : AppConstants.solidBgColor
    opacity: oskButton.enabledAction ? 1 : 0.4

    Column {
        anchors.centerIn: parent
        spacing: 4

        RecoloredIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            iconWidth: 18
            iconHeight: 18
            source: oskButton.iconName === "" ? "" : Qt.resolvedUrl(`assets/icons/fontawesome/solid/${oskButton.iconName}.svg`)
            iconColor: oskButton.highlighted ? oskButton.activeIconColor : AppConstants.styledTextColor
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.horizontalCenter: parent.horizontalCenter
            visible: oskButton.label !== ""
            text: oskButton.label
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        onClicked: {
            if (oskButton.enabledAction) {
                oskButton.action();
            }
        }
    }
}
