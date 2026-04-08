import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

DropdownMenu {
    id: cpuIndicator
    property real barWidth: cpuIndicator.cpuData.length > 16 ? 4 : 10
    property real preferredWidth: cpuIndicator.cpuData.length * barWidth

    property var cpuData: []
    property var cpuTempData: []

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

    menuWidth: 500
    menuAnchors.bottom: true
    menuContent: [
        Repeater {
            model: cpuIndicator.cpuTempData
            delegate: DropdownMenuItem {
                height: chipLabel.height + Math.ceil(modelData.temps.length / 2) * 36
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    anchors.margins: 12
                    Rectangle {
                        color: "transparent"
                        Layout.preferredHeight: chipLabel.height
                        Layout.preferredWidth: chipLabel.width
                        Layout.columnSpan: 2
                        StyledText {
                            id: chipLabel
                            text: modelData.name
                        }
                    }
                    Repeater {
                        model: modelData.temps
                        delegate: Rectangle {
                            color: "transparent"
                            Layout.preferredHeight: tempLabel.height
                            Layout.preferredWidth: tempLabel.width
                            StyledText {
                                id: tempLabel
                                text: modelData
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }
    ]

    Process {
        id: cpuTempProcess
        command: ["sensors", "-J"]

        stdout: StdioCollector {
            onStreamFinished: {
                let result = [];
                let sensorData = JSON.parse(this.text);
                for (let chipKey in sensorData) {
                    let chipData = {
                        "name": `${chipKey} [${sensorData[chipKey]["Adapter"]}]`,
                        "temps": []
                    };
                    for (let tempKey in sensorData[chipKey]) {
                        if (tempKey.startsWith("temp")) {
                            let tempData = sensorData[chipKey][tempKey];
                            let tempLabel = tempData["label"] || tempKey;
                            let tempInput = tempData["input"] || {"value": "?", "unit": "?"};
                            chipData["temps"].push(`${tempLabel}: ${tempInput["value"]}${tempInput["unit"]}`);
                        }
                    }
                    if (chipData["temps"].length > 0) {
                        result.push(chipData);
                    }
                }
                cpuIndicator.cpuTempData = result;
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
            if (cpuIndicator.menuVisible) {
                cpuTempProcess.running = true;
            }
        }
    }
}
