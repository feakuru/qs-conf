import QtQuick
import Quickshell

DropdownMenu {
    id: vpnIndicator
    // The daemon's `vpn` topic: {connections, traffic, sent, received};
    // null while it's unreachable.
    readonly property var vpnStatus: Daemon.connected ? vpnTopic.latest : null
    // [{uuid, type, active, state, name}], active first. Only reassigned
    // when it changes, so rows are kept while their traffic updates.
    property var vpnConnections: []
    property string vpnConnectionsJson: ""
    readonly property var activeVpnConnections: vpnConnections.filter(c => c.active)
    // Per-connection traffic by UUID, and the totals ("" while no VPN is up).
    readonly property var vpnTraffic: vpnStatus ? vpnStatus.traffic : ({})
    readonly property string totalSent: vpnStatus ? vpnStatus.sent : ""
    readonly property string totalReceived: vpnStatus ? vpnStatus.received : ""
    // A vpn.up/vpn.down call is pending.
    property bool toggling: false

    toggleIconColor: activeVpnConnections.length > 0 ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/shield-halved.svg")

    toggleTextFont.pixelSize: 16
    // Speeds left of the shield, in the same format as NetworkIndicator, so
    // the room reserved for wider values is at the outer edge.
    toggleLeadingText: activeVpnConnections.length > 0 && totalSent !== "" ? `${totalSent} ⬆️\n${totalReceived} ⬇️` : ""
    toggleLeadingTextWidest: activeVpnConnections.length > 0 ? "999.99 MiB/s ⬆️" : ""
    // Small enough that the two lines don't take up the bar's full height.
    toggleLeadingTextFont.pixelSize: 12
    toggleText: activeVpnConnections.length > 0 ? `[${activeVpnConnections.length}]` : ""

    menuWidth: 450

    function toggleConnection(connection) {
        if (vpnIndicator.toggling) {
            return;
        }
        let method = connection.active ? "vpn.down" : "vpn.up";
        vpnIndicator.toggling = Daemon.call(method, {
            uuid: connection.uuid
        }, (result, error) => {
            vpnIndicator.toggling = false;
            if (error !== undefined) {
                console.warn(`VpnIndicator: ${method} ${connection.name} failed:`, error);
            }
        });
    }

    function setConnections(connections) {
        let json = JSON.stringify(connections);
        if (json !== vpnIndicator.vpnConnectionsJson) {
            vpnIndicator.vpnConnectionsJson = json;
            vpnIndicator.vpnConnections = connections;
        }
    }

    DaemonTopic {
        id: vpnTopic
        topic: "vpn"
        onData: status => vpnIndicator.setConnections(status.connections || [])
    }

    Connections {
        target: Daemon

        function onConnectedChanged() {
            if (!Daemon.connected) {
                vpnIndicator.setConnections([]);
            }
        }
    }

    menuContent: [
        DropdownMenuItem {
            visible: vpnIndicator.vpnConnections.length === 0
            StyledText {
                font.pixelSize: 18
                text: vpnIndicator.vpnStatus ? "No VPN connections configured" : "…"
            }
        },
        Repeater {
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
