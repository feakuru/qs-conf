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

    property list<var> desktopEntries: []
    property list<string> categories: []
    property string currentCategory: ""

    IpcHandler {
        target: "programPicker"

        function toggle(): void {
            searchField.text = "";
            programPicker.toggleMenuVisibility();
            searchField.forceActiveFocus(Qt.ShortcutFocusReason);
        }
    }

    Process {
        id: findAppsProcess
        running: true
        command: ["bash", "-c", `find "\${XDG_DATA_HOME:-$HOME/.local/share}/applications" \
            $(printf '%s' "\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" \
            | awk -v RS=':' '{sub(/\\/$/, "", $0); print $0 "/applications"}') \
            -type f -name '*.desktop' -exec sh -c 'echo "====="; echo "$1"; cat "$1"; echo' sh {} \\; 2>/dev/null`]

        stdout: StdioCollector {
            onStreamFinished: {
                let newEntries = [];
                let newCategories = new Set();
                for (let fileContent of this.text.split("=====")) {
                    let fileLines = fileContent.trim().split("\n");
                    let fileName = fileLines.shift();
                    if (fileName.trim().length <= 0) {
                        continue;
                    }
                    let entryObj = {
                        filename: fileName
                    };
                    for (let line of fileLines) {
                        if (line.includes("=")) {
                            let sepIndex = line.indexOf("=");
                            let key = line.slice(0, sepIndex).trim();
                            let value = line.slice(sepIndex + 1).trim();
                            if (key == "Categories") {
                                value = value.split(';').map(val => {
                                    val = val.trim();
                                    if (val.startsWith('X-')) {
                                        val = val.split('-').pop();
                                    }
                                    if (val.length > 0) {
                                        newCategories.add(val);
                                    }
                                    return val;
                                }).filter(val => val.length > 0);
                            }
                            entryObj[key] = value;
                        }
                    }
                    if ("Name" in entryObj && "Exec" in entryObj) {
                        newEntries.push(entryObj);
                    }
                }
                programPicker.categories = [...newCategories].sort();
                programPicker.desktopEntries = newEntries;
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: function () {
            findAppsProcess.running = true;
        }
    }

    menuContent: [
        Repeater {
            model: {
                if (searchField.text.length > 0) {
                    return programPicker.desktopEntries.filter(entry => {
                        return entry["Name"].toLowerCase().includes(searchField.text.toLowerCase())
                    });
                }
                if (programPicker.currentCategory.length > 0) {
                    return programPicker.desktopEntries.filter(entry => {
                        if ("Categories" in entry) {
                            return entry["Categories"].includes(programPicker.currentCategory);
                        }
                        return false;
                    });
                }
                return programPicker.categories;
            }
            delegate: DropdownMenuItem {
                action: () => {
                    if (typeof modelData == "string") {
                        programPicker.currentCategory = modelData;
                    } else {
                        console.log(modelData["Exec"]);
                    }
                }
                StyledText {
                    font.pixelSize: 16
                    text: {(typeof modelData != "string") ? modelData["Name"] : `> ${modelData}`}
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
