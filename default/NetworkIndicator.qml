import QtQuick
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: netIndicator
    toggleTextHorizontalAlignment: Text.AlignRight
    toggleTextFont.pixelSize: 16
    menuWidth: 300
    menuAnchors.top: true
    property var txSpeed: 0.0
    property var rxSpeed: 0.0
    property string defaultDevice: "enp"
    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property var wifiConnections: {}

    toggleText: {
        let txSpeedDisplay = txSpeed;
        let txUnit = "kB/s";
        let rxSpeedDisplay = rxSpeed;
        let rxUnit = "kB/s";
        if (txSpeedDisplay > 1000) {
            txSpeedDisplay = txSpeedDisplay / 1000;
            txUnit = "MB/s";
        }
        if (rxSpeedDisplay > 1000) {
            rxSpeedDisplay = rxSpeedDisplay / 1000;
            rxUnit = "MB/s";
        }
        txSpeedDisplay = txSpeedDisplay.toFixed(2).toLocaleString();
        rxSpeedDisplay = rxSpeedDisplay.toFixed(2).toLocaleString();
        `${txSpeedDisplay} ${txUnit} ⬆️\n${rxSpeedDisplay} ${rxUnit} ⬇️`;
    }

    DropdownMenuItem {
        StyledText {
            font.pixelSize: 18
            text: `Active device: ${netIndicator.defaultDevice}`
        }

        Process {
            id: defaultDeviceProc
            command: ["nmcli", "-t", "connection", "show", "--active"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    for (let line of this.text.trim().split("\n")) {
                        let [name, uuid, devType, device] = line.split(':');
                        if (devType.endsWith("ethernet")) {
                            netIndicator.defaultDevice = device;
                            break;
                        }
                    }
                }
            }
        }

        Process {
            id: netSpeedProc
            command: ["bash", "-c", `sar -n DEV 1 1 | grep ${netIndicator.defaultDevice} | awk '{print $5 " " $6}' | tail -n1`]
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
            interval: 1200
            running: true
            repeat: true
            onTriggered: function () {
                netSpeedProc.running = true;
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: function () {
                defaultDeviceProc.running = true;
            }
        }
    }

    DropdownMenuItem {
        StyledText {
            font.pixelSize: 18
            text: `Wifi: ${!netIndicator.wifiAvailable ? 'n/a' : netIndicator.wifiEnabled ? 'on' : 'off'}`
        }
        action: () => {
            wifiToggleProcess.running = true;
        }
        Process {
            id: wifiToggleProcess
            command: ["nmcli", "radio", "wifi", netIndicator.wifiEnabled ? "off" : "on"]
        }

        Process {
            id: wifiStatusProc
            command: ["nmcli", "radio", "wifi"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    switch (this.text.trim()) {
                    case "disabled":
                        netIndicator.wifiAvailable = true;
                        netIndicator.wifiEnabled = false;
                        break;
                    case "enabled":
                        netIndicator.wifiAvailable = true;
                        netIndicator.wifiEnabled = true;
                        break;
                    default:
                        netIndicator.wifiAvailable = false;
                        netIndicator.wifiEnabled = false;
                        break;
                    }
                }
            }
        }

        Timer {
            interval: 200
            running: true
            repeat: true
            onTriggered: function () {
                wifiStatusProc.running = true;
            }
        }
    }
}
