import QtQuick
import QtQuick.Layouts
import Quickshell

DropdownMenu {
    id: ramMenu
    // The daemon's `ram.details` topic, sampled while the menu is open:
    // {memory, swap, processes}.
    readonly property var ramDetails: Daemon.connected ? ramDetailsTopic.latest : null
    readonly property string memoryText: ramDetails ? ramDetails.memory : ""
    readonly property string swapText: ramDetails ? ramDetails.swap : ""
    readonly property var topProcesses: ramDetails ? ramDetails.processes : []
    readonly property int topProcessCount: 5
    // The daemon's `ram.modules` topic: {slots_total, modules}, read once.
    // Kept while disconnected: the modules don't change.
    readonly property var memoryModuleInfo: ramModulesTopic.latest
    readonly property var memoryModules: memoryModuleInfo ? memoryModuleInfo.modules : []
    readonly property int memorySlotsTotal: memoryModuleInfo ? memoryModuleInfo.slots_total || 0 : 0
    readonly property bool memoryModulesLoaded: memoryModuleInfo !== null
    // The daemon's `ram` topic: {percent}; null while it's unreachable.
    readonly property var ramUsage: Daemon.connected ? ramTopic.latest : null

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/memory.svg")

    toggleTextFont.pixelSize: 18
    toggleTextWidest: "100%"
    toggleText: ramMenu.ramUsage ? `${ramIndicator.percentValue}%` : "…"

    Rectangle {
        id: ramIndicator
        z: -1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: AppConstants.loadBarInset
        anchors.right: parent.right
        anchors.rightMargin: AppConstants.loadBarInset
        color: AppConstants.memoryBarColor
        readonly property int percentValue: ramMenu.ramUsage ? ramMenu.ramUsage.percent : 0
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

    DaemonTopic {
        id: ramDetailsTopic
        topic: "ram.details"
        active: ramMenu.menuVisible
    }

    DaemonTopic {
        id: ramModulesTopic
        topic: "ram.modules"
    }

    DaemonTopic {
        id: ramTopic
        topic: "ram"
    }
}
