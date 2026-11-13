import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Adds, edits or deletes one of CustomActions' actions, centred on the screen.
// Like NotificationReplyPrompt, it uses its own layer-shell window, because
// typing needs keyboard focus, which popups can't reliably get. Enter saves;
// it closes on Escape, on "Cancel", after saving or deleting, or when a
// dropdown is opened.
//
// An action is a script, a shell command or an app (see CustomActions); the
// row under the name switches between them. Scripts are chosen in the
// desktop's file chooser (the daemon's `file.pick`). The editor hides while
// that dialog is open: it would cover the dialog, and its exclusive keyboard
// focus would keep typing from reaching it. Apps are chosen from the program
// picker's applications, filtered by the search field above them (Enter
// picks the first match).
PanelWindow {
    id: actionEditor

    // Index in CustomActions.actions, or -1 for a new action.
    property int actionIndex: -1
    property string actionType: "script"
    property string scriptPath: ""
    // A desktop entry id.
    property string appId: ""
    // The options of scripts and commands (see CustomActions.options).
    property bool saveOutput: true
    property bool inTerminal: false
    property bool keepOpen: false
    property bool notifyResult: false
    // A file.pick call is pending.
    property bool picking: false
    property string message: ""
    readonly property bool isNew: actionIndex < 0
    readonly property var appEntry: CustomActions.appEntry(appId)
    // The script, command or app id.
    readonly property string target: {
        switch (actionType) {
        case "command":
            return commandField.text.trim();
        case "app":
            return appId;
        default:
            return scriptPath.trim();
        }
    }
    readonly property bool inputValid: nameField.text.trim().length > 0 && target.length > 0
    readonly property string home: Quickshell.env("HOME")
    readonly property string shownScriptPath: scriptPath.startsWith(home + "/") ? "~" + scriptPath.slice(home.length) : scriptPath
    readonly property string shellName: {
        let shell = Quickshell.env("SHELL") || "/bin/sh";
        return shell.slice(shell.lastIndexOf("/") + 1);
    }
    // The apps matching the search, those whose name starts with it first.
    // Empty unless an app is being chosen, so that their rows only exist
    // then.
    readonly property var matchingApps: {
        if (!actionEditor.visible || actionEditor.actionType !== "app") {
            return [];
        }
        let query = appSearchField.text.trim().toLowerCase();
        if (query === "") {
            return CustomActions.apps;
        }
        let matches = entry => [entry.name, entry.genericName, entry.categories.join(" "), entry.keywords.join(" ")].join(" ").toLowerCase().includes(query);
        let startsWith = entry => entry.name.toLowerCase().startsWith(query);
        return CustomActions.apps.filter(matches).sort((lhs, rhs) => (startsWith(rhs) - startsWith(lhs)) || lhs.name.localeCompare(rhs.name));
    }

    function ask(index) {
        let action = index >= 0 ? CustomActions.actions[index] : null;
        let text = key => typeof action?.[key] === "string" ? action[key] : "";
        actionEditor.actionIndex = action ? index : -1;
        nameField.text = text("name");
        actionEditor.actionType = CustomActions.typeOf(action);
        actionEditor.scriptPath = text("script");
        commandField.text = text("command");
        actionEditor.appId = text("app");
        let options = CustomActions.options(action);
        actionEditor.saveOutput = options.saveOutput;
        actionEditor.inTerminal = options.terminal;
        actionEditor.keepOpen = options.keepOpen;
        actionEditor.notifyResult = options.notify;
        appSearchField.text = "";
        actionEditor.message = "";
        actionEditor.showEditor();
    }

    function showEditor() {
        Dropdowns.current = actionEditor;
        actionEditor.visible = true;
        nameField.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function hideEditor() {
        actionEditor.visible = false;
        if (Dropdowns.current === actionEditor) {
            Dropdowns.current = null;
        }
    }

    function setType(type) {
        actionEditor.actionType = type;
        actionEditor.message = "";
    }

    // Also names a new action after the app.
    function chooseApp(entry) {
        actionEditor.appId = entry.id;
        if (nameField.text.trim() === "") {
            nameField.text = entry.name;
        }
    }

    // The terminal shows the output instead of the log files.
    function setInTerminal(inTerminal) {
        actionEditor.inTerminal = inTerminal;
        if (inTerminal) {
            actionEditor.saveOutput = false;
        }
    }

    // Starts in the current script's folder, if there is one.
    function pickScript() {
        if (actionEditor.picking) {
            return;
        }
        let path = actionEditor.scriptPath;
        let directory = path.includes("/") ? path.slice(0, path.lastIndexOf("/")) : "";
        actionEditor.picking = Daemon.call("file.pick", {
            title: "Choose a script",
            directory: directory
        }, (result, error) => {
            actionEditor.picking = false;
            if (error !== undefined) {
                console.warn("CustomActionEditor: file.pick failed:", error);
                actionEditor.message = `Couldn't open the file chooser: ${error}`;
            } else if (result && result.path) {
                actionEditor.scriptPath = result.path;
                actionEditor.message = "";
            }
            actionEditor.showEditor();
        });
        // Without the daemon, the callback has already shown why.
        if (actionEditor.picking) {
            actionEditor.hideEditor();
        }
    }

    function save() {
        if (!actionEditor.inputValid) {
            return;
        }
        let fields = {
            name: nameField.text.trim(),
            type: actionEditor.actionType
        };
        fields[actionEditor.actionType] = actionEditor.target;
        if (actionEditor.actionType !== "app") {
            Object.assign(fields, {
                saveOutput: actionEditor.saveOutput && !actionEditor.inTerminal,
                terminal: actionEditor.inTerminal,
                keepOpen: actionEditor.inTerminal && actionEditor.keepOpen,
                notify: actionEditor.notifyResult
            });
        }
        CustomActions.save(actionEditor.actionIndex, fields);
        actionEditor.hideEditor();
    }

    function remove() {
        if (!actionEditor.isNew) {
            CustomActions.remove(actionEditor.actionIndex);
        }
        actionEditor.hideEditor();
    }

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (Dropdowns.current !== actionEditor && actionEditor.visible) {
                actionEditor.hideEditor();
            }
        }
    }

    screen: AppConstants.primaryScreen
    visible: false
    // Exclusive rather than on-demand: see ProgramPicker.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: AppConstants.solidBgColor

    implicitWidth: 480
    // Rounded up: windows have whole-pixel sizes.
    implicitHeight: Math.max(1, Math.ceil(editorLayout.implicitHeight))

    ColumnLayout {
        id: editorLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        DropdownMenuHeader {
            text: actionEditor.isNew ? "New action" : "Edit action"
        }

        DropdownMenuItem {
            implicitHeight: 42
            showSeparator: false

            TextField {
                id: nameField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 18
                font.family: AppConstants.defaultFont
                placeholderText: "Name"
                onAccepted: actionEditor.save()
                Keys.onEscapePressed: actionEditor.hideEditor()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            TabMenuItem {
                iconName: CustomActions.typeIconName("script")
                text: "Script"
                selected: actionEditor.actionType === "script"
                action: () => actionEditor.setType("script")
            }

            TabMenuItem {
                iconName: CustomActions.typeIconName("command")
                text: "Command"
                selected: actionEditor.actionType === "command"
                action: () => actionEditor.setType("command")
            }

            TabMenuItem {
                iconName: CustomActions.typeIconName("app")
                text: "App"
                selected: actionEditor.actionType === "app"
                action: () => actionEditor.setType("app")
            }
        }

        // Script: opens the file chooser.
        DropdownMenuItem {
            visible: actionEditor.actionType === "script"
            implicitHeight: 42
            showSeparator: false
            action: () => actionEditor.pickScript()

            RecoloredIcon {
                id: scriptIcon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                iconWidth: 18
                iconHeight: 18
                source: Qt.resolvedUrl("assets/icons/fontawesome/solid/folder-open.svg")
                iconColor: AppConstants.iconColor
            }

            StyledText {
                anchors.centerIn: undefined
                anchors.left: scriptIcon.right
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 16
                textFormat: Text.PlainText
                elide: Text.ElideMiddle
                color: actionEditor.scriptPath !== "" ? AppConstants.styledTextColor : AppConstants.mutedIconColor
                text: actionEditor.scriptPath !== "" ? actionEditor.shownScriptPath : "Choose a script…"
            }
        }

        DropdownMenuItem {
            visible: actionEditor.actionType === "command"
            implicitHeight: 42
            showSeparator: false

            TextField {
                id: commandField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 16
                font.family: AppConstants.defaultFont
                placeholderText: "Shell command"
                onAccepted: actionEditor.save()
                Keys.onEscapePressed: actionEditor.hideEditor()
            }
        }

        DropdownMenuItem {
            visible: actionEditor.actionType !== "app"
            showSeparator: false

            StyledText {
                font.pixelSize: 14
                color: actionEditor.message !== "" ? AppConstants.dangerColor : AppConstants.mutedIconColor
                text: {
                    if (actionEditor.message !== "") {
                        return actionEditor.message;
                    }
                    return actionEditor.actionType === "command" ? `Runs with ${actionEditor.shellName} -c, from your home folder` : "An executable file (with a shebang line)";
                }
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width - 20)
            }
        }

        // App: the chosen one, then the search and the matching apps.
        DropdownMenuItem {
            visible: actionEditor.actionType === "app"
            showSeparator: false

            AppIcon {
                id: chosenAppIcon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                size: 24
                iconName: actionEditor.appEntry?.icon ?? ""
                fallbackIconName: CustomActions.typeIconName("app")
                fallbackColor: actionEditor.appEntry ? AppConstants.iconColor : AppConstants.mutedIconColor
            }

            StyledText {
                anchors.centerIn: undefined
                anchors.left: chosenAppIcon.right
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 16
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: {
                    if (actionEditor.appEntry) {
                        return AppConstants.styledTextColor;
                    }
                    return actionEditor.appId !== "" ? AppConstants.dangerColor : AppConstants.mutedIconColor;
                }
                text: {
                    if (actionEditor.appEntry) {
                        return actionEditor.appEntry.name;
                    }
                    return actionEditor.appId !== "" ? `${actionEditor.appId} isn't installed` : "Choose an app below";
                }
            }
        }

        DropdownMenuItem {
            visible: actionEditor.actionType === "app"
            implicitHeight: 42
            showSeparator: false

            TextField {
                id: appSearchField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 16
                font.family: AppConstants.defaultFont
                placeholderText: "Search apps"
                onAccepted: {
                    if (actionEditor.matchingApps.length > 0) {
                        actionEditor.chooseApp(actionEditor.matchingApps[0]);
                    }
                }
                Keys.onEscapePressed: actionEditor.hideEditor()
            }
        }

        ScrollingMenuList {
            rowCount: actionEditor.matchingApps.length
            maxVisibleRows: 5

            Repeater {
                model: actionEditor.matchingApps
                delegate: DropdownMenuItem {
                    id: appChoice
                    required property var modelData
                    readonly property bool chosen: modelData.id === actionEditor.appId

                    radius: 4
                    border.width: chosen ? 2 : 0
                    border.color: AppConstants.indicatorOnColor
                    action: () => actionEditor.chooseApp(appChoice.modelData)

                    AppIcon {
                        id: appChoiceIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        size: 22
                        iconName: appChoice.modelData.icon ?? ""
                        fallbackIconName: CustomActions.typeIconName("app")
                    }

                    StyledText {
                        anchors.centerIn: undefined
                        anchors.left: appChoiceIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: 16
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        text: appChoice.modelData.name
                    }
                }
            }
        }

        DropdownMenuItem {
            visible: actionEditor.actionType === "app" && actionEditor.matchingApps.length === 0

            StyledText {
                font.pixelSize: 15
                color: AppConstants.mutedIconColor
                text: "No matching apps"
            }
        }

        // Script and command options, two per row.
        GridLayout {
            visible: actionEditor.actionType !== "app"
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 0
            rowSpacing: 0

            ToggleMenuItem {
                text: "Save output"
                checked: actionEditor.saveOutput && !actionEditor.inTerminal
                available: !actionEditor.inTerminal
                toggle: () => {
                    actionEditor.saveOutput = !actionEditor.saveOutput;
                }
            }

            ToggleMenuItem {
                text: "Open in terminal"
                checked: actionEditor.inTerminal
                toggle: () => actionEditor.setInTerminal(!actionEditor.inTerminal)
            }

            ToggleMenuItem {
                text: "Keep terminal open"
                checked: actionEditor.inTerminal && actionEditor.keepOpen
                available: actionEditor.inTerminal
                toggle: () => {
                    actionEditor.keepOpen = !actionEditor.keepOpen;
                }
            }

            ToggleMenuItem {
                text: "Notify when done"
                checked: actionEditor.notifyResult
                toggle: () => {
                    actionEditor.notifyResult = !actionEditor.notifyResult;
                }
            }
        }

        Separator {
            vertical: false
            thickness: 1
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            DropdownMenuItem {
                opacity: actionEditor.inputValid ? 1 : 0.4
                action: () => actionEditor.save()
                StyledText {
                    font.pixelSize: 18
                    text: "Save"
                }
            }

            Separator {
                visible: !actionEditor.isNew
                thickness: 1
            }

            DropdownMenuItem {
                visible: !actionEditor.isNew
                action: () => actionEditor.remove()
                StyledText {
                    font.pixelSize: 18
                    color: AppConstants.dangerColor
                    text: "Delete"
                }
            }

            Separator {
                thickness: 1
            }

            DropdownMenuItem {
                action: () => actionEditor.hideEditor()
                StyledText {
                    font.pixelSize: 18
                    text: "Cancel"
                }
            }
        }
    }
}
