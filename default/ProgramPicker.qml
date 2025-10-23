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
        } else if (currentCategory.length > 0) {
            model = model.filter(entry => entry.categories.includes(currentCategory)).sort((lhs, rhs) => lhs.name.localeCompare(rhs.name)).slice(0, 100)
        } else {
            let categories = new Set();
            for (let entryCategories of model.map(entry => entry.categories)) {
                for (let category of entryCategories) {
                    categories.add(category);
                }
            }
            model = [...categories].sort();
        }
        return model
    }

    IpcHandler {
        target: "programPicker"

        function toggle(): void {
            searchField.text = "";
            programPicker.currentCategory = "";
            programPicker.toggleMenuVisibility();
            searchField.forceActiveFocus(Qt.ShortcutFocusReason);
        }
    }

    menuContent: [
        DropdownMenuItem {
            Layout.margins: 1
            border.width: 2
            action: () => {
                programPicker.currentCategory = "";
            }
            visible: programPicker.currentCategory.length > 0

            StyledText {
                font.pixelSize: 16
                text: "< back"
            }
        },
        Repeater {
            model: programPicker.displayedEntries
            delegate: DropdownMenuItem {
                Layout.margins: 1
                border.width: 1
                action: () => {
                    if (typeof modelData == "string") {
                        programPicker.currentCategory = modelData;
                    } else {
                        programPicker.toggleMenuVisibility();
                        modelData.execute();
                    }
                }
                StyledText {
                    font.pixelSize: 16
                    text: {
                        let name = typeof modelData == "string" ? `> ${modelData}` : modelData.name
                        name.slice(0, 24) + (name.length > 24 ? "..." : "")
                    }
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
                placeholderText: "Search programs or choose category"
                onAccepted: {
                    if (text.length > 0 && programPicker.displayedEntries.length > 0) {
                        programPicker.displayedEntries[programPicker.displayedEntries.length - 1].execute();
                        programPicker.toggleMenuVisibility();
                        searchField.text = "";
                    }
                }
            }
        }
    ]
}
