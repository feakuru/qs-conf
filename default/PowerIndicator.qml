import QtQuick
import Quickshell
import Quickshell.Services.UPower

// toggleMouseAreaContainsMouse
DropdownMenu {
    visible: UPower.displayDevice.isLaptopBattery
    toggleIconColor: {
        let percentage = UPower.displayDevice.percentage;
        if (percentage <= 0.1) {
            return Qt.rgba(0.9, 0.2, 0.2, 0.9);
        } else if (percentage <= 0.3) {
            return Qt.rgba(0.9, 0.9, 0.2, 0.9);
        } else if (percentage <= 0.6) {
            return Qt.rgba(0.7, 0.7, 0.2, 0.9);
        } else if (percentage <= 0.9) {
            return Qt.rgba(0.2, 0.7, 0.2, 0.9);
        } else {
            return "white";
        }
    }
    toggleIconSource: {
        let iconName = "battery-full";
        let percentage = UPower.displayDevice.percentage;
        if (percentage <= 0.1) {
            iconName = "battery-empty";
        } else if (percentage <= 0.3) {
            iconName = "battery-quarter";
        } else if (percentage <= 0.6) {
            iconName = "battery-half";
        } else if (percentage <= 0.9) {
            iconName = "battery-three-quarters";
        }
        return Qt.resolvedUrl(`assets/icons/fontawesome/solid/${iconName}.svg`);
    }

    toggleText: {
        let device = UPower.displayDevice;
        let percentage = Math.floor(device.percentage * 10000) / 100;
        let result = `${percentage}%`;
        if (toggleMouseAreaContainsMouse) {
            if (device.state == UPowerDeviceState.Charging) {
                result += ` [${Math.floor(device.timeToFull / 60)}m to full]`;
            } else {
                let hours = Math.floor(device.timeToEmpty / 3600);
                if (hours > 0) {
                    let minutes = Math.floor((device.timeToEmpty % 3600) / 60);
                    result += ` [${hours}h${minutes}m]`;
                } else {
                    result += ` [${Math.floor(device.timeToEmpty / 60)}m]`;
                }
            }
            if (device.healthSupported) {
                result += ` [health ${device.healthPercentage}%]`;
            }
        }
        result;
    }

    menuWidth: 300
    menuAnchors.bottom: true

    menuContent: [
        DropdownMenuItem {
            action: () => { console.log("unimplemented") }
            StyledText {
                text: "test"
            }
        }
    ]
}
