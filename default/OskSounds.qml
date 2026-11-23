pragma Singleton
import QtQuick
import Quickshell

/// The on-screen keyboard's key sounds, at OskState's volume.
///
/// They are played by `pw-play`, outside of the shell: Qt Multimedia's
/// SoundEffect has crashed (QTBUG-142694, Qt < 6.10.2) and can freeze the
/// whole shell when several of them play at once (QTBUG-143167, Qt 6.12.0).
/// Each sound costs a short-lived process and a few tens of milliseconds of
/// latency; this is meant to become a call to a qs-conf-daemon method that
/// plays them through a persistent stream, which only changes play().
Singleton {
    id: oskSounds

    // The files in assets/sounds, by sound name.
    readonly property var files: ({
            shortPress: "osk_short_press.wav",
            longStart: "osk_long_start.wav",
            longEnd: "osk_long_end.wav",
            layerSwitch: "osk_layer_switch.wav"
        })

    function play(name: string): void {
        let volume = OskState.soundGain;
        if (volume <= 0) {
            return;
        }
        let file = oskSounds.files[name];
        if (!file) {
            console.warn("OskSounds: unknown sound:", name);
            return;
        }
        Quickshell.execDetached(["pw-play", "--latency", "20ms", "--volume", volume.toFixed(4), Quickshell.shellPath(`assets/sounds/${file}`)]);
    }
}
