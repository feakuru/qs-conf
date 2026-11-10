import QtQuick
import Quickshell

// Runs the user's custom actions (see CustomActions). Clicking a row runs its
// action; its pen button, and the last row, open CustomActionEditor.
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
        // Actions are run by the daemon (script.run).
        DropdownMenuItem {
            visible: !Daemon.connected
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

                action: () => {
                    customActionsMenu.closeMenu();
                    CustomActions.run(actionItem.modelData);
                }

                StyledText {
                    anchors.centerIn: undefined
                    anchors.left: parent.left
                    anchors.right: editButton.left
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 17
                    opacity: Daemon.connected ? 1 : 0.5
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    text: {
                        let action = actionItem.modelData || {};
                        return action.name || action.script || "(unnamed)";
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
