import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

DropdownMenu {
    id: bluetoothIndicator

    // Null until BlueZ reports an adapter (e.g. right at startup, or on
    // machines without Bluetooth).
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool adapterEnabled: adapter ? adapter.enabled : false
    readonly property bool adapterDiscovering: adapter ? adapter.discovering : false
    readonly property var devices: adapter ? [...adapter.devices.values] : []

    toggleIconColor: adapterEnabled ? AppConstants.bluetoothColor : AppConstants.indicatorOffColor
    toggleIconOutlineColor: AppConstants.iconOutlineColor
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/brands/bluetooth.svg")

    toggleTextFont.pixelSize: 16
    toggleText: {
        let result = '';
        let connectedDevices = bluetoothIndicator.devices.filter(device => device.state == BluetoothDeviceState.Connected);
        if (connectedDevices.length > 0) {
            result += `[${connectedDevices.length}]`;
        }
        result;
    }

    menuWidth: 300
    menuContent: [
        DropdownMenuItem {
            action: () => {
                if (bluetoothIndicator.adapter) {
                    bluetoothIndicator.adapter.enabled = !bluetoothIndicator.adapter.enabled;
                }
            }
            StyledText {
                font.pixelSize: 18
                text: bluetoothIndicator.adapter ? `ᛒ turn ${bluetoothIndicator.adapter.name} ${bluetoothIndicator.adapterEnabled ? 'off' : 'on'}` : "ᛒ no adapter"
            }
        },
        Repeater {
            model: bluetoothIndicator.devices.filter(d => d.paired).sort((lhs, rhs) => {
                if (lhs.state == BluetoothDeviceState.Connected) {
                    if (rhs.state != BluetoothDeviceState.Connected) {
                        return -1;
                    }
                    return 0;
                }
                return 1;
            })
            delegate: DropdownMenuItem {
                action: () => {
                    if (modelData.connected) {
                        modelData.disconnect();
                    } else {
                        modelData.connect();
                    }
                }
                StyledText {
                    font.pixelSize: 18
                    text: {
                        let result = modelData.name;
                        if (modelData.batteryAvailable) {
                            result += ` [${modelData.battery * 100}%]`;
                        }
                        switch (modelData.state) {
                        case BluetoothDeviceState.Connecting:
                        case BluetoothDeviceState.Disconnecting:
                            result += ' […]';
                            break;
                        case BluetoothDeviceState.Connected:
                            result += ' [+]';
                            break;
                        }
                        result;
                    }
                }
                WindowActionButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "xmark"
                    activeIconColor: AppConstants.dangerColor
                    action: () => {
                        modelData.forget();
                    }
                }
            }
        },
        DropdownMenuItem {
            visible: !!bluetoothIndicator.adapter
            action: () => {
                if (bluetoothIndicator.adapter) {
                    bluetoothIndicator.adapter.discovering = !bluetoothIndicator.adapter.discovering;
                }
            }
            StyledText {
                font.pixelSize: 18
                text: bluetoothIndicator.adapterDiscovering ? "[discovering…]" : "[discover devices]"
            }
        },
        Repeater {
            model: !bluetoothIndicator.adapterDiscovering ? [] : bluetoothIndicator.devices.filter(d => !d.paired).sort((lhs, rhs) => {
                if (lhs.pairing) {
                    if (!rhs.pairing) {
                        return -1;
                    }
                    return 0;
                }
                return 1;
            })
            delegate: DropdownMenuItem {
                action: () => {
                    if (modelData.pairing) {
                        modelData.cancelPair();
                    } else {
                        modelData.pair();
                    }
                }
                StyledText {
                    font.pixelSize: 18
                    text: {
                        let result = modelData.name;
                        if (modelData.pairing) {
                            result += ' […]';
                        }
                        result;
                    }
                }
            }
        }
    ]
}
