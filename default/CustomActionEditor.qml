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
// The script is chosen in the desktop's file chooser (the daemon's
// `file.pick`). The editor hides while that dialog is open: it would cover
// the dialog, and its exclusive keyboard focus would keep typing from
// reaching it.
PanelWindow {
    id: actionEditor

    // Index in CustomActions.actions, or -1 for a new action.
    property int actionIndex: -1
    property string scriptPath: ""
    // Whether the daemon notifies with the result when the script ends.
    property bool notifyResult: false
    // A file.pick call is pending.
    property bool picking: false
    property string message: ""
    readonly property bool isNew: actionIndex < 0
    readonly property bool inputValid: nameField.text.trim().length > 0 && scriptPath.trim().length > 0
    readonly property string home: Quickshell.env("HOME")
    readonly property string shownScriptPath: scriptPath.startsWith(home + "/") ? "~" + scriptPath.slice(home.length) : scriptPath

    function ask(index) {
        let action = index >= 0 ? CustomActions.actions[index] : null;
        actionEditor.actionIndex = action ? index : -1;
        nameField.text = action && typeof action.name === "string" ? action.name : "";
        actionEditor.scriptPath = action && typeof action.script === "string" ? action.script : "";
        actionEditor.notifyResult = action ? action.notify === true : false;
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
        CustomActions.save(actionEditor.actionIndex, nameField.text.trim(), actionEditor.scriptPath.trim(), actionEditor.notifyResult);
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

    implicitWidth: 450
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

        // Opens the file chooser.
        DropdownMenuItem {
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
            showSeparator: false

            StyledText {
                font.pixelSize: 14
                color: actionEditor.message !== "" ? AppConstants.dangerColor : AppConstants.mutedIconColor
                text: actionEditor.message !== "" ? actionEditor.message : "An executable file (with a shebang line)"
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width - 20)
            }
        }

        // Tap-to-toggle, like the theme switch in PowerIndicator: shows the
        // current choice, and a tap flips it.
        IconMenuItem {
            iconNames: [actionEditor.notifyResult ? "bell" : "bell-slash"]
            text: actionEditor.notifyResult ? "notify with the result" : "no result notification"
            textPixelSize: 15
            action: () => {
                actionEditor.notifyResult = !actionEditor.notifyResult;
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
