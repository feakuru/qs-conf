import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

DropdownMenu {
    id: programPicker
    toggleIconColor: "darkgray"
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/book.svg")
    toggleTextFont.pixelSize: 16
    menuWidth: 1200
    menuAnchors.bottom: true
    menuColumns: 4
    disableDisappearanceOnNoFocus: true

    property int focusedIdx: -1
    property string currentCategory: ""
    property list<var> displayedEntries: {
        let model = new Array(...DesktopEntries.applications.values);
        if (searchField.text.length > 0) {
            model = model.filter(val => val.name.toLowerCase().includes(searchField.text));
        } else if (currentCategory.length > 0) {
            model = model.filter(entry => entry.categories.includes(currentCategory)).sort((lhs, rhs) => lhs.name.localeCompare(rhs.name)).slice(0, 100);
        } else {
            let categories = new Set();
            for (let entryCategories of model.map(entry => entry.categories)) {
                for (let category of entryCategories) {
                    categories.add(category);
                }
            }
            model = [...categories].sort().concat(model.filter(entry => entry.categories.length <= 0));
        }
        return model;
    }

    IpcHandler {
        target: "programPicker"

        function toggle(): void {
            searchField.text = "";
            programPicker.currentCategory = "";
            programPicker.focusedIdx = -1;
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
                id: programMenuItem
                Layout.margins: 1
                border.width: {
                    index == programPicker.focusedIdx ? 3 : 1;
                }
                border.color: {
                    index == programPicker.focusedIdx ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor;
                }
                action: () => {
                    if (typeof modelData == "string") {
                        programPicker.currentCategory = modelData;
                    } else {
                        programPicker.toggleMenuVisibility();
                        if (modelData.runInTerminal) {
                            Quickshell.execDetached({
                                command: ["xdg-terminal-exec", modelData.command],
                                workingDirectory: modelData.workingDirectory
                            });
                        } else {
                            modelData.execute();
                        }
                    }
                }
                RowLayout {
                    anchors.fill: parent
                    Rectangle {
                        color: "transparent"
                        Layout.fillHeight: true
                        Layout.preferredWidth: 48
                        visible: {
                            Boolean(modelData.icon) && modelData.icon.length > 0 && (programIcon.status == Image.Ready);
                        }
                        IconImage {
                            id: programIcon
                            width: 32
                            height: 32
                            anchors.centerIn: parent
                            source: Quickshell.iconPath(modelData.icon, true)
                        }
                    }
                    Rectangle {
                        color: "transparent"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        StyledText {
                            font.pixelSize: 16
                            text: {
                                let name = typeof modelData == "string" ? `> ${modelData}` : modelData.name;
                                name.slice(0, 22) + (name.length > 22 ? "…" : "");
                            }
                        }
                    }
                }
            }
        },
        DropdownMenuItem {
            Layout.columnSpan: 4
            Keys.onEscapePressed: {
                programPicker.toggleMenuVisibility();
                searchField.text = "";
                programPicker.focusedIdx = -1;
            }
            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 18
                font.family: "FiraCode Nerd Font"
                placeholderText: "Search programs or choose category"
                onTextChanged: {
                    programPicker.focusedIdx = -1;
                }
                onAccepted: {
                    if (programPicker.focusedIdx >= 0 && programPicker.focusedIdx < programPicker.displayedEntries.length) {
                        let entry = programPicker.displayedEntries[programPicker.focusedIdx];
                        if (typeof entry == "string") {
                            programPicker.currentCategory = entry;
                        } else {
                            if (entry.runInTerminal) {
                                Quickshell.execDetached({
                                    command: ["xdg-terminal-exec", entry.command],
                                    workingDirectory: entry.workingDirectory
                                });
                            } else {
                                entry.execute();
                            }
                            programPicker.toggleMenuVisibility();
                            searchField.text = "";
                        }
                    }
                }
                Keys.onUpPressed: event => {
                    if (programPicker.focusedIdx < 0) {
                        let deltaToLeftInLastRow = programPicker.displayedEntries.length % 4;
                        programPicker.focusedIdx = Math.max(programPicker.displayedEntries.length - deltaToLeftInLastRow, 0);
                    } else {
                        programPicker.focusedIdx = Math.max(programPicker.focusedIdx - 4, 0);
                    }
                    event.accepted = true;
                }
                Keys.onDownPressed: event => {
                    if (programPicker.focusedIdx < 0) {
                        programPicker.focusedIdx = 3;
                    } else {
                        programPicker.focusedIdx = Math.min(programPicker.focusedIdx + 4, programPicker.displayedEntries.length - 1);
                    }
                    event.accepted = true;
                }
                Keys.onLeftPressed: event => {
                    if (programPicker.focusedIdx < 0) {
                        programPicker.focusedIdx = programPicker.displayedEntries.length - 1;
                    } else {
                        programPicker.focusedIdx = Math.max(programPicker.focusedIdx - 1, 0);
                    }
                    event.accepted = true;
                }
                Keys.onRightPressed: event => {
                    if (programPicker.focusedIdx < 0) {
                        programPicker.focusedIdx = 0;
                    } else {
                        programPicker.focusedIdx = Math.min(programPicker.focusedIdx + 1, programPicker.displayedEntries.length - 1);
                    }
                    event.accepted = true;
                }
            }
        }
    ]
}
