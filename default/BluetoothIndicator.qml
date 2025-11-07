import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

DropdownMenu {
    toggleIconColor: Bluetooth.defaultAdapter.enabled ? AppConstants.bluetoothColor : AppConstants.indicatorOffColor
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/brands/bluetooth.svg")
    toggleText: {
        let result = '';
        let connectedDevices = Bluetooth.defaultAdapter.devices.values.filter(device => device.state == BluetoothDeviceState.Connected);
        if (connectedDevices.length > 0) {
            result += `[${connectedDevices.length}]`;
        }
        result;
    }
    toggleTextFont.pixelSize: 16

    menuWidth: 300
    menuAnchors.top: true

    menuContent: [
        DropdownMenuItem {
            action: () => {
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            }
            StyledText {
                font.pixelSize: 18
                text: `ᛒ turn ${Bluetooth.defaultAdapter.name} ${Bluetooth.defaultAdapter.enabled ? 'off' : 'on'}`
            }
        },
        Repeater {
            model: [...Bluetooth.defaultAdapter.devices.values].filter(d => d.paired).sort((lhs, rhs) => {
                if (lhs.state == BluetoothDeviceState.Connected) {
                    if (rhs.state != BluetoothDeviceState.Connected) {
                        return -1;
                    }
                    return 0;
                }
                return 1;
            })
            delegate: RowLayout {
                spacing: 0
                DropdownMenuItem {
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
                }
                DropdownMenuItem {
                    Layout.fillWidth: false
                    Layout.minimumWidth: 42
                    action: () => {
                        modelData.forget();
                    }
                    StyledText {
                        font.pixelSize: 18
                        text: "x"
                    }
                }
            }
        },
        DropdownMenuItem {
            action: () => {
                Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;
            }
            StyledText {
                font.pixelSize: 18
                text: {
                    if (Bluetooth.defaultAdapter.discovering) {
                        return "[discovering…]";
                    } else {
                        return "[discover devices]";
                    }
                }
            }
        },
        Repeater {
            model: !Bluetooth.defaultAdapter.discovering ? [] : [...Bluetooth.defaultAdapter.devices.values].filter(d => !d.paired).sort((lhs, rhs) => {
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
