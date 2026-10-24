import QtQuick
import QtQuick.Layouts
import Quickshell

// A full-width panel along the top or bottom edge of the screen. Children are
// laid out left to right at their implicit width; give one of them
// `Layout.fillWidth: true` to take up the remaining space.
PanelWindow {
    id: bar
    property bool atBottom: false
    default property alias content: barLayout.data

    anchors {
        top: !bar.atBottom
        bottom: bar.atBottom
        left: true
        right: true
    }
    implicitHeight: AppConstants.barHeight

    surfaceFormat.opaque: false
    color: AppConstants.bgColor

    RowLayout {
        id: barLayout
        anchors.fill: parent
        spacing: 0
    }
}
