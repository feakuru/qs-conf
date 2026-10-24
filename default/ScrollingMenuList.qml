import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A list of menu rows showing at most `maxVisibleRows` of them; the rest
// scroll. The rows (usually a Repeater) go inside it, must all have the same
// height, and `rowCount` must say how many there are. Hidden when empty.
Flickable {
    id: scrollingMenuList

    property int rowCount: 0
    property int maxVisibleRows: 3
    default property alias rows: scrollingMenuListColumn.data

    visible: rowCount > 0
    Layout.fillWidth: true
    implicitHeight: rowCount > 0 ? scrollingMenuListColumn.implicitHeight * Math.min(rowCount, maxVisibleRows) / rowCount : 0
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: scrollingMenuListColumn.implicitHeight

    ScrollBar.vertical: ScrollBar {
        id: scrollingMenuListScrollBar
        // Hover-enabled controls swallow hover events, which would hide the
        // pointer from the menu (see DropdownMenu.qml).
        hoverEnabled: false
        policy: scrollingMenuList.contentHeight > scrollingMenuList.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    }

    ColumnLayout {
        id: scrollingMenuListColumn
        width: scrollingMenuList.width - (scrollingMenuListScrollBar.policy === ScrollBar.AlwaysOn ? scrollingMenuListScrollBar.width : 0)
        spacing: 0
    }
}
