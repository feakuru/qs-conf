import QtQuick
import Quickshell

DropdownMenu {
    id: screenshotMenu

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/camera.svg")

    menuWidth: 220
    menuContent: [
        DropdownMenuHeader {
            text: "Screenshot"
        },
        IconMenuItem {
            iconNames: ["desktop"]
            text: "Whole screen"
            action: () => {
                screenshotMenu.closeMenu();
                Screenshots.captureScreen(AppConstants.primaryScreen);
            }
        },
        IconMenuItem {
            iconNames: ["crop-simple"]
            text: "Region"
            action: () => {
                screenshotMenu.closeMenu();
                Screenshots.captureRegion();
            }
        }
    ]
}
