import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: programPicker
    toggleIconColor: "darkgray"
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/book.svg")
    toggleTextFont.pixelSize: 16
    menuWidth: 1200
    menuAnchors.bottom: true
    menuColumns: 4
    disableDisappearanceOnNoFocus: true

    property string currentCategory: ""
    property list<var> displayedEntries: {
        let model = new Array(...DesktopEntries.applications.values);
        if (searchField.text.length > 0) {
            model = model.filter(val => val.name.toLowerCase().includes(searchField.text));
        }
        model = model.slice(0, 100).sort((lhs, rhs) => lhs.name.localeCompare(rhs.name));
        return model
    }

    IpcHandler {
        target: "programPicker"

        function toggle(): void {
            searchField.text = "";
            programPicker.toggleMenuVisibility();
            searchField.forceActiveFocus(Qt.ShortcutFocusReason);
        }
    }

    menuContent: [
        Repeater {
            model: programPicker.displayedEntries
            delegate: DropdownMenuItem {
                action: () => {
                    programPicker.toggleMenuVisibility();
                    modelData.execute();
                }
                StyledText {
                    font.pixelSize: 16
                    text: modelData.name.slice(0, 24) + (modelData.name.length > 24 ? "..." : "")
                }
            }
        },
        DropdownMenuItem {
            Layout.columnSpan: 4
            Keys.onEscapePressed: {
                programPicker.toggleMenuVisibility();
                searchField.text = "";
            }
            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 18
                font.family: "FiraCode Nerd Font"
                placeholderText: "hello"
                onAccepted: {
                    if (programPicker.displayedEntries.length > 0) {
                        programPicker.displayedEntries[programPicker.displayedEntries.length - 1].execute();
                        programPicker.toggleMenuVisibility();
                        searchField.text = "";
                    }
                }
            }
        }
    ]
}
