import QtQuick
import Quickshell.Io

Rectangle {
    color: "transparent"

    StyledText {
        id: netIndicator
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 16
        text: `${txSpeed.toLocaleString()} kB/s ⬆️\n${rxSpeed.toLocaleString()} kB/s ⬇️`

        property var txSpeed: 0.0
        property var rxSpeed: 0.0
    }

    Process {
        id: netProc
        command: ["bash", "-c", "sar -n DEV 1 1 | grep enp4s0 | awk '{print $5 \" \" $6}' | tail -n1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let [rxSpeed, txSpeed] = this.text.trim().split(" ");
                netIndicator.rxSpeed = parseFloat(rxSpeed);
                netIndicator.txSpeed = parseFloat(txSpeed);
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: function () {
            netProc.running = true;
        }
    }
}
