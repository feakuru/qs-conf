pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/// Rotates the built-in screen, along with its touchscreen and pen, to match
/// the accelerometer (via iio-sensor-proxy's `monitor-sensor`).
///
/// When turned off, the screen keeps its current orientation, like a
/// rotation lock. The on/off choice is kept in Quickshell's state directory.
Singleton {
    id: autoRotate

    property bool enabled: false
    // Built-in panel, e.g. "eDP-1"; empty when there is none.
    readonly property string internalMonitorName: {
        let monitor = [...Hyprland.monitors.values].find(monitor => /^(eDP|LVDS|DSI)/.test(monitor.name));
        return monitor ? monitor.name : "";
    }
    // Assumed until monitor-sensor reports otherwise.
    property bool hasAccelerometer: true
    readonly property bool available: internalMonitorName !== "" && hasAccelerometer
    // Hyprland transform last applied here (0-3), or -1 if none yet.
    property int appliedTransform: -1

    readonly property var orientationTransforms: ({
            "normal": 0,
            "left-up": 1,
            "bottom-up": 2,
            "right-up": 3
        })

    function setEnabled(value: bool): void {
        autoRotate.enabled = value;
        stateFile.setText(value ? "on" : "off");
    }

    function toggle(): void {
        autoRotate.setEnabled(!autoRotate.enabled);
    }

    function applyTransform(transform: int): void {
        let name = autoRotate.internalMonitorName;
        if (name === "" || transform < 0) {
            return;
        }
        autoRotate.appliedTransform = transform;
        // hl.monitor() updates the panel's existing rule from hyprland.lua,
        // keeping its mode and scale. Touch and pen input are tied to the
        // panel so that they rotate with it.
        let lua = `hl.monitor({ output = "${name}", transform = ${transform} }); ` + `hl.config({ input = { ` + `touchdevice = { transform = ${transform}, output = "${name}" }, ` + `tablet = { transform = ${transform}, output = "${name}" } } })`;
        applyProcess.command = ["hyprctl", "eval", lua];
        applyProcess.running = true;
    }

    function adoptOrientation(line: string): void {
        if (line.includes("No accelerometer")) {
            autoRotate.hasAccelerometer = false;
            return;
        }
        // "=== Has accelerometer (orientation: normal, ...)" at startup,
        // then "Accelerometer orientation changed: left-up".
        let match = line.match(/orientation(?: changed)?: ([a-z-]+)/);
        if (!match || !(match[1] in autoRotate.orientationTransforms)) {
            return;
        }
        autoRotate.hasAccelerometer = true;
        let transform = autoRotate.orientationTransforms[match[1]];
        if (transform !== autoRotate.appliedTransform) {
            autoRotate.applyTransform(transform);
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("autorotate")
        blockLoading: true
        printErrors: false
        onLoaded: autoRotate.enabled = text().trim() === "on"
    }

    Process {
        id: sensorProcess
        // stdbuf: monitor-sensor would otherwise buffer its output in a pipe.
        command: ["stdbuf", "-oL", "monitor-sensor", "--accel"]
        running: autoRotate.enabled && autoRotate.internalMonitorName !== ""

        stdout: SplitParser {
            onRead: line => autoRotate.adoptOrientation(line)
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "ok") {
                    console.log("AutoRotate: hyprctl eval failed:", this.text.trim());
                }
            }
        }
    }

    // A config reload or reconnecting the panel resets it to the rule in
    // hyprland.lua, i.e. unrotated, so the orientation is applied again.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            let reset = event.name === "configreloaded" || (event.name === "monitoradded" && event.data === autoRotate.internalMonitorName);
            if (reset && autoRotate.appliedTransform > 0) {
                autoRotate.applyTransform(autoRotate.appliedTransform);
            }
        }
    }

    // Lets it be toggled from outside the shell, e.g. a Hyprland keybind:
    //   qs ipc call autorotate toggle
    IpcHandler {
        target: "autorotate"

        function get(): bool {
            return autoRotate.enabled;
        }

        function toggle(): void {
            autoRotate.toggle();
        }
    }
}
