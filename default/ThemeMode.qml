pragma Singleton
import Quickshell
import Quickshell.Io

/// Desktop-wide dark/light colour scheme, owned by qs-conf-daemon (its
/// `theme` topic and `theme.*` methods).
///
/// The daemon applies the mode to the GTK/Qt/icon themes, starts every
/// session dark, and notices changes made outside the shell; this singleton
/// only mirrors it for the shell's own widgets (see AppConstants.qml) and
/// exposes setters for the UI.
Singleton {
    id: themeMode

    readonly property string dark: "dark"
    readonly property string light: "light"

    // Dark until the daemon says otherwise; kept while it's unreachable, so
    // the shell doesn't flash dark during a daemon restart.
    property string mode: dark
    readonly property bool isDark: mode !== light
    // A theme.set call is pending.
    property bool requested: false
    /// True while a switch is in flight, so the UI can avoid queueing requests.
    readonly property bool busy: requested || (Daemon.connected && themeTopic.latest !== null && themeTopic.latest.busy)

    function setMode(newMode: string): void {
        if (themeMode.busy || newMode === themeMode.mode) {
            return;
        }
        if (newMode !== themeMode.dark && newMode !== themeMode.light) {
            console.log("ThemeMode: refusing to set unknown mode:", newMode);
            return;
        }
        themeMode.requested = Daemon.call("theme.set", {
            mode: newMode
        }, (result, error) => {
            themeMode.requested = false;
            if (error !== undefined) {
                console.warn("ThemeMode: theme.set failed:", error);
            }
        });
    }

    function toggle(): void {
        themeMode.setMode(themeMode.isDark ? themeMode.light : themeMode.dark);
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

    // {mode, busy}
    DaemonTopic {
        id: themeTopic
        topic: "theme"
        onData: state => {
            if (state.mode === themeMode.dark || state.mode === themeMode.light) {
                themeMode.mode = state.mode;
            }
        }
    }
}
