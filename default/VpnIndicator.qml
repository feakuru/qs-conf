import QtQuick
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: vpnIndicator
    property var vpnConnections: []
    property string lastConnectionsOutput: ""
    readonly property var activeVpnConnections: vpnConnections.filter(c => c.active)
    // Per-connection traffic by UUID, and the totals, from vpn_usage.py.
    property var vpnTraffic: ({})
    property string totalSent: ""
    property string totalReceived: ""

    toggleIconColor: activeVpnConnections.length > 0 ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor
    toggleIconOutlineColor: AppConstants.iconOutlineColor
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/shield-halved.svg")

    toggleTextFont.pixelSize: 16
    // Speeds left of the shield, in the same format as NetworkIndicator, so
    // the room reserved for wider values is at the outer edge.
    toggleLeadingText: activeVpnConnections.length > 0 && totalSent !== "" ? `${totalSent} ⬆️\n${totalReceived} ⬇️` : ""
    toggleLeadingTextWidest: activeVpnConnections.length > 0 ? "999.99 kB/s ⬆️" : ""
    // Small enough that the two lines don't take up the bar's full height.
    toggleLeadingTextFont.pixelSize: 12
    toggleText: activeVpnConnections.length > 0 ? `[${activeVpnConnections.length}]` : ""

    menuWidth: 450
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

    ScriptProcess {
        id: vpnUsageProcess
        scriptName: "vpn_usage"
        running: vpnIndicator.activeVpnConnections.length > 0

        onRunningChanged: {
            if (!running) {
                vpnIndicator.vpnTraffic = {};
                vpnIndicator.totalSent = "";
                vpnIndicator.totalReceived = "";
            }
        }

        stdout: SplitParser {
            onRead: data => {
                let usage;
                try {
                    usage = JSON.parse(data);
                } catch (e) {
                    return;
                }
                vpnIndicator.vpnTraffic = usage.connections || {};
                vpnIndicator.totalSent = usage.sent || "";
                vpnIndicator.totalReceived = usage.received || "";
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
            // Only reassigned when nmcli's output changes, so rows are kept
            // while their traffic updates.
            model: vpnIndicator.vpnConnections
            delegate: UsageMenuItem {
                // The bar is this connection's share of all VPN traffic.
                readonly property var traffic: vpnIndicator.vpnTraffic[modelData.uuid] || null
                action: () => {
                    vpnIndicator.toggleConnection(modelData);
                }
                label: modelData.name
                labelColor: modelData.active ? AppConstants.indicatorOnColor : AppConstants.styledTextColor
                percent: modelData.state === "activated" && traffic ? traffic.percent : 0
                valueText: {
                    switch (modelData.state) {
                    case "activating":
                        return "connecting…";
                    case "deactivating":
                        return "disconnecting…";
                    case "activated":
                        return traffic ? traffic.value : "…";
                    }
                    return "";
                }
            }
        }
    ]
}
