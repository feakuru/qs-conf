import QtQuick
import QtQuick.Layouts

// A menu row with a label on the left (with an optional smaller suffix), a
// value on the right and a bar behind them showing `percent`. An optional
// second, smaller line has its own label and value.
DropdownMenuItem {
    id: usageMenuItem
    property string label: ""
    property color labelColor: AppConstants.styledTextColor
    // E.g. Text.ElideMiddle for names whose end tells them apart.
    property int labelElide: Text.ElideRight
    // Shown right after the label, smaller and muted, e.g. "[active]".
    property string labelSuffix: ""
    property string valueText: ""
    property string detailLabel: ""
    property string detailValueText: ""
    property real percent: 0
    property color barColor: AppConstants.indicatorBarColor
    // Room to leave right of the value, e.g. for a button.
    property real valueRightMargin: 12

    readonly property bool hasDetails: detailLabel !== "" || detailValueText !== ""

    Layout.preferredHeight: usageTextColumn.implicitHeight + 16

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

    Column {
        id: usageTextColumn
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: usageMenuItem.valueRightMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Item {
            width: parent.width
            implicitHeight: Math.max(usageLabelText.implicitHeight, usageValueText.implicitHeight)

            StyledText {
                id: usageLabelText
                readonly property real suffixSpace: usageLabelSuffixText.visible ? usageLabelSuffixText.implicitWidth + usageLabelSuffixText.anchors.leftMargin : 0
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                // As wide as the text, so the suffix follows it, but it
                // elides before running into the value.
                width: Math.max(0, Math.min(implicitWidth, usageValueText.x - 12 - suffixSpace))
                font.pixelSize: 16
                color: usageMenuItem.labelColor
                horizontalAlignment: Text.AlignLeft
                elide: usageMenuItem.labelElide
                text: usageMenuItem.label
            }

            StyledText {
                id: usageLabelSuffixText
                visible: usageMenuItem.labelSuffix !== ""
                anchors.centerIn: undefined
                anchors.left: usageLabelText.right
                anchors.leftMargin: 6
                anchors.baseline: usageLabelText.baseline
                font.pixelSize: 13
                color: AppConstants.mutedIconColor
                text: usageMenuItem.labelSuffix
            }

            StyledText {
                id: usageValueText
                anchors.centerIn: undefined
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 16
                text: usageMenuItem.valueText
            }
        }

        Item {
            visible: usageMenuItem.hasDetails
            width: parent.width
            implicitHeight: Math.max(usageDetailLabelText.implicitHeight, usageDetailValueText.implicitHeight)

            StyledText {
                id: usageDetailLabelText
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.right: usageDetailValueText.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 13
                color: AppConstants.mutedIconColor
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: usageMenuItem.detailLabel
            }

            StyledText {
                id: usageDetailValueText
                anchors.centerIn: undefined
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 13
                color: AppConstants.mutedIconColor
                text: usageMenuItem.detailValueText
            }
        }
    }
}
