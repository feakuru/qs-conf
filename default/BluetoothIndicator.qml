import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

DropdownMenu {
    id: bluetoothIndicator

    // Null until BlueZ reports an adapter (e.g. right at startup, or on
    // machines without Bluetooth).
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool adapterEnabled: adapter ? adapter.enabled : false
    readonly property bool adapterDiscovering: adapter ? adapter.discovering : false
    readonly property var devices: adapter ? [...adapter.devices.values] : []
    // Connected first, then by name.
    readonly property var pairedDevices: adapterEnabled ? devices.filter(device => device.paired).sort((lhs, rhs) => {
        if (lhs.connected !== rhs.connected) {
            return lhs.connected ? -1 : 1;
        }
        return lhs.name.localeCompare(rhs.name);
    }) : []
    // Only while discovering. Devices being paired first, then the ones
    // that report a name, then by name.
    readonly property var nearbyDevices: adapterDiscovering ? devices.filter(device => !device.paired).sort((lhs, rhs) => {
        if (lhs.pairing !== rhs.pairing) {
            return lhs.pairing ? -1 : 1;
        }
        let lhsNamed = lhs.deviceName !== "";
        let rhsNamed = rhs.deviceName !== "";
        if (lhsNamed !== rhsNamed) {
            return lhsNamed ? -1 : 1;
        }
        return lhs.name.localeCompare(rhs.name);
    }) : []
    readonly property int devicesShown: 5
    // Set when discovery is started from this menu, so it can be stopped
    // again when the menu closes.
    property bool startedDiscovery: false
    // The device last being paired from this menu, connected once paired.
    property var pairingDevice: null
    // BlueZ reports soft (software, e.g. airplane mode) and hard (hardware
    // switch) rfkill blocks alike; only a hard block can't be lifted here.
    readonly property bool adapterBlocked: adapter ? adapter.state === BluetoothAdapterState.Blocked : false
    property bool hardBlocked: false
    // Set when turning on a soft-blocked adapter: it's unblocked first, and
    // powered on once BlueZ reports it as no longer blocked.
    property bool enableAfterUnblock: false

    function toggleAdapter() {
        let adapter = bluetoothIndicator.adapter;
        if (!adapter) {
            return;
        }
        if (bluetoothIndicator.adapterBlocked) {
            if (!bluetoothIndicator.hardBlocked && !rfkillUnblockProcess.running) {
                bluetoothIndicator.enableAfterUnblock = true;
                rfkillUnblockProcess.running = true;
            }
            return;
        }
        adapter.enabled = !adapter.enabled;
    }

    onAdapterBlockedChanged: {
        if (adapterBlocked) {
            rfkillHardBlockProcess.running = true;
        } else if (enableAfterUnblock) {
            enableAfterUnblock = false;
            if (adapter) {
                adapter.enabled = true;
            }
        }
    }

    Process {
        id: rfkillUnblockProcess
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                bluetoothIndicator.enableAfterUnblock = false;
            }
        }
    }

    Process {
        id: rfkillHardBlockProcess
        // One "blocked"/"unblocked" line per Bluetooth rfkill device.
        command: ["rfkill", "--noheadings", "--output", "HARD", "list", "bluetooth"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                bluetoothIndicator.hardBlocked = this.text.split("\n").some(line => line.trim() === "blocked");
            }
        }
    }

    function toggleDiscovery() {
        if (!bluetoothIndicator.adapter) {
            return;
        }
        let discovering = !bluetoothIndicator.adapter.discovering;
        bluetoothIndicator.adapter.discovering = discovering;
        bluetoothIndicator.startedDiscovery = discovering;
    }

    function toggleNearbyDevice(device) {
        if (device.pairing) {
            device.cancelPair();
            return;
        }
        bluetoothIndicator.pairingDevice = device;
        device.pair();
    }

    toggleIconColor: adapterEnabled ? AppConstants.bluetoothColor : AppConstants.indicatorOffColor
    toggleIconOutlineColor: AppConstants.iconOutlineColor
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/brands/bluetooth.svg")

    toggleTextFont.pixelSize: 16
    toggleText: {
        let connectedCount = bluetoothIndicator.devices.filter(device => device.state == BluetoothDeviceState.Connected).length;
        return connectedCount > 0 ? `[${connectedCount}]` : "";
    }

    onMenuVisibleChanged: {
        // Discovery keeps the radio busy, so it only runs while it's useful.
        if (!menuVisible && startedDiscovery) {
            if (adapter && adapter.discovering) {
                adapter.discovering = false;
            }
            startedDiscovery = false;
        }
    }

    Connections {
        target: bluetoothIndicator.pairingDevice
        ignoreUnknownSignals: true

        function onPairedChanged() {
            let device = bluetoothIndicator.pairingDevice;
            if (device && device.paired) {
                // Lets it reconnect by itself later, as in other desktops.
                device.trusted = true;
                device.connect();
                bluetoothIndicator.pairingDevice = null;
            }
        }
    }

    menuWidth: 450
    menuContent: [
        DropdownMenuItem {
            action: () => bluetoothIndicator.toggleAdapter()
            StyledText {
                font.pixelSize: 18
                text: {
                    let adapter = bluetoothIndicator.adapter;
                    if (!adapter) {
                        return "No Bluetooth adapter";
                    }
                    if (bluetoothIndicator.enableAfterUnblock) {
                        return "Turning on…";
                    }
                    switch (adapter.state) {
                    case BluetoothAdapterState.Blocked:
                        // A soft block is just "off" as far as the user is concerned.
                        return bluetoothIndicator.hardBlocked ? "Blocked by hardware switch" : "Off · click to turn on";
                    case BluetoothAdapterState.Enabling:
                        return "Turning on…";
                    case BluetoothAdapterState.Disabling:
                        return "Turning off…";
                    }
                    return adapter.enabled ? "On · click to turn off" : "Off · click to turn on";
                }
            }
            WindowActionButton {
                visible: bluetoothIndicator.adapterEnabled
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                iconName: "magnifying-glass"
                highlighted: bluetoothIndicator.adapterDiscovering
                action: () => bluetoothIndicator.toggleDiscovery()
            }
        },
        DropdownMenuHeader {
            visible: bluetoothIndicator.pairedDevices.length > 0
            text: "Devices"
        },
        ScrollingMenuList {
            rowCount: pairedDevicesRepeater.count
            maxVisibleRows: bluetoothIndicator.devicesShown

            Repeater {
                id: pairedDevicesRepeater
                // ScriptModel keeps the rows of devices that are still listed,
                // so re-sorting doesn't recreate them.
                model: ScriptModel {
                    values: bluetoothIndicator.pairedDevices
                }
                delegate: BluetoothDeviceMenuItem {
                    required property var modelData
                    // The first row is at the top of the scroll area, but
                    // still follows the rows above it.
                    showSeparator: true
                    device: modelData
                    action: () => {
                        if (modelData.connected) {
                            modelData.disconnect();
                        } else {
                            modelData.connect();
                        }
                    }
                    forgetAction: () => modelData.forget()
                }
            }
        },
        DropdownMenuHeader {
            visible: bluetoothIndicator.adapterDiscovering
            text: "Nearby devices"
        },
        DropdownMenuItem {
            visible: bluetoothIndicator.adapterDiscovering && bluetoothIndicator.nearbyDevices.length === 0
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "Searching…"
            }
        },
        ScrollingMenuList {
            rowCount: nearbyDevicesRepeater.count
            maxVisibleRows: bluetoothIndicator.devicesShown

            Repeater {
                id: nearbyDevicesRepeater
                model: ScriptModel {
                    values: bluetoothIndicator.nearbyDevices
                }
                delegate: BluetoothDeviceMenuItem {
                    required property var modelData
                    showSeparator: true
                    device: modelData
                    action: () => bluetoothIndicator.toggleNearbyDevice(modelData)
                }
            }
        }
    ]
}
