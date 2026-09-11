import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: windowMenu

    // The HyprlandWorkspace whose windows are being managed.
    property var workspace: null
    // Position of the widget the menu is anchored under, in screen coordinates.
    property real anchorX: 0
    property real anchorWidth: 0

    readonly property var windows: workspace && workspace.toplevels ? workspace.toplevels.values : []
    readonly property int workspaceId: workspace ? workspace.id : 0

    // Hyprland reports addresses with and without the 0x prefix depending on the
    // source, but dispatchers always expect it.
    function hyprlandAddress(toplevel) {
        let address = toplevel && toplevel.address ? toplevel.address : "";
        if (address === "") {
            return "";
        }
        return address.startsWith("0x") ? address : `0x${address}`;
    }

    function moveWindowBy(toplevel, workspaceDelta) {
        let targetWorkspace = windowMenu.workspaceId + workspaceDelta;
        let address = windowMenu.hyprlandAddress(toplevel);
        if (targetWorkspace < 1 || address === "") {
            return;
        }
        // follow = false keeps the focus on the current workspace instead of
        // dragging the user along with the window.
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${targetWorkspace}, window = "address:${address}", follow = false })`);
        refreshDelay.restart();
    }

    function toggleWindowFloating(toplevel) {
        let address = windowMenu.hyprlandAddress(toplevel);
        if (address === "") {
            return;
        }
        Hyprland.dispatch(`hl.dsp.window.float({ action = "toggle", window = "address:${address}" })`);
        refreshDelay.restart();
    }

    function closeWindow(toplevel) {
        if (toplevel.wayland) {
            toplevel.wayland.close();
        } else {
            let address = windowMenu.hyprlandAddress(toplevel);
            if (address === "") {
                return;
            }
            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${address}" })`);
        }
        refreshDelay.restart();
    }

    function focusWindow(toplevel) {
        if (toplevel.wayland) {
            toplevel.wayland.activate();
        }
    }

    function toggleFor(targetWorkspace, x, width) {
        let sameWorkspace = windowMenu.workspace && targetWorkspace && windowMenu.workspace.id === targetWorkspace.id;
        if (windowMenu.visible && sameWorkspace) {
            windowMenu.visible = false;
            return;
        }
        if (!targetWorkspace || !targetWorkspace.toplevels || targetWorkspace.toplevels.values.length === 0) {
            windowMenu.visible = false;
            return;
        }
        windowMenu.workspace = targetWorkspace;
        windowMenu.anchorX = x;
        windowMenu.anchorWidth = width;
        Hyprland.refreshToplevels();
        windowMenu.visible = true;
    }

    onWindowsChanged: {
        if (windowMenu.visible && windowMenu.windows.length === 0) {
            windowMenu.visible = false;
        }
    }

    visible: false
    // Deliberately not focusable: taking keyboard focus would change which
    // window Hyprland considers active while the menu is being used.
    color: AppConstants.solidBgColor

    anchors {
        top: true
        left: true
    }

    margins {
        left: {
            let foundScreen = Quickshell.screens.find(s => s.name == "DP-1") || Quickshell.screens[0];
            let centerOfAnchor = windowMenu.anchorX + (windowMenu.anchorWidth / 2);
            let targetPosition = centerOfAnchor - (windowMenu.implicitWidth / 2);
            let rightmostPosition = foundScreen.width - windowMenu.implicitWidth - 10;
            parseInt(Math.min(rightmostPosition, Math.max(targetPosition, 10)));
        }
    }

    implicitWidth: 520
    implicitHeight: windowMenuBody.implicitHeight

    Timer {
        id: refreshDelay
        interval: 120
        repeat: false
        onTriggered: Hyprland.refreshToplevels()
    }

    MouseArea {
        id: windowMenuArea
        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: true
        onEntered: {
            windowMenu.visible = Qt.binding(() => {
                if (windowMenuArea.containsMouse) {
                    return true;
                }
                windowMenu.visible = false;
                return false;
            });
        }

        ColumnLayout {
            id: windowMenuBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                color: AppConstants.accentColor

                StyledText {
                    anchors.centerIn: undefined
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    text: `Workspace ${windowMenu.workspaceId} — ${windowMenu.windows.length} window${windowMenu.windows.length === 1 ? "" : "s"}`
                }
            }

            Repeater {
                model: windowMenu.windows

                delegate: Rectangle {
                    id: windowRow

                    required property var modelData

                    readonly property string appId: modelData.wayland ? modelData.wayland.appId : ""
                    readonly property string windowTitle: modelData.title ? modelData.title : (modelData.wayland ? modelData.wayland.title : "")
                    readonly property bool isFloating: modelData.lastIpcObject ? modelData.lastIpcObject.floating === true : false

                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    color: windowRowMouseArea.containsMouse ? AppConstants.focusedSolidBgColor : "transparent"
                    border.width: 1
                    border.color: AppConstants.indicatorBorderColor

                    MouseArea {
                        id: windowRowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            windowMenu.focusWindow(windowRow.modelData);
                            windowMenu.visible = false;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            Image {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignVCenter
                                source: Quickshell.iconPath(windowRow.appId.toLowerCase(), "application-x-executable")
                                mipmap: true
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.leftMargin: 6
                                anchors.centerIn: undefined
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                color: windowRow.modelData.activated ? AppConstants.indicatorOnColor : AppConstants.styledTextColor
                                text: windowRow.windowTitle
                            }

                            WindowActionButton {
                                iconName: "arrow-left"
                                enabledAction: windowMenu.workspaceId > 1
                                action: () => windowMenu.moveWindowBy(windowRow.modelData, -1)
                            }

                            WindowActionButton {
                                iconName: "arrow-right"
                                action: () => windowMenu.moveWindowBy(windowRow.modelData, 1)
                            }

                            WindowActionButton {
                                iconName: "window-restore"
                                highlighted: windowRow.isFloating
                                action: () => windowMenu.toggleWindowFloating(windowRow.modelData)
                            }

                            WindowActionButton {
                                iconName: "xmark"
                                activeIconColor: AppConstants.dangerColor
                                action: () => windowMenu.closeWindow(windowRow.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
