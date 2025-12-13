import Quickshell
import Quickshell.Io
import QtQuick

DropdownMenu {
    id: cpuIndicator
    property real barWidth: cpuIndicator.cpuData.length > 16 ? 4 : 10
    property real preferredWidth: cpuIndicator.cpuData.length * barWidth

    property var cpuData: []

    toggleTextFont.pixelSize: 18
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/microchip.svg")
    toggleIconColor: "white"

    Row {
        anchors.fill: parent
        spacing: 0
        z: -1
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

    menuWidth: 300
    menuAnchors.bottom: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                text: "under construction"
            }
        }
    ]

    ScriptProcess {
        id: cpuProcess
        scriptName: "cpu_per_core_load"
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                cpuIndicator.cpuData = this.text.split(" ").map(x => parseInt(x));
            }
        }
    }

    ScriptProcess {
        id: cpuPercentProcess
        scriptName: "cpu_load"
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                cpuIndicator.toggleText = `${this.text.trim()}%`;
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
