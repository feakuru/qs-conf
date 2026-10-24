import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: volumeIndicator
    toggleIconColor: AppConstants.styledTextColor
    toggleIconSource: {
        let iconName = "off";
        if (isMuted) {
            iconName = "xmark";
        } else {
            let volume = leftVolume + rightVolume;
            if (volume > 100) {
                iconName = "high";
            } else if (volume > 0) {
                iconName = "low";
            } else {
                iconName = "off";
            }
        }
        Qt.resolvedUrl(`assets/icons/fontawesome/solid/volume-${iconName}.svg`);
    }
    property bool isMuted: false
    property real leftVolume: 0
    property real rightVolume: 0

    toggleTextFont.pixelSize: 18
    toggleText: {
        if (isMuted) {
            return '';
        } else if (leftVolume == rightVolume) {
            return `${leftVolume}%`;
        } else {
            return `L${leftVolume} R${rightVolume}`;
        }
    }

    menuWidth: 200
    menuColumns: 3
    menuContent: [
        IconMenuItem {
            iconNames: ["volume-low"]
            action: () => {
                Quickshell.execDetached({
                    command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%"]
                });
            }
        },
        IconMenuItem {
            iconNames: ["volume-xmark"]
            action: () => {
                Quickshell.execDetached({
                    command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
                });
            }
        },
        IconMenuItem {
            iconNames: ["volume-high"]
            action: () => {
                Quickshell.execDetached({
                    command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%"]
                });
            }
        }
    ]

    Process {
        id: volumeProc
        command: ["bash", "-c", 'pactl get-sink-volume @DEFAULT_SINK@ | grep -oP \'\\d+%\' | awk \'NR==1{L=$0} NR==2{print L " " $0}\'',]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let [newLeftVolume, newRightVolume] = this.text.split(' ');
                volumeIndicator.leftVolume = parseFloat(newLeftVolume);
                volumeIndicator.rightVolume = parseFloat(newRightVolume);
            }
        }
    }

    Process {
        id: muteCheckProc
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let value = this.text.trim().split(" ").pop();
                switch (value) {
                case "yes":
                    volumeIndicator.isMuted = true;
                    break;
                case "no":
                    volumeIndicator.isMuted = false;
                    break;
                default:
                    console.log("could not get mute status from:", this.text);
                }
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: function () {
            volumeProc.running = true;
            muteCheckProc.running = true;
        }
    }
}
