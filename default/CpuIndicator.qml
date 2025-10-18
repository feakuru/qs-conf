import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: cpuIndicator
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real preferredWidth: cpuIndicator.cpuData.length * 8

    property var cpuData: []

    Process {
        id: cpuProcess
        command: ["python", "-c", "import psutil; print(' '.join(str(int(val)) for val in psutil.cpu_percent(percpu=True, interval=0.1)))"]
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
                width: 4
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
            command: ["python", "-c", "import psutil; print(f'{int(psutil.cpu_percent(interval=0.1)): 2d}', end='')"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    if (cpuIndicator.cpuData.length > 16) {
                        cpuPercentIndicator.text = `🔲 ${this.text.trim()}%`;
                    }
                    else {
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
