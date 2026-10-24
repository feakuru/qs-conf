import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Application launcher. Unlike the dropdown menus it uses its own layer-shell
// window, because typing into the search field needs keyboard focus, which
// popups can't reliably get. It closes on Escape, when the button is clicked
// again, after launching a program, or when a dropdown is opened.
BarButton {
    id: programPicker
    toggleIconColor: "darkgray"
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/book.svg")
    toggleTextFont.pixelSize: 16

    readonly property int columns: 4
    readonly property alias launcherVisible: launcherWindow.visible
    property int focusedIdx: 0
    property string currentCategory: ""
    property list<var> displayedEntries: {
        let model = [...new Map(DesktopEntries.applications.values.map(entry => [entry.name, entry])).values()];
        if (searchField.text.length > 1) {
            model = model.filter(val => val.name.toLowerCase().includes(searchField.text.toLowerCase()) || val.categories.join(" ").toLowerCase().includes(searchField.text.toLowerCase()) || val.keywords.join(" ").toLowerCase().includes(searchField.text.toLowerCase())).sort((lhs, rhs) => {
                let lhsStartsWith = lhs.name.toLowerCase().startsWith(searchField.text.toLowerCase());
                let rhsStartsWith = rhs.name.toLowerCase().startsWith(searchField.text.toLowerCase());
                if (lhsStartsWith && !rhsStartsWith)
                    return -1;
                if (!lhsStartsWith && rhsStartsWith)
                    return 1;
                return lhs.name.length - rhs.name.length;
            });
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

    function openLauncher() {
        searchField.text = "";
        programPicker.currentCategory = "";
        programPicker.focusedIdx = 0;
        Dropdowns.current = programPicker;
        launcherWindow.visible = true;
        searchField.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function closeLauncher() {
        launcherWindow.visible = false;
        if (Dropdowns.current === programPicker) {
            Dropdowns.current = null;
        }
    }

    function toggleLauncher() {
        if (launcherWindow.visible) {
            programPicker.closeLauncher();
        } else {
            programPicker.openLauncher();
        }
    }

    // Categories are opened; programs are launched and close the launcher.
    function activate(entry) {
        if (typeof entry == "string") {
            programPicker.currentCategory = entry;
            return;
        }
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["xdg-terminal-exec", entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
        programPicker.closeLauncher();
    }

    function scrollEntryIntoView(item) {
        if (!item) {
            return;
        }
        if (item.y < entriesFlickable.contentY) {
            entriesFlickable.contentY = item.y;
        } else if (item.y + item.height > entriesFlickable.contentY + entriesFlickable.height) {
            entriesFlickable.contentY = item.y + item.height - entriesFlickable.height;
        }
    }

    onClicked: toggleLauncher()
    onDisplayedEntriesChanged: entriesFlickable.contentY = 0
    onFocusedIdxChanged: Qt.callLater(() => programPicker.scrollEntryIntoView(entriesRepeater.itemAt(programPicker.focusedIdx)))

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (Dropdowns.current !== programPicker && launcherWindow.visible) {
                programPicker.closeLauncher();
            }
        }
    }

    IpcHandler {
        target: "programPicker"

        function toggle(): void {
            programPicker.toggleLauncher();
        }
    }

    PanelWindow {
        id: launcherWindow
        screen: AppConstants.primaryScreen
        visible: false
        focusable: true
        color: AppConstants.solidBgColor

        anchors {
            bottom: true
            left: true
        }

        // The height of the first view (the category list) is kept while
        // searching or browsing, so the launcher doesn't jump around.
        property real lockedHeight: 0
        // Rounded up: windows have whole-pixel sizes, and rounding down would
        // make the entries overflow by a fraction and show the scrollbar.
        readonly property real naturalHeight: Math.min(Math.ceil(launcherLayout.implicitHeight), (screen ? screen.height : 1080) * 0.8)

        implicitWidth: 1200
        implicitHeight: lockedHeight > 0 ? lockedHeight : Math.max(1, naturalHeight)

        onVisibleChanged: {
            if (visible && lockedHeight === 0) {
                Qt.callLater(() => {
                    if (entriesGrid.implicitHeight > 0) {
                        launcherWindow.lockedHeight = launcherWindow.naturalHeight;
                    }
                });
            }
        }

        ColumnLayout {
            id: launcherLayout
            anchors.fill: parent
            spacing: 0

            Flickable {
                id: entriesFlickable
                implicitHeight: entriesGrid.implicitHeight
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: entriesGrid.implicitHeight

                ScrollBar.vertical: ScrollBar {
                    id: entriesScrollBar
                    policy: entriesFlickable.contentHeight > entriesFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                GridLayout {
                    id: entriesGrid
                    width: entriesFlickable.width - (entriesScrollBar.policy === ScrollBar.AlwaysOn ? entriesScrollBar.width : 0)
                    columns: programPicker.columns
                    columnSpacing: 0
                    rowSpacing: 0

                    DropdownMenuItem {
                        Layout.margins: 1
                        showSeparator: false
                        border.width: 2
                        border.color: AppConstants.indicatorBorderColor
                        visible: programPicker.currentCategory.length > 0
                        action: () => {
                            programPicker.currentCategory = "";
                        }

                        StyledText {
                            font.pixelSize: 16
                            text: "< back"
                        }
                    }

                    Repeater {
                        id: entriesRepeater
                        model: programPicker.displayedEntries
                        delegate: DropdownMenuItem {
                            readonly property bool isFocused: index == programPicker.focusedIdx
                            Layout.margins: 1
                            showSeparator: false
                            radius: 4
                            border.width: isFocused ? 3 : 0
                            border.color: AppConstants.indicatorOnColor
                            action: () => programPicker.activate(modelData)

                            RowLayout {
                                anchors.fill: parent

                                Item {
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 48
                                    visible: Boolean(modelData.icon) && modelData.icon.length > 0 && (programIcon.status == Image.Ready)

                                    IconImage {
                                        id: programIcon
                                        width: 32
                                        height: 32
                                        anchors.centerIn: parent
                                        source: Quickshell.iconPath(modelData.icon, true)
                                    }
                                }

                                Item {
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
                    }
                }
            }

            Separator {
                vertical: false
                thickness: 1
                Layout.fillWidth: true
            }

            DropdownMenuItem {
                id: searchItem
                implicitHeight: 42
                showSeparator: false
                Keys.onEscapePressed: {
                    programPicker.closeLauncher();
                }

                TextField {
                    id: searchField
                    anchors.fill: parent
                    anchors.margins: 5
                    font.pixelSize: 18
                    font.family: AppConstants.defaultFont
                    placeholderText: "Search programs or choose category"
                    onTextChanged: {
                        programPicker.focusedIdx = 0;
                    }
                    onAccepted: {
                        if (programPicker.focusedIdx >= 0 && programPicker.focusedIdx < programPicker.displayedEntries.length) {
                            programPicker.activate(programPicker.displayedEntries[programPicker.focusedIdx]);
                        }
                    }
                    Keys.onUpPressed: event => {
                        if (programPicker.focusedIdx < 0) {
                            let deltaToLeftInLastRow = programPicker.displayedEntries.length % programPicker.columns || programPicker.columns;
                            programPicker.focusedIdx = Math.max(programPicker.displayedEntries.length - deltaToLeftInLastRow, 0);
                        } else {
                            programPicker.focusedIdx = Math.max(programPicker.focusedIdx - programPicker.columns, 0);
                        }
                        event.accepted = true;
                    }
                    Keys.onDownPressed: event => {
                        if (programPicker.focusedIdx < 0) {
                            programPicker.focusedIdx = programPicker.columns - 1;
                        } else {
                            programPicker.focusedIdx = Math.min(programPicker.focusedIdx + programPicker.columns, programPicker.displayedEntries.length - 1);
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
        }
    }
}
