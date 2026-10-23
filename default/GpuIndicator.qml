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

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/display.svg")
    toggleIconColor: AppConstants.styledTextColor

    toggleTextFont.pixelSize: 18
    toggleText: `${gpuIndicator.loadPercent}%`

    // Reserve room for "100%" so the widget doesn't resize as the value changes
    preferredWidth: maxToggleTextMetrics.advanceWidth + 32 + 20

    TextMetrics {
        id: maxToggleTextMetrics
        font: gpuIndicator.toggleTextFont
        text: "100%"
    }

    Item {
        anchors.fill: parent
        z: -1
        Rectangle {
            width: gpuIndicator.hasDedicatedMemory ? parent.width / 2 : parent.width
            height: (gpuIndicator.loadPercent / 100) * 42
            color: AppConstants.indicatorBarColor
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        Rectangle {
            visible: gpuIndicator.hasDedicatedMemory
            width: parent.width / 2
            height: (gpuIndicator.memoryPercent / 100) * 42
            color: AppConstants.memoryBarColor
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }
    }

    menuWidth: 600
    menuAnchors.bottom: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                text: gpuIndicator.gpuName
            }
        },
        DropdownMenuItem {
            StyledText {
                text: `Load: ${gpuIndicator.loadPercent}%`
            }
        },
        DropdownMenuItem {
            StyledText {
                text: gpuIndicator.hasDedicatedMemory ? `Memory: ${gpuIndicator.memoryUsed} / ${gpuIndicator.memoryTotal} MiB (${gpuIndicator.memoryPercent}%)` : "Memory: shared with system RAM"
            }
        }
    ]

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
