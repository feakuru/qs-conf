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
//   stays open; never once the button or menu has been touched while open,
//   see touchUsed),
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
        dropdown.touchUsed = false;
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

    // Index of this menu's key in Dropdowns.hintKeys, or -1 if no key label is
    // shown.
    readonly property int hintIndex: Dropdowns.hintedMenus.indexOf(dropdown)

    Component.onCompleted: Dropdowns.menus = Dropdowns.menus.concat([dropdown])
    Component.onDestruction: {
        Dropdowns.menus = Dropdowns.menus.filter(menu => menu !== dropdown);
        Dropdowns.hintedMenus = Dropdowns.hintedMenus.filter(menu => menu !== dropdown);
    }

    Rectangle {
        anchors.centerIn: parent
        z: 1
        visible: dropdown.hintIndex >= 0
        width: Math.max(height, hintText.implicitWidth + 10)
        height: hintText.implicitHeight + 4
        radius: 4
        color: AppConstants.solidBgColor
        border.width: 2
        border.color: AppConstants.indicatorOnColor

        StyledText {
            id: hintText
            font.pixelSize: 18
            font.bold: true
            text: dropdown.hintIndex >= 0 ? Dropdowns.hintKeys.charAt(dropdown.hintIndex).toUpperCase() : ""
        }
    }

    property bool pointerVisitedMenu: false
    readonly property bool pointerInside: dropdownMenuHover.hovered || dropdown.toggleMouseAreaContainsMouse

    // Qt Quick turns the first touch point into synthetic hover events that
    // claim to come from the core pointer device (so HoverHandler's
    // acceptedDevices can't filter them out), and that hover ends after the
    // finger lifts. Without this flag, every tap inside the menu would count as
    // "the mouse visited and left", and the menu would close shortly after it.
    // Set on a touch press on the button or in the menu; reset when the menu
    // closes.
    property bool touchUsed: false

    onTouchUsedChanged: {
        if (dropdown.touchUsed) {
            closeOnLeaveTimer.stop();
        }
    }

    onPointerInsideChanged: {
        if (!dropdown.menuVisible) {
            return;
        }
        if (dropdown.pointerInside) {
            closeOnLeaveTimer.stop();
        } else if (dropdown.pointerVisitedMenu && !dropdown.touchUsed) {
            closeOnLeaveTimer.restart();
        }
    }

    // A HoverHandler is "hovered" while a finger is pressed on its item, even
    // when a child MouseArea has grabbed the touch. PointHandler/TapHandler
    // would not work here: they ignore points that a child already grabbed.
    HoverHandler {
        acceptedDevices: PointerDevice.TouchScreen
        onHoveredChanged: {
            if (hovered) {
                dropdown.touchUsed = true;
            }
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
                // This doesn't keep touch out: synthetic hover from touch is
                // reported by the core pointer device (see touchUsed).
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onHoveredChanged: {
                    if (hovered) {
                        dropdown.pointerVisitedMenu = true;
                    }
                }
            }

            // Touch users close the menu with its button instead. See the
            // button's touch HoverHandler for why this is a HoverHandler.
            HoverHandler {
                acceptedDevices: PointerDevice.TouchScreen
                onHoveredChanged: {
                    if (hovered) {
                        dropdown.touchUsed = true;
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
