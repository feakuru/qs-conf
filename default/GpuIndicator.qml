import QtQuick
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: gpuIndicator
    property string gpuName: ""
    property int loadPercent: 0
    property int memoryUsed: 0
    property int memoryTotal: 0
    // Integrated GPUs share system RAM and report no dedicated memory.
    property bool hasDedicatedMemory: memoryTotal > 0
    property int memoryPercent: hasDedicatedMemory ? Math.round(memoryUsed / memoryTotal * 100) : 0
    property var topProcesses: []
    property string processesError: ""
    property bool processesLoaded: false
    readonly property int topProcessCount: 5

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/display.svg")

    toggleTextFont.pixelSize: 18
    toggleText: `${gpuIndicator.loadPercent}%`

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
            valueText: `${gpuIndicator.loadPercent}%`
            percent: gpuIndicator.loadPercent
        },
        UsageMenuItem {
            barColor: AppConstants.memoryBarColor
            label: "Memory"
            valueText: gpuIndicator.hasDedicatedMemory ? `${gpuIndicator.memoryUsed} / ${gpuIndicator.memoryTotal} MiB · ${gpuIndicator.memoryPercent}%` : "shared with system RAM"
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

    ScriptProcess {
        id: gpuDetailsProcess
        scriptName: "gpu_details"
        running: gpuIndicator.menuVisible

        stdout: SplitParser {
            onRead: data => {
                let details;
                try {
                    details = JSON.parse(data);
                } catch (e) {
                    return;
                }
                gpuIndicator.processesLoaded = true;
                gpuIndicator.topProcesses = details.processes || [];
                gpuIndicator.processesError = details.error || "";
            }
        }
    }

    ScriptProcess {
        id: gpuProcess
        scriptName: "gpu_usage"
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let info;
                try {
                    info = JSON.parse(this.text);
                } catch (e) {
                    return;
                }
                gpuIndicator.loadPercent = info.load || 0;
                gpuIndicator.memoryUsed = info.memory_used || 0;
                gpuIndicator.memoryTotal = info.memory_total || 0;
                gpuIndicator.gpuName = info.name || "";
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: function () {
            gpuProcess.running = true;
        }
    }
}
