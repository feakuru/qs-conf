import QtQuick
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    color: powerIndicatorMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    visible: UPower.displayDevice.isLaptopBattery
    property real preferredWidth: innerText.width + 20

    StyledText {
        id: innerText
        text: {
            let device = UPower.displayDevice;
            let percentage = Math.floor(device.percentage * 10000) / 100;
            let result = `🔋${percentage}%`;
            if (powerIndicatorMouseArea.containsMouse) {
                if (device.chargeRate > 0) {
                    result += ` [${device.timeToFull / 60} min to charge]`;
                } else {
                    let hours = Math.floor(device.timeToEmpty / 3600);
                    if (hours > 0) {
                        let minutes = (device.timeToEmpty % 3600) % 60;
                        result += ` [${hours}h${minutes}m]`;
                    } else {
                        result += ` [${device.timeToEmpty / 60} m]`;
                    }
                }
                if (device.healthSupported) {
                    result += ` [health ${device.healthPercentage}%]`;
                }
            }
            result;
        }
    }

    MouseArea {
        id: powerIndicatorMouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
