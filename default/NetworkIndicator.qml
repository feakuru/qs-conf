import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking

DropdownMenu {
    id: netIndicator
    toggleTextFont.pixelSize: 16
    menuWidth: 450
    opensUpward: true
    property var txSpeed: 0.0
    property var rxSpeed: 0.0
    property string defaultDevice: "enp"
    property var topProcesses: []
    property string processesError: ""
    property bool processesLoaded: false
    readonly property int topProcessCount: 5

    // Null on machines without Wi-Fi, or until NetworkManager reports it.
    readonly property var wifiDevice: [...Networking.devices.values].find(device => device.type === DeviceType.Wifi) || null
    readonly property bool wifiAvailable: wifiDevice !== null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    // Connected first, then saved networks, then by signal strength. Unknown
    // networks are only listed while scanning, i.e. while the menu is open.
    readonly property var wifiNetworks: {
        if (!wifiEnabled || !wifiDevice) {
            return [];
        }
        return [...wifiDevice.networks.values].filter(network => network.name !== "").sort((lhs, rhs) => {
            if (lhs.connected !== rhs.connected) {
                return lhs.connected ? -1 : 1;
            }
            if (lhs.known !== rhs.known) {
                return lhs.known ? -1 : 1;
            }
            return rhs.signalStrength - lhs.signalStrength;
        });
    }
    // The network a connection was last started for, to report its failure
    // even if its row has disappeared from the list in the meantime.
    property var pendingNetwork: null
    property bool pendingNetworkWasKnown: false
    property bool pendingNetworkGotPassword: false
    property string wifiError: ""
    property bool wifiRescanning: false
    readonly property int wifiNetworksShown: 3

    // `speed` is in kB/s, as reported by sar.
    function formatSpeed(speed) {
        if (speed > 1000) {
            return `${(speed / 1000).toFixed(2)} MB/s`;
        }
        return `${speed.toFixed(2)} kB/s`;
    }

    function usesPassword(network) {
        return network.security === WifiSecurityType.WpaPsk || network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.Sae;
    }

    function toggleWifiNetwork(network) {
        if (network.connected || network.state === ConnectionState.Connecting) {
            network.disconnect();
            return;
        }
        netIndicator.wifiError = "";
        netIndicator.pendingNetwork = network;
        netIndicator.pendingNetworkWasKnown = network.known;
        netIndicator.pendingNetworkGotPassword = false;
        if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) {
            network.connect();
        } else if (netIndicator.usesPassword(network)) {
            // Asked up front: connect() would save a profile without a
            // password first, which then fails.
            wifiPasswordPrompt.ask(network, "");
        } else {
            netIndicator.wifiError = `${network.name}: ${WifiSecurityType.toString(network.security)} networks can't be set up from here`;
        }
    }

    function rescanWifi() {
        if (!netIndicator.wifiDevice || wifiRescanProcess.running) {
            return;
        }
        wifiRescanProcess.command = ["nmcli", "device", "wifi", "rescan", "ifname", netIndicator.wifiDevice.name];
        wifiRescanProcess.running = true;
        netIndicator.wifiRescanning = true;
        wifiRescanFeedbackTimer.restart();
    }

    // Quickshell only scans (and lists unknown networks) while this is on.
    Binding {
        when: netIndicator.wifiDevice !== null
        target: netIndicator.wifiDevice
        property: "scannerEnabled"
        value: netIndicator.wifiEnabled && (netIndicator.menuVisible || wifiPasswordPrompt.visible)
    }

    Connections {
        target: netIndicator.pendingNetwork
        ignoreUnknownSignals: true

        function onConnectionFailed(reason) {
            let network = netIndicator.pendingNetwork;
            if (reason === ConnectionFailReason.NoSecrets && netIndicator.usesPassword(network)) {
                wifiPasswordPrompt.ask(network, netIndicator.pendingNetworkGotPassword ? "Wrong password, try again" : "");
                return;
            }
            netIndicator.wifiError = `Couldn't connect to ${network.name}: ${ConnectionFailReason.toString(reason)}`;
        }

        function onConnectedChanged() {
            if (netIndicator.pendingNetwork.connected) {
                netIndicator.wifiError = "";
            }
        }
    }

    WifiPasswordPrompt {
        id: wifiPasswordPrompt

        onSubmitted: (network, password) => {
            netIndicator.pendingNetworkGotPassword = true;
            network.connectWithPsk(password);
        }

        onCancelled: network => {
            // A failed attempt saves a profile with the wrong password; don't
            // leave it behind for networks that weren't saved before.
            if (network && network === netIndicator.pendingNetwork && !netIndicator.pendingNetworkWasKnown && network.known && !network.connected) {
                network.forget();
            }
        }
    }

    Process {
        id: wifiRescanProcess
    }

    Timer {
        id: wifiRescanFeedbackTimer
        // Roughly how long a scan takes; nmcli returns before it finishes.
        interval: 4000
        onTriggered: netIndicator.wifiRescanning = false
    }

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/network-wired.svg")
    toggleIconColor: AppConstants.styledTextColor
    // Speeds left of the icon, like VpnIndicator, so the room reserved for
    // wider values is at the outer edge.
    toggleLeadingText: `${formatSpeed(txSpeed)} ⬆️\n${formatSpeed(rxSpeed)} ⬇️`
    toggleLeadingTextWidest: "999.99 kB/s ⬆️"
    // Small enough that the two lines don't take up the bar's full height.
    toggleLeadingTextFont.pixelSize: 12
    // Active connections by type, each only when there are any.
    toggleText: {
        let parts = [];
        if (wiredConnectionCount > 0) {
            parts.push(`🔌${wiredConnectionCount}`);
        }
        if (wifiConnectionCount > 0) {
            parts.push(`🛜${wifiConnectionCount}`);
        }
        return parts.length > 0 ? parts.join(" ") : "0";
    }

    readonly property int wiredConnectionCount: [...Networking.devices.values].filter(device => device.type === DeviceType.Wired && device.connected).length
    readonly property int wifiConnectionCount: [...Networking.devices.values].filter(device => device.type === DeviceType.Wifi && device.connected).length

    Process {
        id: defaultDeviceProc
        command: ["nmcli", "-t", "connection", "show", "--active"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                for (let line of this.text.trim().split("\n")) {
                    let [name, uuid, devType, device] = line.split(':');
                    if (devType.endsWith("ethernet") || devType.endsWith("wireless")) {
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

    ScriptProcess {
        id: netDetailsProcess
        scriptName: "net_details"
        running: netIndicator.menuVisible

        stdout: SplitParser {
            onRead: data => {
                let details;
                try {
                    details = JSON.parse(data);
                } catch (e) {
                    return;
                }
                netIndicator.processesLoaded = true;
                netIndicator.topProcesses = details.processes || [];
                netIndicator.processesError = details.error || "";
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

    menuContent: [
        DropdownMenuItem {
            // Two lines, as interface names can be long (e.g. USB adapters).
            Layout.preferredHeight: summaryColumn.implicitHeight + 16

            Column {
                id: summaryColumn
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    anchors.centerIn: undefined
                    width: parent.width
                    font.pixelSize: 18
                    elide: Text.ElideRight
                    text: netIndicator.defaultDevice
                }

                StyledText {
                    anchors.centerIn: undefined
                    width: parent.width
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    text: `↑ ${netIndicator.formatSpeed(netIndicator.txSpeed)} · ↓ ${netIndicator.formatSpeed(netIndicator.rxSpeed)}`
                }
            }
        },
        DropdownMenuHeader {
            text: "Top processes"
        },
        DropdownMenuItem {
            visible: netIndicator.processesError !== ""
            Layout.preferredHeight: processesErrorText.implicitHeight + 16

            StyledText {
                id: processesErrorText
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 16
                color: AppConstants.dangerColor
                wrapMode: Text.Wrap
                text: `${netIndicator.processesError} (see README for nethogs setup)`
            }
        },
        Repeater {
            // A fixed number of rows that only have their values swapped, so
            // hovering and the menu size stay stable between samples.
            model: netIndicator.processesError === "" ? netIndicator.topProcessCount : 0
            delegate: UsageMenuItem {
                readonly property var processInfo: netIndicator.topProcesses[index] || null
                // Often only a few processes are using the network.
                label: processInfo ? processInfo.name : netIndicator.processesLoaded ? "" : "…"
                valueText: processInfo ? processInfo.value : ""
                percent: processInfo ? processInfo.percent : 0
            }
        },
        DropdownMenuHeader {
            visible: netIndicator.wifiAvailable
            text: "Wi-Fi"
        },
        DropdownMenuItem {
            visible: netIndicator.wifiAvailable
            action: () => {
                if (Networking.wifiHardwareEnabled) {
                    Networking.wifiEnabled = !Networking.wifiEnabled;
                }
            }
            StyledText {
                font.pixelSize: 18
                text: {
                    if (!Networking.wifiHardwareEnabled) {
                        return "Blocked by hardware switch";
                    }
                    return netIndicator.wifiEnabled ? "On · click to turn off" : "Off · click to turn on";
                }
            }
            WindowActionButton {
                visible: netIndicator.wifiEnabled
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                iconName: "arrows-rotate"
                highlighted: netIndicator.wifiRescanning
                action: () => netIndicator.rescanWifi()
            }
        },
        DropdownMenuItem {
            visible: netIndicator.wifiError !== ""
            Layout.preferredHeight: wifiErrorText.implicitHeight + 16
            action: () => {
                netIndicator.wifiError = "";
            }

            StyledText {
                id: wifiErrorText
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 16
                color: AppConstants.dangerColor
                wrapMode: Text.Wrap
                text: netIndicator.wifiError
            }
        },
        DropdownMenuItem {
            visible: netIndicator.wifiEnabled && netIndicator.wifiNetworks.length === 0
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "Scanning…"
            }
        },
        Flickable {
            id: wifiNetworksFlickable
            // Rows all have the same height; at most wifiNetworksShown of them
            // are visible and the rest scroll.
            readonly property real visibleHeight: wifiNetworksRepeater.count > 0 ? wifiNetworksColumn.implicitHeight * Math.min(wifiNetworksRepeater.count, netIndicator.wifiNetworksShown) / wifiNetworksRepeater.count : 0

            visible: wifiNetworksRepeater.count > 0
            Layout.fillWidth: true
            implicitHeight: visibleHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: wifiNetworksColumn.implicitHeight

            ScrollBar.vertical: ScrollBar {
                id: wifiNetworksScrollBar
                // Hover-enabled controls swallow hover events, which would
                // hide the pointer from the menu (see DropdownMenu.qml).
                hoverEnabled: false
                policy: wifiNetworksFlickable.contentHeight > wifiNetworksFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: wifiNetworksColumn
                width: wifiNetworksFlickable.width - (wifiNetworksScrollBar.policy === ScrollBar.AlwaysOn ? wifiNetworksScrollBar.width : 0)
                spacing: 0

                Repeater {
                    id: wifiNetworksRepeater
                    // ScriptModel keeps the rows of networks that are still
                    // listed, so re-sorting doesn't recreate them.
                    model: ScriptModel {
                        values: netIndicator.wifiNetworks
                    }
                    delegate: WifiNetworkMenuItem {
                        required property var modelData
                        // The first row is at the top of the scroll area,
                        // but still follows the rows above it.
                        showSeparator: true
                        network: modelData
                        action: () => netIndicator.toggleWifiNetwork(modelData)
                        forgetAction: () => modelData.forget()
                    }
                }
            }
        }
    ]
}
