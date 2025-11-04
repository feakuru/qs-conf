import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real preferredWidth: indicatorText.width + 30

    Rectangle {
        id: ramIndicator
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: AppConstants.indicatorBarColor
        property var percentValue: 0
        height: (percentValue / 100) * 42
    }
    StyledText {
        id: indicatorText
        text: `🧠 ${ramIndicator.percentValue}%`
        font.pixelSize: 18
    }
    Process {
        id: ramProcess
        command: ["python", Qt.resolvedUrl("scripts/ram_usage.py").toString().replace(/^file:\/{2}/, ""),]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                ramIndicator.percentValue = parseInt(this.text);
            }
        }
    }
    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: function () {
            ramProcess.running = true;
        }
    }
}
