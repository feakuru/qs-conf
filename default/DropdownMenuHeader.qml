import QtQuick
import QtQuick.Layouts

Rectangle {
    property alias text: headerText.text

    Layout.fillWidth: true
    Layout.preferredHeight: 28
    color: AppConstants.accentColor

    StyledText {
        id: headerText
        anchors.centerIn: undefined
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 14
        horizontalAlignment: Text.AlignLeft
    }
}
