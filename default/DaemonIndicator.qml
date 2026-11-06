import QtQuick

// Whether the shell is connected to qs-conf-daemon (see Daemon.qml). While it
// isn't, widgets fed by the daemon keep their "…" placeholders. The menu shows
// the daemon's version and can ping it.
DropdownMenu {
    id: daemonIndicator

    // E.g. "pong in 2 ms", after a ping from the menu.
    property string pingResult: ""

    toggleIconSource: {
        switch (Daemon.connectionState) {
        case "connected":
            return Qt.resolvedUrl("assets/icons/fontawesome/solid/plug-circle-check.svg");
        case "incompatible":
            return Qt.resolvedUrl("assets/icons/fontawesome/solid/plug-circle-exclamation.svg");
        }
        return Qt.resolvedUrl("assets/icons/fontawesome/solid/plug-circle-xmark.svg");
    }
    toggleIconColor: Daemon.connected ? AppConstants.indicatorOnColor : AppConstants.dangerColor
    toggleIconSize: 22

    menuWidth: 400
    opensUpward: true

    onMenuVisibleChanged: daemonIndicator.pingResult = ""

    menuContent: [
        DropdownMenuHeader {
            text: "qs-conf-daemon"
        },
        UsageMenuItem {
            label: "Status"
            labelColor: Daemon.connected ? AppConstants.indicatorOnColor : AppConstants.dangerColor
            valueText: {
                switch (Daemon.connectionState) {
                case "connected":
                    return "connected";
                case "connecting":
                    return "connecting…";
                case "incompatible":
                    return "incompatible";
                }
                return "not reachable";
            }
            detailLabel: {
                switch (Daemon.connectionState) {
                case "incompatible":
                    return Daemon.daemonProtocol > 0 ? `The daemon speaks protocol ${Daemon.daemonProtocol}, the shell ${Daemon.protocol}` : "The daemon's hello has no protocol version";
                case "disconnected":
                    return "Retrying. Check: systemctl --user status qs-conf-daemon";
                }
                return "";
            }
        },
        UsageMenuItem {
            visible: Daemon.daemonVersion !== ""
            label: "Version"
            valueText: Daemon.daemonVersion
            detailLabel: "Protocol"
            detailValueText: String(Daemon.daemonProtocol)
        },
        UsageMenuItem {
            visible: Daemon.connected
            label: "Ping"
            valueText: daemonIndicator.pingResult !== "" ? daemonIndicator.pingResult : "click to ping"
            action: () => {
                daemonIndicator.pingResult = "…";
                Daemon.ping((ms, error) => {
                    daemonIndicator.pingResult = error !== undefined ? error : `pong in ${ms} ms`;
                });
            }
        }
    ]
}
