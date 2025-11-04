import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: cpuIndicator
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real barWidth: cpuIndicator.cpuData.length > 16 ? 4 : 8
    property real preferredWidth: cpuIndicator.cpuData.length * barWidth

    property var cpuData: []

    Process {
        id: cpuProcess
        command: ["python", Qt.resolvedUrl("scripts/cpu_per_core_load.py").toString().replace(/^file:\/{2}/, ""),]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                cpuIndicator.cpuData = this.text.split(" ").map(x => parseInt(x));
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: 0
        Repeater {
            model: cpuIndicator.cpuData
            Rectangle {
                width: cpuIndicator.barWidth
                height: (modelData / 100) * 42
                color: AppConstants.indicatorBarColor
                anchors.bottom: parent.bottom
            }
        }
    }
    StyledText {
        id: cpuPercentIndicator
        anchors.fill: parent
        font.pixelSize: 18
        Process {
            id: cpuPercentProcess
            command: ["python", Qt.resolvedUrl("scripts/cpu_load.py").toString().replace(/^file:\/{2}/, ""),]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    if (cpuIndicator.cpuData.length > 16) {
                        cpuPercentIndicator.text = `🔲 ${this.text.trim()}%`;
                    } else {
                        cpuPercentIndicator.text = `${this.text.trim()}%`;
                    }
                }
            }
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: function () {
            cpuProcess.running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: function () {
            cpuPercentProcess.running = true;
        }
    }
}
