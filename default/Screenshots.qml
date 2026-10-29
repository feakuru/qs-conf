pragma Singleton
import QtQuick
import Quickshell

// Screenshots via hyprshot (run by scripts/screenshot.py), which saves them to
// $HYPRSHOT_DIR (or the Pictures folder) and copies them to the clipboard. The
// script reports the outcome with a notification (see NotificationCenter);
// clicking a saved screenshot's notification shows it in the file manager.
Singleton {
    id: screenshots

    // Capturing is delayed so that open menus are gone from the screen, and a
    // window that was just focused has been raised, by the time hyprshot runs.
    readonly property int captureDelay: 300
    // One capture at a time: a second region selection on top of the first
    // one would only get in the way.
    readonly property bool busy: captureDelayTimer.running || screenshotProcess.running

    function captureWindow(toplevel) {
        if (screenshots.busy) {
            return;
        }
        // hyprshot can only capture a specific window by it being the active one.
        WindowActions.focusWindow(toplevel);
        let title = toplevel.title ? toplevel.title : (toplevel.wayland ? toplevel.wayland.title : "");
        screenshots.capture(["window", "--title", title]);
    }

    function captureScreen(screen) {
        screenshots.capture(screen && screen.name ? ["screen", "--output", screen.name] : ["screen"]);
    }

    function captureRegion() {
        screenshots.capture(["region"]);
    }

    function capture(scriptArgs) {
        if (screenshots.busy) {
            return;
        }
        screenshotProcess.scriptArgs = scriptArgs;
        captureDelayTimer.restart();
    }

    Timer {
        id: captureDelayTimer
        interval: screenshots.captureDelay
        repeat: false
        onTriggered: screenshotProcess.running = true
    }

    ScriptProcess {
        id: screenshotProcess
        scriptName: "screenshot"
    }
}
