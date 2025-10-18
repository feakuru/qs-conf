import QtQuick
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    visible: UPower.displayDevice.isLaptopBattery

    StyledText {
        text: {
            let device = UPower.displayDevice;
            let result = `🔋 ${device.percentage}%`;
            if (device.chargeRate > 0) {
                result += ` [${device.timeToFull / 60} min to charge]`;
            } else {
                result += ` [${device.timeToEmpty / 60} min left]`;
            }
            if (device.healthSupported) {
                result += ` [health ${device.healthPercentage}%]`
            }
            result
        }
    }
}
