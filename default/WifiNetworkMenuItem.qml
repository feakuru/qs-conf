import QtQuick
import Quickshell.Networking

// A Wi-Fi network row; the bar behind it shows the signal strength. Clicking
// the row runs `action` (connect or disconnect), and saved networks get a
// button running `forgetAction`.
UsageMenuItem {
    id: wifiNetworkItem
    property var network: null
    property var forgetAction: () => {}

    readonly property bool secured: network ? network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe : false
    readonly property int signalPercent: network ? Math.round(network.signalStrength * 100) : 0

    label: network ? network.name : ""
    labelColor: network && network.connected ? AppConstants.indicatorOnColor : AppConstants.styledTextColor
    percent: signalPercent
    valueRightMargin: forgetButton.visible ? forgetButton.width + 12 : 12
    valueText: {
        if (!network) {
            return "";
        }
        let parts = [];
        switch (network.state) {
        case ConnectionState.Connected:
            parts.push("connected");
            break;
        case ConnectionState.Connecting:
            parts.push("connecting…");
            break;
        case ConnectionState.Disconnecting:
            parts.push("disconnecting…");
            break;
        default:
            if (network.known) {
                parts.push("saved");
            }
            break;
        }
        if (!secured) {
            parts.push("open");
        }
        parts.push(`${signalPercent}%`);
        return parts.join(" · ");
    }

    WindowActionButton {
        id: forgetButton
        visible: wifiNetworkItem.network ? wifiNetworkItem.network.known : false
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "trash"
        activeIconColor: AppConstants.dangerColor
        action: () => wifiNetworkItem.forgetAction()
    }
}
