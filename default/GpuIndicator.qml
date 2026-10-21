import QtQuick
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: gpuIndicator
    property string gpuName: ""
    property int loadPercent: 0
    property int memoryUsed: 0
    property int memoryTotal: 0
    property int memoryPercent: memoryTotal > 0 ? Math.round(memoryUsed / memoryTotal * 100) : 0

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
            width: parent.width / 2
            height: (gpuIndicator.loadPercent / 100) * 42
            color: AppConstants.indicatorBarColor
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        Rectangle {
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
                text: `Memory: ${gpuIndicator.memoryUsed} / ${gpuIndicator.memoryTotal} MiB (${gpuIndicator.memoryPercent}%)`
            }
        }
    ]

    Process {
        id: gpuProcess
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,name", "--format=csv,noheader,nounits"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let fields = this.text.trim().split("\n")[0].split(",").map(x => x.trim());
                if (fields.length < 4) {
                    return;
                }
                gpuIndicator.loadPercent = parseInt(fields[0]) || 0;
                gpuIndicator.memoryUsed = parseInt(fields[1]) || 0;
                gpuIndicator.memoryTotal = parseInt(fields[2]) || 0;
                gpuIndicator.gpuName = fields.slice(3).join(",");
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
