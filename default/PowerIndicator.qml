import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Widgets

// toggleMouseAreaContainsMouse
DropdownMenu {
    toggleIconColor: {
        if (!UPower.displayDevice.isLaptopBattery) {
            return AppConstants.styledTextColor;
        }
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
        let iconName = "power-off";
        if (UPower.displayDevice.isLaptopBattery) {
            iconName = "battery-full";

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
        }
        return Qt.resolvedUrl(`assets/icons/fontawesome/solid/${iconName}.svg`);
    }

    toggleText: {
        if (!UPower.displayDevice.isLaptopBattery) {
            return "";
        }
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

    menuWidth: 200
    menuAnchors.top: true

    menuContent: [
        GridLayout {
            columns: 2
            columnSpacing: 0
            rowSpacing: 0

            DropdownMenuItem {
                Layout.columnSpan: 1
                action: () => {
                    Quickshell.execDetached({
                        command: ["shutdown", "now"]
                    });
                }
                RowLayout {
                    anchors.fill: parent
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/power-off.svg`)
                        iconColor: "lightgray"
                    }
                }
            }
            DropdownMenuItem {
                Layout.columnSpan: 1
                action: () => {
                    Hyprland.dispatch("exit");
                }
                RowLayout {
                    anchors.fill: parent
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/right-from-bracket.svg`)
                        iconColor: "lightgray"
                    }
                }
            }
            DropdownMenuItem {
                Layout.columnSpan: 1
                action: () => {
                    Hyprland.dispatch("switchxkblayout all 0");
                    Quickshell.execDetached({
                        command: ["hyprlock"]
                    });
                }
                RowLayout {
                    anchors.fill: parent
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/lock.svg`)
                        iconColor: "lightgray"
                    }
                }
            }
            DropdownMenuItem {
                Layout.columnSpan: 1
                action: () => {
                    console.log("there will be an autorotate control here");
                }
                StyledText {
                    text: ""
                }
            }
            DropdownMenuItem {
                Layout.columnSpan: 1
                action: () => {
                    Quickshell.execDetached({
                        command: ["brightnessctl", "set", "10%-"]
                    });
                }
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Rectangle {
                        color: "transparent"
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/square-minus.svg`)
                        iconColor: "lightgray"
                    }
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/sun.svg`)
                        iconColor: "lightgray"
                    }
                    Rectangle {
                        color: "transparent"
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
            }
            DropdownMenuItem {
                Layout.columnSpan: 1
                action: () => {
                    Quickshell.execDetached({
                        command: ["brightnessctl", "set", "10%+"]
                    });
                }
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Rectangle {
                        color: "transparent"
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/sun.svg`)
                        iconColor: "lightgray"
                    }
                    RecoloredIcon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: preferredWidth
                        iconWidth: 26
                        iconHeight: 26
                        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/square-plus.svg`)
                        iconColor: "lightgray"
                    }
                    Rectangle {
                        color: "transparent"
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
            }
        }
    ]
}
