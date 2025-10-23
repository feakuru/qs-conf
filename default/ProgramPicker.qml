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
            model: {
                let model = DesktopEntries.applications.values;
                if (searchField.text.length > 0) {
                    return model.filter(val => val.name.toLowerCase().includes(searchField.text));
                }
                return model.slice(0, 100);
            }
            delegate: DropdownMenuItem {
                action: () => {
                    programPicker.toggleMenuVisibility();
                    modelData.execute();
                }
                StyledText {
                    font.pixelSize: 16
                    text: modelData.name
                }
            }
        },
        DropdownMenuItem {
            Layout.columnSpan: 4
            Keys.onEscapePressed: {
                programPicker.toggleMenuVisibility();
            }
            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 18
                font.family: "FiraCode Nerd Font"
                placeholderText: "hello"
            }
        }
    ]
}
