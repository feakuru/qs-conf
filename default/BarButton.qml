import QtQuick
import QtQuick.Layouts

// A clickable bar widget showing an optional icon and an optional text, sized
// to fit them.
Rectangle {
    id: barButton

    signal clicked(var mouse)

    property alias toggleText: toggleLabel.text
    // Optional text left of the icon. It is right-aligned, so that it stays
    // next to the icon.
    property alias toggleLeadingText: leadingLabel.text
    property alias toggleLeadingTextFont: leadingLabel.font
    property alias toggleLeadingTextHorizontalAlignment: leadingLabel.horizontalAlignment
    // Like toggleTextWidest, for toggleLeadingText.
    property string toggleLeadingTextWidest: ""
    property alias toggleTextFont: toggleLabel.font
    property alias toggleTextColor: toggleLabel.color
    property alias toggleTextHorizontalAlignment: toggleLabel.horizontalAlignment
    // Widest text the label is expected to show (e.g. "100%"); its width is
    // reserved so the widget doesn't resize as the value changes.
    property string toggleTextWidest: ""
    // By default the unused part of the reserved width sits next to the
    // shorter text. If set, it's split evenly on both sides of the centred
    // content instead, which keeps the padding balanced, but the content
    // shifts slightly when the text's width changes.
    property bool balanceReservedWidth: false
    property alias toggleIconSource: toggleIcon.source
    property alias toggleIconColor: toggleIcon.iconColor
    property alias toggleIconOutlineColor: toggleIcon.outlineColor
    property real toggleIconSize: 28
    readonly property alias toggleMouseAreaContainsMouse: toggleMouseArea.containsMouse
    property real horizontalPadding: 10
    // Per-side overrides, e.g. to make up for glyphs with uneven side bearings.
    property real leftPadding: horizontalPadding
    property real rightPadding: horizontalPadding
    // Gap between the leading text, icon and text.
    property alias contentSpacing: toggleContent.spacing
    // Width needed by the icon and text, for widgets that override implicitWidth.
    readonly property real contentImplicitWidth: toggleContent.implicitWidth + leftPadding + rightPadding
    readonly property real unusedReservedWidth: (leadingLabel.visible ? Math.max(0, widestLeadingTextMetrics.advanceWidth - leadingLabel.implicitWidth) : 0) + (toggleLabel.visible ? Math.max(0, widestToggleTextMetrics.advanceWidth - toggleLabel.implicitWidth) : 0)

    implicitWidth: contentImplicitWidth + (balanceReservedWidth ? unusedReservedWidth : 0)
    Layout.fillHeight: true
    color: toggleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

    RowLayout {
        id: toggleContent
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: (barButton.leftPadding - barButton.rightPadding) / 2
        spacing: 5

        StyledText {
            id: leadingLabel
            anchors.centerIn: undefined
            visible: text.length > 0
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: barButton.balanceReservedWidth ? 0 : widestLeadingTextMetrics.advanceWidth
        }

        RecoloredIcon {
            id: toggleIcon
            visible: source.toString() !== ""
            iconColor: AppConstants.iconColor
            iconWidth: barButton.toggleIconSize
            iconHeight: barButton.toggleIconSize
        }

        StyledText {
            id: toggleLabel
            anchors.centerIn: undefined
            visible: text.length > 0
            Layout.minimumWidth: barButton.balanceReservedWidth ? 0 : widestToggleTextMetrics.advanceWidth
        }
    }

    TextMetrics {
        id: widestToggleTextMetrics
        font: toggleLabel.font
        text: barButton.toggleTextWidest
    }

    TextMetrics {
        id: widestLeadingTextMetrics
        font: leadingLabel.font
        text: barButton.toggleLeadingTextWidest
    }

    MouseArea {
        id: toggleMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => barButton.clicked(mouse)
    }
}
