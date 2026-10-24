import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// A bar button that opens a popup menu attached to it.
//
// The menu closes when:
// - the button is clicked again,
// - the mouse leaves the menu (after a short grace period, and only if it was
//   inside the menu at some point, so a menu that was opened but never visited
//   stays open),
// - another dropdown is opened.
//
// There is deliberately no click-outside dismissal: it needs a
// HyprlandFocusGrab, and with one active the popup received no pointer input
// at all (no hover, and clicks inside the menu counted as outside), even when
// the grab was only started after the popup's window was shown.
BarButton {
    id: dropdown

    property real menuWidth: 300
    property bool opensUpward: false
    property alias menuColumns: dropdownMenuBody.columns
    property alias menuContent: dropdownMenuBody.data
    readonly property alias menuVisible: dropdownPopup.visible
    property int closeOnLeaveDelay: 600

    function openMenu() {
        dropdown.pointerVisitedMenu = false;
        Dropdowns.current = dropdown;
        dropdownPopup.visible = true;
    }

    function closeMenu() {
        closeOnLeaveTimer.stop();
        dropdownPopup.visible = false;
        if (Dropdowns.current === dropdown) {
            Dropdowns.current = null;
        }
    }

    function toggleMenu() {
        if (dropdown.menuVisible) {
            dropdown.closeMenu();
        } else {
            dropdown.openMenu();
        }
    }

    onClicked: toggleMenu()

    property bool pointerVisitedMenu: false
    readonly property bool pointerInside: dropdownMenuHover.hovered || dropdown.toggleMouseAreaContainsMouse

    onPointerInsideChanged: {
        if (!dropdown.menuVisible) {
            return;
        }
        if (dropdown.pointerInside) {
            closeOnLeaveTimer.stop();
        } else if (dropdown.pointerVisitedMenu) {
            closeOnLeaveTimer.restart();
        }
    }

    Timer {
        id: closeOnLeaveTimer
        interval: dropdown.closeOnLeaveDelay
        onTriggered: dropdown.closeMenu()
    }

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (Dropdowns.current !== dropdown && dropdown.menuVisible) {
                dropdown.closeMenu();
            }
        }
    }

    PopupWindow {
        id: dropdownPopup
        visible: false
        color: AppConstants.solidBgColor

        anchor {
            item: dropdown
            // Centred on the button, below it (or above it for bottom bars).
            edges: dropdown.opensUpward ? Edges.Top : Edges.Bottom
            gravity: dropdown.opensUpward ? Edges.Top : Edges.Bottom
            adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        }

        implicitWidth: dropdown.menuWidth
        // Rounded up: windows have whole-pixel sizes, and rounding down would
        // make the content overflow by a fraction and show the scrollbar.
        implicitHeight: Math.max(1, Math.ceil(dropdownMenuBody.implicitHeight))

        Item {
            anchors.fill: parent

            // Sits on the ancestor of all menu content. Qt stops delivering
            // hover to ancestors as soon as a descendant accepts it, which
            // hover-enabled MouseAreas and Controls do, so menu content must
            // track hover with HoverHandlers (which don't accept) instead.
            HoverHandler {
                id: dropdownMenuHover
                // Touch input has no hover, so touch users close the menu with
                // its button instead.
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onHoveredChanged: {
                    if (hovered) {
                        dropdown.pointerVisitedMenu = true;
                    }
                }
            }

            Flickable {
                id: dropdownMenuFlickable
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: dropdownMenuBody.implicitHeight

                ScrollBar.vertical: ScrollBar {
                    id: dropdownMenuScrollBar
                    // Hover-enabled controls swallow hover events, which
                    // would hide the pointer from dropdownMenuHover.
                    hoverEnabled: false
                    policy: dropdownMenuFlickable.contentHeight > dropdownMenuFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                GridLayout {
                    id: dropdownMenuBody
                    width: dropdownMenuFlickable.width - (dropdownMenuScrollBar.policy === ScrollBar.AlwaysOn ? dropdownMenuScrollBar.width : 0)
                    columns: 1
                    columnSpacing: 0
                    rowSpacing: 0
                }
            }
        }
    }
}
