import QtQuick

// A menu row with a label on the left, a value on the right and a bar behind
// them showing `percent`.
DropdownMenuItem {
    id: usageMenuItem
    property string label: ""
    property color labelColor: AppConstants.styledTextColor
    property string valueText: ""
    property real percent: 0
    property color barColor: AppConstants.indicatorBarColor
    // Room to leave right of the value, e.g. for a button.
    property real valueRightMargin: 12

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: (parent.width - 2) * Math.min(Math.max(usageMenuItem.percent, 0), 100) / 100
        color: usageMenuItem.barColor

        Behavior on width {
            NumberAnimation {
                duration: 300
            }
        }
    }

    StyledText {
        anchors.centerIn: undefined
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: usageValueText.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 16
        color: usageMenuItem.labelColor
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
        text: usageMenuItem.label
    }

    StyledText {
        id: usageValueText
        anchors.centerIn: undefined
        anchors.right: parent.right
        anchors.rightMargin: usageMenuItem.valueRightMargin
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 16
        text: usageMenuItem.valueText
    }
}
