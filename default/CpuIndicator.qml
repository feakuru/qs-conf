import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

DropdownMenu {
    id: cpuIndicator
    property real barWidth: cpuIndicator.cpuData.length > 16 ? 4 : 10
    property real preferredWidth: cpuIndicator.cpuData.length * barWidth

    property var cpuData: []
    property var temperature: null
    property var topProcesses: []
    readonly property int topProcessCount: 5

    toggleTextFont.pixelSize: 18
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/microchip.svg")
    toggleIconColor: AppConstants.styledTextColor

    Item {
        anchors.fill: parent
        z: -1
        Repeater {
            // Keyed on the core count only, so bars are updated in place
            // instead of being recreated on every sample.
            model: cpuIndicator.cpuData.length
            Rectangle {
                x: index * cpuIndicator.barWidth
                width: cpuIndicator.barWidth
                height: ((cpuIndicator.cpuData[index] || 0) / 100) * 42
                color: AppConstants.indicatorBarColor
                anchors.bottom: parent.bottom
            }
        }
    }

    menuWidth: 400
    menuAnchors.bottom: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                font.pixelSize: 18
                color: cpuIndicator.temperature && cpuIndicator.temperature.hot ? AppConstants.dangerColor : AppConstants.styledTextColor
                text: cpuIndicator.temperature ? cpuIndicator.temperature.text : "Temperature: n/a"
            }
        },
        DropdownMenuHeader {
            text: "Top processes"
        },
        Repeater {
            // A fixed number of rows that only have their values swapped, so
            // hovering and the menu size stay stable between samples.
            model: cpuIndicator.topProcessCount
            delegate: UsageMenuItem {
                readonly property var processInfo: cpuIndicator.topProcesses[index] || null
                label: processInfo ? processInfo.name : "…"
                valueText: processInfo ? processInfo.value : ""
                percent: processInfo ? processInfo.percent : 0
            }
        }
    ]

    ScriptProcess {
        id: cpuDetailsProcess
        scriptName: "cpu_details"
        running: cpuIndicator.menuVisible

        stdout: SplitParser {
            onRead: data => {
                let details;
                try {
                    details = JSON.parse(data);
                } catch (e) {
                    return;
                }
                cpuIndicator.temperature = details.temperature;
                cpuIndicator.topProcesses = details.processes || [];
            }
        }
    }

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
        interval: 1000
        running: true
        repeat: true
        onTriggered: function () {
            cpuProcess.running = true;
            cpuPercentProcess.running = true;
        }
    }
}
