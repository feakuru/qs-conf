pragma Singleton
import QtQuick
import Quickshell

// Screenshots via qs-conf-daemon (`screenshot.capture`, which runs hyprshot):
// they're saved to $HYPRSHOT_DIR (or the Pictures folder) and copied to the
// clipboard. The daemon reports the outcome with a notification (see
// NotificationCenter); clicking a saved screenshot's notification shows it
// in the file manager.
Singleton {
    id: screenshots

    // Capturing is delayed so that open menus are gone from the screen, and a
    // window that was just focused has been raised, by the time hyprshot runs.
    readonly property int captureDelay: 300
    // The capture waiting for captureDelay.
    property var pendingParams: null
    // A screenshot.capture call is pending.
    property bool requested: false
    // One capture at a time: a second region selection on top of the first
    // one would only get in the way. The daemon's `screenshot` topic also
    // covers captures started elsewhere (the PRINT keybinds).
    readonly property bool busy: captureDelayTimer.running || requested || (Daemon.connected && screenshotTopic.latest !== null && screenshotTopic.latest.busy)

    function captureWindow(toplevel) {
        if (screenshots.busy) {
            return;
        }
        // hyprshot can only capture a specific window by it being the active one.
        WindowActions.focusWindow(toplevel);
        let title = toplevel.title ? toplevel.title : (toplevel.wayland ? toplevel.wayland.title : "");
        screenshots.capture({
            mode: "window",
            title: title
        });
    }

    function captureScreen(screen) {
        screenshots.capture(screen && screen.name ? {
            mode: "screen",
            output: screen.name
        } : {
            mode: "screen"
        });
    }

    // Frozen while selecting, like the SHIFT + PRINT keybind, so what's
    // selected is what gets saved.
    function captureRegion() {
        screenshots.capture({
            mode: "region",
            freeze: true
        });
    }

    function capture(params) {
        if (screenshots.busy) {
            return;
        }
        screenshots.pendingParams = params;
        captureDelayTimer.restart();
    }

    Timer {
        id: captureDelayTimer
        interval: screenshots.captureDelay
        repeat: false
        onTriggered: {
            screenshots.requested = Daemon.call("screenshot.capture", screenshots.pendingParams, (result, error) => {
                screenshots.requested = false;
                // Failures were reported with a notification already.
                if (error !== undefined) {
                    console.warn("Screenshots: screenshot.capture failed:", error);
                }
            });
        }
    }

    // {busy}
    DaemonTopic {
        id: screenshotTopic
        topic: "screenshot"
    }
}
