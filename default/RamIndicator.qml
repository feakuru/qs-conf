import QtQuick
import Quickshell
import Quickshell.Io

DropdownMenu {
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/memory.svg")
    toggleIconColor: "white"

    toggleTextFont.pixelSize: 18
    toggleText: `${ramIndicator.percentValue}%`

    Rectangle {
        id: ramIndicator
        z: -1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: AppConstants.indicatorBarColor
        property var percentValue: 0
        height: (percentValue / 100) * 42
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
        id: ramProcess
        scriptName: "ram_usage"
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
