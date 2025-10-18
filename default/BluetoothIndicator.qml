import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

DropdownMenu {
    id: btIndicator
    border.color: AppConstants.indicatorBorderColor

    property real preferredWidth: toggleText.length * 20 + 12

    toggleText: {
        let result = 'ᛒ';
        let connectedDevices = Bluetooth.defaultAdapter.devices.values.filter(device => device.state == BluetoothDeviceState.Connected);
        if (connectedDevices.length > 0) {
            result += ` ${connectedDevices.length}`;
        }
        result;
    }
    toggleTextColor: Bluetooth.defaultAdapter.enabled ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor

    menuWidth: 300
    menuAnchors.right: true
    menuAnchors.top: true
    menuMargins.right: Screen.desktopAvailableWidth - btIndicator.x - menuWidth

    DropdownMenuItem {
        text: `ᛒ turn ${Bluetooth.defaultAdapter.name} ${Bluetooth.defaultAdapter.enabled ? 'off' : 'on'}`
        action: () => {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }
    }

    Repeater {
        model: Bluetooth.defaultAdapter.devices
        delegate: DropdownMenuItem {
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
            action: () => {
                if (modelData.connected) {
                    modelData.disconnect();
                } else {
                    modelData.connect();
                }
            }
        }
    }
}
