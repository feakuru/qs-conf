import QtQuick
import Quickshell

DropdownMenu {
    id: gpuIndicator
    // The daemon's `gpu` topic: {name, load, memory_used, memory_total} (MiB);
    // null while it's unreachable.
    readonly property var gpuUsage: Daemon.connected ? gpuTopic.latest : null
    readonly property string gpuName: gpuUsage ? gpuUsage.name : ""
    readonly property int loadPercent: gpuUsage ? gpuUsage.load : 0
    readonly property int memoryUsed: gpuUsage ? gpuUsage.memory_used : 0
    readonly property int memoryTotal: gpuUsage ? gpuUsage.memory_total : 0
    // Integrated GPUs share system RAM and report no dedicated memory.
    property bool hasDedicatedMemory: memoryTotal > 0
    property int memoryPercent: hasDedicatedMemory ? Math.round(memoryUsed / memoryTotal * 100) : 0
    // The daemon's `gpu.details` topic, sampled while the menu is open:
    // {processes, error}.
    readonly property var gpuDetails: Daemon.connected ? gpuDetailsTopic.latest : null
    readonly property var topProcesses: gpuDetails ? gpuDetails.processes : []
    readonly property string processesError: gpuDetails ? gpuDetails.error : ""
    readonly property bool processesLoaded: gpuDetails !== null
    readonly property int topProcessCount: 5

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/display.svg")

    toggleTextFont.pixelSize: 18
    toggleText: gpuIndicator.gpuUsage ? `${gpuIndicator.loadPercent}%` : "…"

    toggleTextWidest: "100%"

    Item {
        anchors.fill: parent
        anchors.leftMargin: AppConstants.loadBarInset
        anchors.rightMargin: AppConstants.loadBarInset
        z: -1
        Rectangle {
            width: gpuIndicator.hasDedicatedMemory ? parent.width / 2 : parent.width
            height: (gpuIndicator.loadPercent / 100) * parent.height
            color: AppConstants.indicatorBarColor
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        Rectangle {
            visible: gpuIndicator.hasDedicatedMemory
            width: parent.width / 2
            height: (gpuIndicator.memoryPercent / 100) * parent.height
            color: AppConstants.memoryBarColor
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }
    }

    menuWidth: 450
    opensUpward: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 18
                elide: Text.ElideRight
                text: gpuIndicator.gpuName || "…"
            }
        },
        UsageMenuItem {
            label: "Load"
            valueText: gpuIndicator.gpuUsage ? `${gpuIndicator.loadPercent}%` : "…"
            percent: gpuIndicator.loadPercent
        },
        UsageMenuItem {
            barColor: AppConstants.memoryBarColor
            label: "Memory"
            valueText: {
                if (!gpuIndicator.gpuUsage) {
                    return "…";
                }
                return gpuIndicator.hasDedicatedMemory ? `${gpuIndicator.memoryUsed} / ${gpuIndicator.memoryTotal} MiB · ${gpuIndicator.memoryPercent}%` : "shared with system RAM";
            }
            percent: gpuIndicator.memoryPercent
        },
        DropdownMenuHeader {
            text: "Top processes"
        },
        DropdownMenuItem {
            visible: gpuIndicator.processesError !== ""
            StyledText {
                font.pixelSize: 16
                text: gpuIndicator.processesError
            }
        },
        Repeater {
            // A fixed number of rows that only have their values swapped, so
            // hovering and the menu size stay stable between samples.
            model: gpuIndicator.processesError === "" ? gpuIndicator.topProcessCount : 0
            delegate: UsageMenuItem {
                readonly property var processInfo: gpuIndicator.topProcesses[index] || null
                // There can be fewer GPU clients than rows.
                label: processInfo ? processInfo.name : gpuIndicator.processesLoaded ? "" : "…"
                valueText: processInfo ? processInfo.value : ""
                percent: processInfo ? processInfo.percent : 0
            }
        }
    ]

    DaemonTopic {
        id: gpuDetailsTopic
        topic: "gpu.details"
        active: gpuIndicator.menuVisible
    }

    DaemonTopic {
        id: gpuTopic
        topic: "gpu"
    }
}
