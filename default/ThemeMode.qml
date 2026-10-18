pragma Singleton
import Quickshell
import Quickshell.Io

/// Desktop-wide dark/light colour scheme, backed by scripts/theme_toggle.py.
///
/// The script owns the persisted preference and the propagation to
/// GTK/Qt/icon themes; this singleton only mirrors it for the shell's own
/// widgets (see AppConstants.qml) and exposes setters for the UI.
Singleton {
    id: themeMode

    readonly property string dark: "dark"
    readonly property string light: "light"

    property string mode: dark
    readonly property bool isDark: mode !== light
    /// True while a switch is in flight, so the UI can avoid queueing requests.
    readonly property bool busy: setDarkProcess.running || setLightProcess.running

    /// Re-read the mode from the script (cheap; use after external changes).
    function refresh(): void {
        if (!getProcess.running && !themeMode.busy) {
            getProcess.running = true;
        }
    }

    function setMode(newMode: string): void {
        if (themeMode.busy || newMode === themeMode.mode) {
            return;
        }
        if (newMode === themeMode.dark) {
            setDarkProcess.running = true;
        } else if (newMode === themeMode.light) {
            setLightProcess.running = true;
        } else {
            console.log("ThemeMode: refusing to set unknown mode:", newMode);
        }
    }

    function toggle(): void {
        themeMode.setMode(themeMode.isDark ? themeMode.light : themeMode.dark);
    }

    /// Adopt a mode name printed by theme_toggle.py.
    function adopt(output: string): void {
        let value = output.trim();
        if (value === themeMode.dark || value === themeMode.light) {
            themeMode.mode = value;
        } else if (value.length > 0) {
            console.log("ThemeMode: unexpected theme_toggle output:", value);
        }
    }

    // Lets the mode be driven from outside the shell, e.g. a Hyprland keybind:
    //   qs ipc call theme toggle
    IpcHandler {
        target: "theme"

        function get(): string {
            return themeMode.mode;
        }

        function toggle(): void {
            themeMode.toggle();
        }

        function setMode(mode: string): void {
            themeMode.setMode(mode);
        }
    }

    component ThemeProcess: ScriptProcess {
        scriptName: "theme_toggle"

        stdout: StdioCollector {
            onStreamFinished: themeMode.adopt(this.text)
        }
    }

    ThemeProcess {
        id: getProcess
        scriptArgs: ["get"]
        running: true
    }

    ThemeProcess {
        id: setDarkProcess
        scriptArgs: ["set", themeMode.dark]
    }

    ThemeProcess {
        id: setLightProcess
        scriptArgs: ["set", themeMode.light]
    }
}
