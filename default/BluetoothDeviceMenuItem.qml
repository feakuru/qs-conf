import QtQuick
import Quickshell.Bluetooth

// A Bluetooth device row; the bar behind it shows the device's battery level
// when it reports one. Clicking the row runs `action` (e.g. connect or
// disconnect), and paired devices get a button running `forgetAction`.
UsageMenuItem {
    id: bluetoothDeviceItem
    property var device: null
    property var forgetAction: () => {}

    readonly property bool hasBattery: device ? device.connected && device.batteryAvailable : false
    readonly property int batteryPercent: hasBattery ? Math.round(device.battery * 100) : 0

    label: device ? device.name : ""
    labelColor: device && device.connected ? AppConstants.indicatorOnColor : AppConstants.styledTextColor
    percent: batteryPercent
    valueRightMargin: forgetButton.visible ? forgetButton.width + 12 : 12
    valueText: {
        if (!device) {
            return "";
        }
        let parts = [];
        if (device.pairing) {
            parts.push("pairing…");
        } else {
            switch (device.state) {
            case BluetoothDeviceState.Connected:
                parts.push("connected");
                break;
            case BluetoothDeviceState.Connecting:
                parts.push("connecting…");
                break;
            case BluetoothDeviceState.Disconnecting:
                parts.push("disconnecting…");
                break;
            }
        }
        if (hasBattery) {
            parts.push(`battery ${batteryPercent}%`);
        }
        return parts.join(" · ");
    }

    WindowActionButton {
        id: forgetButton
        visible: bluetoothDeviceItem.device ? bluetoothDeviceItem.device.paired : false
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "trash"
        activeIconColor: AppConstants.dangerColor
        action: () => bluetoothDeviceItem.forgetAction()
    }
}
