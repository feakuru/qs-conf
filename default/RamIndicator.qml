import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: ramMenu
    property string memoryText: ""
    property string swapText: ""
    property var topProcesses: []
    readonly property int topProcessCount: 5
    property var memoryModules: []
    property int memorySlotsTotal: 0
    property bool memoryModulesLoaded: false

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/memory.svg")

    toggleTextFont.pixelSize: 18
    toggleTextWidest: "100%"
    toggleText: `${ramIndicator.percentValue}%`

    Rectangle {
        id: ramIndicator
        z: -1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: AppConstants.loadBarInset
        anchors.right: parent.right
        anchors.rightMargin: AppConstants.loadBarInset
        color: AppConstants.memoryBarColor
        property var percentValue: 0
        height: (percentValue / 100) * parent.height
    }

    menuWidth: 450
    opensUpward: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                font.pixelSize: 18
                text: {
                    if (ramMenu.memoryText === "") {
                        return "…";
                    }
                    let result = `RAM ${ramMenu.memoryText}`;
                    if (ramMenu.swapText !== "") {
                        result += ` · swap ${ramMenu.swapText}`;
                    }
                    return result;
                }
            }
        },
        DropdownMenuHeader {
            text: "Top processes"
        },
        Repeater {
            // A fixed number of rows that only have their values swapped, so
            // hovering and the menu size stay stable between samples.
            model: ramMenu.topProcessCount
            delegate: UsageMenuItem {
                readonly property var processInfo: ramMenu.topProcesses[index] || null
                barColor: AppConstants.memoryBarColor
                label: processInfo ? processInfo.name : "…"
                valueText: processInfo ? processInfo.value : ""
                percent: processInfo ? processInfo.percent : 0
            }
        },
        DropdownMenuHeader {
            text: ramMenu.memorySlotsTotal > 0 ? `Memory modules (${ramMenu.memoryModules.length}/${ramMenu.memorySlotsTotal} slots used)` : "Memory modules"
        },
        DropdownMenuItem {
            visible: ramMenu.memoryModules.length === 0
            StyledText {
                font.pixelSize: 16
                text: ramMenu.memoryModulesLoaded ? "Module info unavailable" : "…"
            }
        },
        Repeater {
            // Only set once at startup, so these are never recreated.
            model: ramMenu.memoryModules
            delegate: DropdownMenuItem {
                Layout.preferredHeight: moduleInfoColumn.implicitHeight + 16

                Column {
                    id: moduleInfoColumn
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        anchors.centerIn: undefined
                        width: parent.width
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        text: `${modelData.slot}: ${modelData.summary}`
                    }

                    StyledText {
                        anchors.centerIn: undefined
                        width: parent.width
                        visible: modelData.details !== ""
                        font.pixelSize: 14
                        color: AppConstants.mutedIconColor
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        text: modelData.details
                    }
                }
            }
        }
    ]

    ScriptProcess {
        id: ramDetailsProcess
        scriptName: "ram_details"
        running: ramMenu.menuVisible

        stdout: SplitParser {
            onRead: data => {
                let details;
                try {
                    details = JSON.parse(data);
                } catch (e) {
                    return;
                }
                ramMenu.memoryText = details.memory || "";
                ramMenu.swapText = details.swap || "";
                ramMenu.topProcesses = details.processes || [];
            }
        }
    }

    ScriptProcess {
        id: ramModulesProcess
        scriptName: "ram_modules"
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                ramMenu.memoryModulesLoaded = true;
                let info;
                try {
                    info = JSON.parse(this.text);
                } catch (e) {
                    return;
                }
                ramMenu.memorySlotsTotal = info.slots_total || 0;
                ramMenu.memoryModules = info.modules || [];
            }
        }
    }

    ScriptProcess {
        id: ramProcess
        scriptName: "ram_usage"
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                ramIndicator.percentValue = parseInt(this.text);
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: function () {
            ramProcess.running = true;
        }
    }
}
