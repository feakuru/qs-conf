import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Keyboard access to the dropdown menus, meant to be bound to a compositor
// shortcut (`qs ipc call dropdownHints toggle`). While active, every visible
// DropdownMenu shows a key label (top bar first, each bar left to right), and
// pressing that key toggles the menu and ends hint mode. Escape ends hint mode
// and closes the open dropdown; calling `toggle` again only ends hint mode.
//
// Keys are read by a tiny, transparent and click-through overlay window with
// exclusive keyboard focus, because popups can't reliably get keyboard focus.
PanelWindow {
    id: dropdownHints

    // Fallback for non-Latin layouts (e.g. Russian), where the typed text
    // isn't one of the hint keys: XKB keycodes of the QWERTY letter keys.
    readonly property var qwertyKeycodes: {
        let keycodes = {};
        let rows = [["qwertyuiop", 24], ["asdfghjkl", 38], ["zxcvbnm", 52]];
        for (let [letters, firstKeycode] of rows) {
            for (let i = 0; i < letters.length; i++) {
                keycodes[firstKeycode + i] = letters[i];
            }
        }
        return keycodes;
    }

    function showHints() {
        // Launchers and prompts need the keyboard themselves.
        if (Dropdowns.current && !Dropdowns.menus.includes(Dropdowns.current)) {
            Dropdowns.current = null;
        }
        Dropdowns.hintedMenus = Dropdowns.menus.filter(menu => menu.visible).map(menu => ({
                    menu: menu,
                    x: menu.mapToItem(null, 0, 0).x
                })).sort((lhs, rhs) => (lhs.menu.opensUpward - rhs.menu.opensUpward) || (lhs.x - rhs.x)).map(entry => entry.menu).slice(0, Dropdowns.hintKeys.length);
        dropdownHints.visible = true;
        keyHandler.forceActiveFocus();
    }

    function hideHints() {
        Dropdowns.hintedMenus = [];
        dropdownHints.visible = false;
    }

    function toggleHints() {
        if (dropdownHints.visible) {
            dropdownHints.hideHints();
        } else {
            dropdownHints.showHints();
        }
    }

    function hintIndexOf(event) {
        let text = event.text.toLowerCase();
        let index = text.length === 1 ? Dropdowns.hintKeys.indexOf(text) : -1;
        if (index < 0 && dropdownHints.qwertyKeycodes[event.nativeScanCode]) {
            index = Dropdowns.hintKeys.indexOf(dropdownHints.qwertyKeycodes[event.nativeScanCode]);
        }
        return index < Dropdowns.hintedMenus.length ? index : -1;
    }

    IpcHandler {
        target: "dropdownHints"

        function toggle(): void {
            dropdownHints.toggleHints();
        }
    }

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (dropdownHints.visible && Dropdowns.current && !Dropdowns.menus.includes(Dropdowns.current)) {
                dropdownHints.hideHints();
            }
        }
    }

    visible: false
    anchors {
        top: true
        left: true
    }
    implicitWidth: 1
    implicitHeight: 1
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    surfaceFormat.opaque: false
    color: "transparent"
    mask: Region {}

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            event.accepted = true;
            if (event.key === Qt.Key_Escape) {
                dropdownHints.hideHints();
                if (Dropdowns.current) {
                    Dropdowns.current = null;
                }
                return;
            }
            let index = dropdownHints.hintIndexOf(event);
            if (index < 0) {
                return;
            }
            let menu = Dropdowns.hintedMenus[index];
            dropdownHints.hideHints();
            menu.toggleMenu();
        }
    }
}
