import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

DropdownMenu {
    id: powerIndicator
    toggleIconColor: {
        if (!UPower.displayDevice.isLaptopBattery) {
            return AppConstants.iconColor;
        }
        let percentage = UPower.displayDevice.percentage;
        if (percentage <= 0.1) {
            return Qt.rgba(0.9, 0.2, 0.2, 0.9);
        } else if (percentage <= 0.3) {
            return Qt.rgba(0.9, 0.9, 0.2, 0.9);
        } else {
            return AppConstants.iconColor;
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
        result;
    }

    function formatDuration(seconds) {
        let hours = Math.floor(seconds / 3600);
        let minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    // e.g. "85% · 2h 10m left · health 92%"
    readonly property string batteryDetails: {
        let device = UPower.displayDevice;
        if (!device.isLaptopBattery) {
            return "";
        }
        let parts = [`${Math.round(device.percentage * 100)}%`];
        switch (device.state) {
        case UPowerDeviceState.Charging:
            parts.push(device.timeToFull > 0 ? `${formatDuration(device.timeToFull)} to full` : "charging");
            break;
        case UPowerDeviceState.Discharging:
            if (device.timeToEmpty > 0) {
                parts.push(`${formatDuration(device.timeToEmpty)} left`);
            }
            break;
        case UPowerDeviceState.FullyCharged:
            parts.push("full");
            break;
        }
        if (device.healthSupported) {
            parts.push(`health ${Math.round(device.healthPercentage)}%`);
        }
        return parts.join(" · ");
    }

    // Each runs after confirmation in sessionActionDialog, or by itself once
    // its countdown ends.
    readonly property var logoutAction: ({
            title: "Log out?",
            countdownLabel: "Logging out in",
            confirmLabel: "Log out",
            iconName: "right-from-bracket",
            run: () => Hyprland.dispatch("hl.dsp.exit()")
        })
    readonly property var restartAction: ({
            title: "Restart?",
            countdownLabel: "Restarting in",
            confirmLabel: "Restart",
            iconName: "arrows-rotate",
            run: () => Quickshell.execDetached({
                    command: ["systemctl", "reboot"]
                })
        })
    readonly property var powerOffAction: ({
            title: "Power off?",
            countdownLabel: "Powering off in",
            confirmLabel: "Power off",
            iconName: "power-off",
            run: () => Quickshell.execDetached({
                    command: ["systemctl", "poweroff"]
                })
        })

    function askSessionAction(sessionAction) {
        powerIndicator.closeMenu();
        sessionActionDialog.ask(sessionAction);
    }

    menuWidth: 450

    onMenuVisibleChanged: () => {
        if (menuVisible) {
            // Pick up changes made outside the shell (CLI, autostart, ...).
            ThemeMode.refresh();
        }
    }

    SessionActionDialog {
        id: sessionActionDialog
    }

    ScriptProcess {
        id: lockProcess
        scriptName: "lock_session"
    }

    menuContent: [
        UsageMenuItem {
            visible: UPower.displayDevice.isLaptopBattery
            label: "Battery"
            valueText: powerIndicator.batteryDetails
            percent: UPower.displayDevice.percentage * 100
            barColor: UPower.displayDevice.percentage <= 0.1 ? AppConstants.dangerBarColor : AppConstants.indicatorBarColor
        },
        DropdownMenuHeader {
            text: "Session"
        },
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 0
            rowSpacing: 0

            IconMenuItem {
                iconNames: ["lock"]
                text: "Lock"
                action: () => {
                    powerIndicator.closeMenu();
                    lockProcess.running = true;
                }
            }
            IconMenuItem {
                iconNames: ["right-from-bracket"]
                text: "Log out"
                action: () => powerIndicator.askSessionAction(powerIndicator.logoutAction)
            }
            IconMenuItem {
                iconNames: ["arrows-rotate"]
                text: "Restart"
                action: () => powerIndicator.askSessionAction(powerIndicator.restartAction)
            }
            IconMenuItem {
                iconNames: ["power-off"]
                text: "Power off"
                action: () => powerIndicator.askSessionAction(powerIndicator.powerOffAction)
            }
        },
        DropdownMenuHeader {
            text: "Display"
        },
        BrightnessMenuItem {
            active: powerIndicator.menuVisible
        },
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            // Tap-to-toggle: shows the mode that is active now, and a tap
            // always flips it. Deliberately not a two-half segmented
            // control, because on a touch screen one half would be a
            // silent no-op with no hover state to explain why.
            IconMenuItem {
                enabled: !ThemeMode.busy
                opacity: ThemeMode.busy ? 0.5 : 1
                iconNames: [ThemeMode.isDark ? "moon" : "sun"]
                text: ThemeMode.isDark ? "Dark" : "Light"
                action: () => {
                    ThemeMode.toggle();
                }
            }

            Separator {
                visible: AutoRotate.available
                thickness: 1
            }

            // Lit while on; when off, the screen keeps its orientation.
            IconMenuItem {
                visible: AutoRotate.available
                iconNames: ["rotate"]
                iconColor: AutoRotate.enabled ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor
                text: "Auto-rotate"
                action: () => {
                    AutoRotate.toggle();
                }
            }
        }
    ]
}
