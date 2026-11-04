import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Windows of the focused workspace. Fills the remaining width of the bar and
// can be dragged sideways when there are more windows than fit.
Item {
    id: windowControls
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int workspaceId: focusedWorkspace ? focusedWorkspace.id : 0
    readonly property var windows: focusedWorkspace && focusedWorkspace.toplevels ? focusedWorkspace.toplevels.values : []
    readonly property bool hasWindows: windows.length > 0
    readonly property int maxTitleLength: 16

    onFocusedWorkspaceChanged: WindowActions.scheduleRefresh()

    function shortenTitle(title) {
        // Spread into code points so that emoji etc. are never cut in half.
        let characters = [...title];
        if (characters.length <= windowControls.maxTitleLength) {
            return title;
        }
        return characters.slice(0, windowControls.maxTitleLength).join("") + "…";
    }

    Flickable {
        anchors.fill: parent
        anchors.rightMargin: 5
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: windowPillsRow.implicitWidth
        contentHeight: height

        Row {
            id: windowPillsRow
            height: parent.height
            spacing: 6

            Repeater {
                model: windowControls.windows

                // A click focuses the window; a right click or a press and
                // hold (meant for touch) opens the window's actions.
                delegate: DropdownMenu {
                    id: windowPill

                    required property var modelData

                    readonly property string windowTitle: modelData.title ? modelData.title : (modelData.wayland ? modelData.wayland.title : "")
                    readonly property bool isFloating: modelData.lastIpcObject ? modelData.lastIpcObject.floating === true : false

                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 32
                    radius: 7
                    border.width: 1
                    border.color: modelData.activated ? AppConstants.accentColor : AppConstants.indicatorBorderColor
                    color: modelData.activated ? AppConstants.accentColor : windowPill.toggleMouseAreaContainsMouse || windowPill.menuVisible ? AppConstants.focusedBgColor : "transparent"

                    leftPadding: 8
                    // Room for the close button on the right.
                    rightPadding: windowPillCloseSeparator.width + windowPillCloseButton.width + windowPillCloseButton.anchors.rightMargin + 6
                    toggleText: windowControls.shortenTitle(windowPill.windowTitle)
                    toggleTextFont.pixelSize: 16

                    // The separator shows touch users where the window's own
                    // pressable area ends and the close button begins.
                    Separator {
                        id: windowPillCloseSeparator
                        anchors.right: windowPillCloseButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        thickness: 1
                        length: 20
                    }

                    // All of the pill right of the separator (inside its
                    // border) closes the window.
                    WindowActionButton {
                        id: windowPillCloseButton
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: windowPill.border.width
                        implicitWidth: 30
                        radius: windowPill.radius - windowPill.border.width
                        iconName: "xmark"
                        activeIconColor: AppConstants.dangerColor
                        action: () => {
                            windowPill.closeMenu();
                            WindowActions.closeWindow(windowPill.modelData);
                        }
                    }

                    toggleOnClick: false
                    handlesPressAndHold: true
                    // Their number changes with the windows, which would shift
                    // the keys of all the menus to their right.
                    showsHint: false

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            windowPill.toggleMenu();
                            return;
                        }
                        windowPill.closeMenu();
                        WindowActions.focusWindow(windowPill.modelData);
                    }
                    onPressAndHold: windowPill.openMenu()

                    menuWidth: 220
                    menuContent: [
                        DropdownMenuHeader {
                            text: "Move to workspace"
                        },
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 0
                            rowSpacing: 0

                            IconMenuItem {
                                enabled: windowControls.workspaceId > 1
                                opacity: enabled ? 1 : 0.5
                                iconNames: ["arrow-left"]
                                text: enabled ? `${windowControls.workspaceId - 1}` : ""
                                textPixelSize: 17
                                action: () => {
                                    windowPill.closeMenu();
                                    WindowActions.moveWindowToWorkspace(windowPill.modelData, windowControls.workspaceId - 1);
                                }
                            }
                            IconMenuItem {
                                iconNames: ["arrow-right"]
                                text: `${windowControls.workspaceId + 1}`
                                textPixelSize: 17
                                action: () => {
                                    windowPill.closeMenu();
                                    WindowActions.moveWindowToWorkspace(windowPill.modelData, windowControls.workspaceId + 1);
                                }
                            }
                        },
                        DropdownMenuHeader {
                            text: "Window"
                        },
                        // Tap-to-toggle, showing the current mode (like the
                        // theme toggle in PowerIndicator).
                        IconMenuItem {
                            iconNames: [windowPill.isFloating ? "window-restore" : "table-columns"]
                            text: windowPill.isFloating ? "floating" : "tiled"
                            textPixelSize: 17
                            action: () => WindowActions.toggleWindowFloating(windowPill.modelData)
                        },
                        IconMenuItem {
                            iconNames: ["camera"]
                            text: "screenshot"
                            textPixelSize: 17
                            action: () => {
                                windowPill.closeMenu();
                                Screenshots.captureWindow(windowPill.modelData);
                            }
                        }
                    ]
                }
            }
        }
    }
}
