import QtQuick
import Quickshell

DropdownMenu {
    id: screenshotMenu

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/camera.svg")

    menuWidth: 220
    menuContent: [
        DropdownMenuHeader {
            text: "screenshot"
        },
        IconMenuItem {
            iconNames: ["desktop"]
            text: "Whole screen"
            textPixelSize: 17
            action: () => {
                screenshotMenu.closeMenu();
                Screenshots.captureScreen(AppConstants.primaryScreen);
            }
        },
        IconMenuItem {
            iconNames: ["crop-simple"]
            text: "Region"
            textPixelSize: 17
            action: () => {
                screenshotMenu.closeMenu();
                Screenshots.captureRegion();
            }
        }
    ]
}
