pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/// The user's custom actions, listed in CustomActionsMenu:
/// [{name, script, notify?}]. `notify` (default false) asks for a
/// notification with the result when the script ends.
///
/// They are kept in `actions.json` at the root of this repository (gitignored,
/// so each machine has its own), which is created with the defaults below if
/// it doesn't exist. Changes made from the menu are saved there, and changes
/// made to the file show up in the menu right away. Other keys are kept when
/// an action is edited, so the format can grow.
Singleton {
    id: customActions

    readonly property var actions: {
        let actions = actionsAdapter.actions;
        // Once loaded from the file, this is a Qt list (a V4Sequence), which
        // Array.isArray rejects, rather than a JS array; it's copied into one.
        return actions && typeof actions === "object" && typeof actions.length === "number" ? Array.from(actions) : [];
    }

    // Runs the action's script, an executable file ("~/" is the home
    // directory), through the daemon's `script.run`. Its output goes to log
    // files in /tmp. With `notify`, the daemon reports the exit code with a
    // notification that opens the logs' folder when clicked; failing to
    // start it is always reported that way.
    function run(action) {
        let script = action && typeof action.script === "string" ? action.script.trim() : "";
        if (script === "") {
            console.warn("CustomActions: action has no script:", JSON.stringify(action));
            return;
        }
        Daemon.call("script.run", {
            name: typeof action.name === "string" ? action.name : "",
            script: script,
            notify: action.notify === true
        }, (result, error) => {
            if (error !== undefined) {
                console.warn(`CustomActions: script.run ${script} failed:`, error);
            }
        });
    }

    // Replaces the action at `index`, or adds a new one if `index` is -1.
    function save(index, name, script, notify) {
        let fields = {
            name: name,
            script: script,
            notify: notify
        };
        let actions = [...customActions.actions];
        if (index >= 0 && index < actions.length) {
            actions[index] = Object.assign({}, actions[index], fields);
        } else {
            actions.push(fields);
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
                    script: "~/.config/hypr/scripts/toggle-idle.sh",
                    // The script sends a notification of its own.
                    notify: false
                }
            ]
        }
    }
}
