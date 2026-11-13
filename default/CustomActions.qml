pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/// The user's custom actions, listed in CustomActionsMenu:
/// [{name, type?, …}], where `type` (default "script") says what runs:
/// - "script": `script`, an executable file ("~/" is the home directory);
/// - "command": `command`, a command for the login shell (`$SHELL -c`);
/// - "app": `app`, the id of an application's desktop entry, one of those
///   the program picker offers.
///
/// Scripts and commands also have these options, all booleans:
/// - `saveOutput` (default true): stdout and stderr go to log files;
/// - `terminal` (default false): it runs in the default terminal instead,
///   so its output isn't saved;
/// - `keepOpen` (default false): with `terminal`, the terminal stays open
///   once it ends, until Enter is pressed;
/// - `notify` (default false): a notification with the result when it ends.
///
/// They are kept in `actions.json` at the root of this repository (gitignored,
/// so each machine has its own), which is created with the defaults below if
/// it doesn't exist. Changes made from the menu are saved there, and changes
/// made to the file show up in the menu right away. Other keys are kept when
/// an action is edited, so the format can grow.
Singleton {
    id: customActions

    readonly property var types: ["script", "command", "app"]
    // The keys that depend on the type; they are replaced on saving.
    readonly property var typedKeys: ["script", "command", "app", "saveOutput", "terminal", "keepOpen", "notify"]

    readonly property var actions: {
        let actions = actionsAdapter.actions;
        // Once loaded from the file, this is a Qt list (a V4Sequence), which
        // Array.isArray rejects, rather than a JS array; it's copied into one.
        return actions && typeof actions === "object" && typeof actions.length === "number" ? Array.from(actions) : [];
    }

    // The applications the program picker offers (one per name), by name.
    readonly property var apps: [...new Map(DesktopEntries.applications.values.map(entry => [entry.name, entry])).values()].sort((lhs, rhs) => lhs.name.localeCompare(rhs.name))

    function typeOf(action) {
        return action && customActions.types.includes(action.type) ? action.type : "script";
    }

    // The Font Awesome icon for actions of `type`.
    function typeIconName(type) {
        switch (type) {
        case "command":
            return "terminal";
        case "app":
            return "rocket";
        default:
            return "file-code";
        }
    }

    // The desktop entry with this id, or null if it isn't installed.
    // Bindings that call this are updated when the applications change.
    function appEntry(id) {
        if (typeof id !== "string" || id === "") {
            return null;
        }
        return customActions.apps.find(entry => entry.id === id) ?? DesktopEntries.byId(id);
    }

    // The options of a script or command, with their defaults; `terminal`
    // rules out `saveOutput`, and `keepOpen` needs `terminal`.
    function options(action) {
        let terminal = action?.terminal === true;
        return {
            saveOutput: !terminal && action?.saveOutput !== false,
            terminal: terminal,
            keepOpen: terminal && action?.keepOpen === true,
            notify: action?.notify === true
        };
    }

    function run(action) {
        if (customActions.typeOf(action) === "app") {
            customActions.launchApp(action);
        } else {
            customActions.runThroughDaemon(action);
        }
    }

    // As the program picker launches it.
    function launchApp(action) {
        let entry = customActions.appEntry(action.app);
        if (!entry) {
            console.warn("CustomActions: app isn't installed:", JSON.stringify(action));
            return;
        }
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["xdg-terminal-exec", ...Array.from(entry.command)],
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
    }

    // Scripts and commands run through the daemon's `script.run`. Logged
    // runs' output goes to log files in /tmp. With `notify`, the daemon
    // reports the exit code with a notification (for logged runs, it opens
    // the logs' folder when clicked); failing to start is always reported
    // that way.
    function runThroughDaemon(action) {
        let type = customActions.typeOf(action);
        let target = typeof action[type] === "string" ? action[type].trim() : "";
        if (target === "") {
            console.warn(`CustomActions: action has no ${type}:`, JSON.stringify(action));
            return;
        }
        let options = customActions.options(action);
        let params = {
            name: typeof action.name === "string" ? action.name : "",
            notify: options.notify,
            output: options.terminal ? "terminal" : options.saveOutput ? "log" : "discard",
            hold: options.keepOpen
        };
        params[type] = target;
        Daemon.call("script.run", params, (result, error) => {
            if (error !== undefined) {
                console.warn(`CustomActions: script.run ${target} failed:`, error);
            }
        });
    }

    // Replaces the action at `index`, or adds a new one if `index` is -1.
    // `fields` has the name, type and the type's own keys; the previous
    // type's keys are dropped.
    function save(index, fields) {
        let actions = [...customActions.actions];
        let editing = index >= 0 && index < actions.length;
        let action = editing ? Object.assign({}, actions[index]) : {};
        for (let key of customActions.typedKeys) {
            delete action[key];
        }
        Object.assign(action, fields);
        if (editing) {
            actions[index] = action;
        } else {
            actions.push(action);
        }
        actionsAdapter.actions = actions;
    }

    function remove(index) {
        actionsAdapter.actions = customActions.actions.filter((action, i) => i !== index);
    }

    FileView {
        path: Quickshell.shellPath("../actions.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: actionsAdapter

            property var actions: [
                {
                    name: "Toggle idle handling",
                    type: "script",
                    script: "~/.config/hypr/scripts/toggle-idle.sh",
                    saveOutput: true,
                    // The script sends a notification of its own.
                    notify: false
                }
            ]
        }
    }
}
