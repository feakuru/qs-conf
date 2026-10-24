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

                delegate: Rectangle {
                    id: windowPill

                    required property var modelData

                    readonly property string windowTitle: modelData.title ? modelData.title : (modelData.wayland ? modelData.wayland.title : "")
                    readonly property bool isFloating: modelData.lastIpcObject ? modelData.lastIpcObject.floating === true : false

                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: windowPillLayout.implicitWidth + windowPillLayout.anchors.leftMargin + windowPillLayout.anchors.rightMargin
                    implicitHeight: 32
                    radius: 7
                    border.width: 1
                    border.color: modelData.activated ? AppConstants.accentColor : AppConstants.indicatorBorderColor
                    color: modelData.activated ? AppConstants.accentColor : windowTitleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

                    RowLayout {
                        id: windowPillLayout
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        spacing: 0

                        StyledText {
                            anchors.centerIn: undefined
                            Layout.fillHeight: true
                            Layout.rightMargin: 4
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignLeft
                            text: windowControls.shortenTitle(windowPill.windowTitle)

                            MouseArea {
                                id: windowTitleMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WindowActions.focusWindow(windowPill.modelData)
                            }
                        }

                        WindowActionButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            iconName: "arrow-left"
                            enabledAction: windowControls.workspaceId > 1
                            action: () => WindowActions.moveWindowToWorkspace(windowPill.modelData, windowControls.workspaceId - 1)
                        }

                        WindowActionButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            iconName: "arrow-right"
                            action: () => WindowActions.moveWindowToWorkspace(windowPill.modelData, windowControls.workspaceId + 1)
                        }

                        WindowActionButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            iconName: "window-restore"
                            highlighted: windowPill.isFloating
                            action: () => WindowActions.toggleWindowFloating(windowPill.modelData)
                        }

                        WindowActionButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            iconName: "xmark"
                            activeIconColor: AppConstants.dangerColor
                            action: () => WindowActions.closeWindow(windowPill.modelData)
                        }
                    }
                }
            }
        }
    }
}
