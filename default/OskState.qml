pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/// The on-screen keyboard's settings that are changed from its own menu:
/// where it is, its size and its sound volume. They are kept in Quickshell's
/// state directory (`osk.json`), unlike OskConfig's hand-edited options.
///
/// - `mode`: "floating" (anywhere on the screen, over other windows), "top"
///   or "bottom" (pinned to that edge at full width, reserving its height so
///   that windows aren't covered by it);
/// - `floatX`, `floatY`: the floating keyboard's position, as fractions of the
///   room left around it (0: left/top edge, 1: right/bottom edge), so that it
///   stays in place relative to the screen when the screen rotates. While
///   the keyboard spans the screen's width, only `floatY` matters;
/// - `scale`: the size of the keys, 1 being their natural size. The keyboard
///   is shrunk further when it wouldn't fit on the screen;
/// - `volume`: the key sounds' volume slider, 0-1, and `muted`.
Singleton {
    id: oskState

    readonly property var modes: ["floating", "top", "bottom"]
    readonly property real minScale: 0.4
    readonly property real maxScale: 2.5

    readonly property string mode: oskState.modes.includes(stateAdapter.mode) ? stateAdapter.mode : "floating"
    readonly property bool floating: oskState.mode === "floating"
    readonly property real floatX: oskState.clamp(stateAdapter.floatX, 0, 1, 0.5)
    readonly property real floatY: oskState.clamp(stateAdapter.floatY, 0, 1, 1)
    readonly property real scale: oskState.clamp(stateAdapter.scale, oskState.minScale, oskState.maxScale, 1)
    readonly property real volume: oskState.clamp(stateAdapter.volume, 0, 1, 0.5)
    readonly property bool muted: stateAdapter.muted === true
    // Linear gain for the sounds: the slider is cubic, like PipeWire's own
    // volume sliders, so that its steps sound even.
    readonly property real soundGain: oskState.muted ? 0 : Math.pow(oskState.volume, 3)

    function clamp(value, min, max, fallback) {
        return typeof value === "number" && isFinite(value) ? Math.min(Math.max(value, min), max) : fallback;
    }

    function setMode(mode: string): void {
        if (oskState.modes.includes(mode)) {
            stateAdapter.mode = mode;
        }
    }

    function setFloatPosition(x: real, y: real): void {
        stateAdapter.floatX = oskState.clamp(x, 0, 1, oskState.floatX);
        stateAdapter.floatY = oskState.clamp(y, 0, 1, oskState.floatY);
    }

    function setScale(scale: real): void {
        stateAdapter.scale = oskState.clamp(scale, oskState.minScale, oskState.maxScale, oskState.scale);
    }

    // Changing the volume unmutes.
    function setVolume(volume: real): void {
        stateAdapter.volume = oskState.clamp(volume, 0, 1, oskState.volume);
        stateAdapter.muted = false;
    }

    function setMuted(muted: bool): void {
        stateAdapter.muted = muted;
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("osk.json")
        // Loaded before the keyboard is first shown, so that it doesn't jump
        // from the defaults to its saved place.
        blockLoading: true
        printErrors: false
        // Moving, resizing and the volume slider change these continuously;
        // they're saved once the changes stop.
        onAdapterUpdated: saveTimer.restart()

        JsonAdapter {
            id: stateAdapter

            property string mode: "floating"
            property real floatX: 0.5
            property real floatY: 1
            property real scale: 1
            property real volume: 0.5
            property bool muted: false
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: stateFile.writeAdapter()
    }
}
