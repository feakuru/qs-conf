import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Widgets

DropdownMenu {
    id: powerIndicator
    toggleIconColor: {
        if (!UPower.displayDevice.isLaptopBattery) {
            return AppConstants.styledTextColor;
        }
        let percentage = UPower.displayDevice.percentage;
        if (percentage <= 0.1) {
            return Qt.rgba(0.9, 0.2, 0.2, 0.9);
        } else if (percentage <= 0.3) {
            return Qt.rgba(0.9, 0.9, 0.2, 0.9);
        } else {
            return AppConstants.styledTextColor;
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
        if (device.state == UPowerDeviceState.Charging) {
            result += "+";
        }
        if (toggleMouseAreaContainsMouse) {
            if (device.state == UPowerDeviceState.Charging) {
                result += ` [${Math.floor(device.timeToFull / 60)}m to full]`;
            } else {
                let hours = Math.floor(device.timeToEmpty / 3600);
                if (hours > 0) {
                    let minutes = Math.floor((device.timeToEmpty % 3600) / 60);
                    result += ` [${hours}h${minutes}m]`;
                } else {
                    let minutes = Math.floor(device.timeToEmpty / 60);
                    if (minutes > 0) {
                        result += ` [${minutes}m]`;
                    }
                }
            }
            if (device.healthSupported) {
                result += ` [health ${device.healthPercentage}%]`;
            }
        }
        result;
    }

    menuWidth: 200

    property bool showShutdownDialog: false

    onMenuVisibleChanged: () => {
        showShutdownDialog = false;
        if (menuVisible) {
            // Pick up changes made outside the shell (CLI, autostart, ...).
            ThemeMode.refresh();
        }
    }

    menuContent: [
        Loader {
            Layout.fillWidth: true

            readonly property Component baseMenu: GridLayout {
                columns: 2
                columnSpacing: 0
                rowSpacing: 0

                IconMenuItem {
                    iconNames: ["power-off"]
                    action: () => {
                        powerIndicator.showShutdownDialog = true;
                    }
                }
                IconMenuItem {
                    iconNames: ["right-from-bracket"]
                    action: () => {
                        Hyprland.dispatch("exit");
                    }
                }
                IconMenuItem {
                    iconNames: ["lock"]
                    action: () => {
                        Quickshell.execDetached({
                            command: ["hyprctl", "switchxkblayout", "all", "0"]
                        });
                        Quickshell.execDetached({
                            command: ["hyprlock"]
                        });
                    }
                }
                IconMenuItem {
                    action: () => {
                        console.log("there will be an autorotate control here");
                    }
                }
                IconMenuItem {
                    iconNames: ["square-minus", "sun"]
                    action: () => {
                        Quickshell.execDetached({
                            command: ["brightnessctl", "set", "5%-"]
                        });
                    }
                }
                IconMenuItem {
                    iconNames: ["sun", "square-plus"]
                    action: () => {
                        Quickshell.execDetached({
                            command: ["brightnessctl", "set", "5%+"]
                        });
                    }
                }
                // Full-width tap-to-toggle row: shows the mode that is active
                // now, and a tap always flips it. Deliberately not a two-half
                // segmented control, because on a touch screen one half would
                // be a silent no-op with no hover state to explain why.
                IconMenuItem {
                    Layout.columnSpan: 2
                    enabled: !ThemeMode.busy
                    opacity: ThemeMode.busy ? 0.5 : 1
                    iconNames: [ThemeMode.isDark ? "moon" : "sun"]
                    text: ThemeMode.isDark ? "Dark" : "Light"
                    action: () => {
                        ThemeMode.toggle();
                    }
                }
            }

            readonly property Component shutdownMenu: GridLayout {
                columns: 2
                columnSpacing: 0
                rowSpacing: 0

                IconMenuItem {
                    iconNames: ["power-off"]
                    iconColor: AppConstants.dangerColor
                    action: () => {
                        Quickshell.execDetached({
                            command: ["shutdown", "now"]
                        });
                    }
                }
                IconMenuItem {
                    iconNames: ["arrows-rotate"]
                    iconColor: AppConstants.dangerColor
                    action: () => {
                        Quickshell.execDetached({
                            command: ["reboot"]
                        });
                    }
                }
                IconMenuItem {
                    iconNames: ["cancel"]
                    action: () => {
                        powerIndicator.showShutdownDialog = false;
                    }
                }
            }

            sourceComponent: powerIndicator.showShutdownDialog ? shutdownMenu : baseMenu
        }
    ]
}
