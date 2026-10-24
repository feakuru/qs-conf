import QtQuick
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: vpnIndicator
    property var vpnConnections: []
    property string lastConnectionsOutput: ""
    readonly property var activeVpnConnections: vpnConnections.filter(c => c.active)

    toggleIconColor: activeVpnConnections.length > 0 ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor
    toggleIconOutlineColor: AppConstants.iconOutlineColor
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/shield-halved.svg")

    toggleTextFont.pixelSize: 16
    toggleText: activeVpnConnections.length > 0 ? `[${activeVpnConnections.length}]` : ""

    menuWidth: 350
    opensUpward: true

    function toggleConnection(connection) {
        if (vpnToggleProc.running) {
            return;
        }
        vpnToggleProc.command = ["nmcli", "connection", connection.active ? "down" : "up", "uuid", connection.uuid];
        vpnToggleProc.running = true;
    }

    Process {
        id: vpnListProc
        // NAME goes last so that colons inside it don't break the split below.
        command: ["nmcli", "-t", "-e", "no", "-f", "UUID,TYPE,ACTIVE,STATE,NAME", "connection", "show"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === vpnIndicator.lastConnectionsOutput) {
                    return;
                }
                vpnIndicator.lastConnectionsOutput = this.text;
                let connections = [];
                for (let line of this.text.trim().split("\n")) {
                    let parts = line.split(":");
                    if (parts.length < 5) {
                        continue;
                    }
                    let [uuid, connType, active, connState] = parts;
                    if (connType !== "vpn" && connType !== "wireguard") {
                        continue;
                    }
                    connections.push({
                        uuid: uuid,
                        type: connType,
                        active: active === "yes",
                        state: connState,
                        name: parts.slice(4).join(":")
                    });
                }
                connections.sort((lhs, rhs) => {
                    if (lhs.active !== rhs.active) {
                        return lhs.active ? -1 : 1;
                    }
                    return lhs.name.localeCompare(rhs.name);
                });
                vpnIndicator.vpnConnections = connections;
            }
        }
    }

    Process {
        id: vpnToggleProc
        onExited: vpnListProc.running = true

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.log("Error toggling VPN connection\n", this.text);
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: function () {
            vpnListProc.running = true;
        }
    }

    menuContent: [
        DropdownMenuItem {
            visible: vpnIndicator.vpnConnections.length === 0
            StyledText {
                font.pixelSize: 18
                text: "No VPN connections configured"
            }
        },
        Repeater {
            model: vpnIndicator.vpnConnections
            delegate: DropdownMenuItem {
                action: () => {
                    vpnIndicator.toggleConnection(modelData);
                }
                StyledText {
                    font.pixelSize: 18
                    color: modelData.active ? AppConstants.indicatorOnColor : AppConstants.styledTextColor
                    text: {
                        let result = modelData.name;
                        switch (modelData.state) {
                        case "activating":
                        case "deactivating":
                            result += ' […]';
                            break;
                        case "activated":
                            result += ' [+]';
                            break;
                        }
                        result;
                    }
                }
            }
        }
    ]
}
