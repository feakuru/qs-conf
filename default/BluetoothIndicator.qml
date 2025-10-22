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
    toggleTextColor: Bluetooth.defaultAdapter.enabled ? AppConstants.bluetoothColor : AppConstants.indicatorOffColor

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
            model: Bluetooth.defaultAdapter.devices
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
                            result += ' [...]';
                            break;
                        case BluetoothDeviceState.Connected:
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
