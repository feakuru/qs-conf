import QtQuick
import Quickshell.Io

Rectangle {
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor

    StyledText {
        id: volumeIndicator

        Process {
            id: volumeProc
            command: ["bash", "-c", 'pactl get-sink-volume @DEFAULT_SINK@ | grep -oP \'\\d+%\' | awk \'NR==1{L=$0} NR==2{print L " " $0}\'',]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    let [leftVolume, rightVolume] = this.text.split(' ');
                    let result = "🔊";
                    if (parseFloat(leftVolume) == parseFloat(rightVolume)) {
                        result += leftVolume;
                    } else {
                        result = leftVolume + result + rightVolume;
                    }
                    volumeIndicator.text = result;
                }
            }
        }

        Timer {
            interval: 200
            running: true
            repeat: true
            onTriggered: function () {
                volumeProc.running = true;
            }
        }
    }
}
