import QtQuick
import Quickshell

// Runs the user's custom actions (see CustomActions). Each row shows its
// type's icon (an app's own icon, if it has one); clicking it runs its
// action, and its pen button, and the last row, open CustomActionEditor.
DropdownMenu {
    id: customActionsMenu

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/bolt.svg")
    opensUpward: true
    menuWidth: 350

    // `index` -1 adds a new action.
    function edit(index) {
        customActionsMenu.closeMenu();
        actionEditor.ask(index);
    }

    CustomActionEditor {
        id: actionEditor
    }

    menuContent: [
        DropdownMenuHeader {
            text: "Actions"
        },
        DropdownMenuItem {
            visible: CustomActions.actions.length === 0
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "No actions yet"
            }
        },
        // Scripts and commands are run by the daemon (script.run).
        DropdownMenuItem {
            visible: !Daemon.connected && CustomActions.actions.some(action => CustomActions.typeOf(action) !== "app")
            StyledText {
                font.pixelSize: 15
                color: AppConstants.dangerColor
                text: "Not connected to qs-conf-daemon"
            }
        },
        Repeater {
            model: CustomActions.actions
            delegate: DropdownMenuItem {
                id: actionItem
                required property var modelData
                required property int index
                readonly property string type: CustomActions.typeOf(modelData)
                readonly property var appEntry: type === "app" ? CustomActions.appEntry(modelData.app) : null
                // Apps are launched here; the rest needs the daemon.
                readonly property bool runnable: type === "app" ? appEntry !== null : Daemon.connected

                action: () => {
                    customActionsMenu.closeMenu();
                    CustomActions.run(actionItem.modelData);
                }

                // The app's own icon if it has one, else the type's.
                AppIcon {
                    id: typeIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    size: 22
                    opacity: actionItem.runnable ? 1 : 0.5
                    iconName: actionItem.appEntry?.icon ?? ""
                    fallbackIconName: CustomActions.typeIconName(actionItem.type)
                }

                StyledText {
                    anchors.centerIn: undefined
                    anchors.left: typeIcon.right
                    anchors.right: editButton.left
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 17
                    opacity: actionItem.runnable ? 1 : 0.5
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    text: {
                        let action = actionItem.modelData || {};
                        return action.name || action[actionItem.type] || "(unnamed)";
                    }
                }

                WindowActionButton {
                    id: editButton
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "pen"
                    action: () => customActionsMenu.edit(actionItem.index)
                }
            }
        },
        IconMenuItem {
            iconNames: ["plus"]
            text: "Add action"
            textPixelSize: 15
            action: () => customActionsMenu.edit(-1)
        }
    ]
}
