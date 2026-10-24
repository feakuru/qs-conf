pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: windowActions

    // Hyprland reports addresses with and without the 0x prefix depending on the
    // source, but dispatchers always expect it.
    function hyprlandAddress(toplevel) {
        let address = toplevel && toplevel.address ? toplevel.address : "";
        if (address === "") {
            return "";
        }
        return address.startsWith("0x") ? address : `0x${address}`;
    }

    function moveWindowToWorkspace(toplevel, targetWorkspace) {
        let address = windowActions.hyprlandAddress(toplevel);
        if (targetWorkspace < 1 || address === "") {
            return;
        }
        // follow = false keeps the focus on the current workspace instead of
        // dragging the user along with the window.
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${targetWorkspace}, window = "address:${address}", follow = false })`);
        windowActions.scheduleRefresh();
    }

    function toggleWindowFloating(toplevel) {
        let address = windowActions.hyprlandAddress(toplevel);
        if (address === "") {
            return;
        }
        Hyprland.dispatch(`hl.dsp.window.float({ action = "toggle", window = "address:${address}" })`);
        windowActions.scheduleRefresh();
    }

    function closeWindow(toplevel) {
        if (toplevel.wayland) {
            toplevel.wayland.close();
        } else {
            let address = windowActions.hyprlandAddress(toplevel);
            if (address === "") {
                return;
            }
            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${address}" })`);
        }
        windowActions.scheduleRefresh();
    }

    function focusWindow(toplevel) {
        if (toplevel.wayland) {
            toplevel.wayland.activate();
        }
    }

    // lastIpcObject (and with it the floating state) is only updated on an
    // explicit refresh, so batch refreshes after actions and Hyprland events.
    function scheduleRefresh() {
        refreshDelay.restart();
    }

    Timer {
        id: refreshDelay
        interval: 120
        repeat: false
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowActions.scheduleRefresh();
        }
    }
}
