import QtQuick
import QtQuick.Layouts

// A row for something the lights menu can set: every zone, a device or one
// zone. Shows an icon, a name (and an optional muted detail), and what it
// shows: the effect's icon and its colours, or `emptyText` without a
// setting. Marked while `selected`. With `canIdentify`, a button blinks the
// zone (`identifyAction`), highlighted while it's `identifying`.
DropdownMenuItem {
    id: targetItem

    property string iconName: "lightbulb"
    property string text: ""
    property string detailText: ""
    // Left indentation, e.g. for the zones under their device.
    property real indent: 0
    property bool selected: false
    // {effect, colors, speed}, or null.
    property var setting: null
    property string emptyText: "not set"
    property bool canIdentify: false
    property bool identifying: false
    property var identifyAction: () => {}

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        width: 3
        radius: 1.5
        visible: targetItem.selected
        color: AppConstants.indicatorOnColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12 + targetItem.indent
        anchors.rightMargin: 6
        spacing: 10

        RecoloredIcon {
            Layout.alignment: Qt.AlignVCenter
            iconWidth: 20
            iconHeight: 20
            source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/${targetItem.iconName}.svg`)
            iconColor: targetItem.selected ? AppConstants.indicatorOnColor : AppConstants.iconColor
        }

        StyledText {
            anchors.centerIn: undefined
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 16
            font.bold: targetItem.selected
            textFormat: Text.PlainText
            elide: Text.ElideRight
            text: targetItem.text
        }

        StyledText {
            anchors.centerIn: undefined
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 140
            visible: text.length > 0
            font.pixelSize: 13
            color: AppConstants.mutedIconColor
            textFormat: Text.PlainText
            elide: Text.ElideRight
            text: targetItem.identifying ? "blinking…" : targetItem.detailText
        }

        // What it shows.
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            StyledText {
                anchors.centerIn: undefined
                anchors.verticalCenter: parent.verticalCenter
                visible: targetItem.setting === null
                font.pixelSize: 13
                color: AppConstants.mutedIconColor
                text: targetItem.emptyText
            }

            RecoloredIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: targetItem.setting !== null
                iconWidth: 16
                iconHeight: 16
                source: targetItem.setting === null ? "" : Qt.resolvedUrl(`assets/icons/fontawesome/solid/${Lights.effectIcon(targetItem.setting.effect)}.svg`)
                iconColor: AppConstants.mutedIconColor
            }

            Repeater {
                model: targetItem.setting?.colors ?? []
                delegate: Rectangle {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: modelData
                    border.width: 1
                    border.color: AppConstants.indicatorBorderColor
                }
            }
        }

        // Keeps the previews lined up whether or not a row can identify.
        Item {
            implicitWidth: 30
            implicitHeight: 30
            Layout.alignment: Qt.AlignVCenter

            WindowActionButton {
                anchors.fill: parent
                visible: targetItem.canIdentify
                iconName: "crosshairs"
                highlighted: targetItem.identifying
                action: () => targetItem.identifyAction()
            }
        }
    }
}
