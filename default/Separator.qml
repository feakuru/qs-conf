import QtQuick
import QtQuick.Layouts

// Thin rounded line that visually separates bar widgets (vertical) or menu
// rows (horizontal).
Rectangle {
    property bool vertical: true
    property real thickness: 2
    // Only used when vertical; horizontal separators are sized by their anchors.
    property real length: 26

    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? length : thickness
    Layout.alignment: Qt.AlignCenter
    radius: thickness / 2
    color: AppConstants.indicatorBorderColor
}
