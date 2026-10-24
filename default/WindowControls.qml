import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: windowControls
    color: "transparent"
    visible: windows.length > 0

    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int workspaceId: focusedWorkspace ? focusedWorkspace.id : 0
    readonly property var windows: focusedWorkspace && focusedWorkspace.toplevels ? focusedWorkspace.toplevels.values : []
    readonly property int maxTitleLength: 16
    property real preferredWidth: windowControlsSeparator.width + windowControlsSeparator.Layout.leftMargin + windowControlsSeparator.Layout.rightMargin + windowPillsRow.width + 5

    onFocusedWorkspaceChanged: WindowActions.scheduleRefresh()

    function shortenTitle(title) {
        // Spread into code points so that emoji etc. are never cut in half.
        let characters = [...title];
        if (characters.length <= windowControls.maxTitleLength) {
            return title;
        }
        return characters.slice(0, windowControls.maxTitleLength).join("") + "…";
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: windowControlsSeparator
            Layout.preferredWidth: 2
            Layout.preferredHeight: 26
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.alignment: Qt.AlignVCenter
            radius: 1
            color: AppConstants.indicatorBorderColor
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 5
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: windowPillsRow.width
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
                        width: windowPillLayout.implicitWidth + 12
                        height: 32
                        radius: 7
                        border.width: 1
                        border.color: modelData.activated ? AppConstants.accentColor : AppConstants.indicatorBorderColor
                        color: modelData.activated ? AppConstants.accentColor : windowTitleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

                        RowLayout {
                            id: windowPillLayout
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 0

                            Item {
                                Layout.preferredWidth: windowTitleText.implicitWidth
                                Layout.preferredHeight: 28
                                Layout.rightMargin: 4

                                StyledText {
                                    id: windowTitleText
                                    anchors.centerIn: undefined
                                    anchors.fill: parent
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignLeft
                                    text: windowControls.shortenTitle(windowPill.windowTitle)
                                }

                                MouseArea {
                                    id: windowTitleMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WindowActions.focusWindow(windowPill.modelData)
                                }
                            }

                            WindowActionButton {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                iconName: "arrow-left"
                                enabledAction: windowControls.workspaceId > 1
                                action: () => WindowActions.moveWindowToWorkspace(windowPill.modelData, windowControls.workspaceId - 1)
                            }

                            WindowActionButton {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                iconName: "arrow-right"
                                action: () => WindowActions.moveWindowToWorkspace(windowPill.modelData, windowControls.workspaceId + 1)
                            }

                            WindowActionButton {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                iconName: "window-restore"
                                highlighted: windowPill.isFloating
                                action: () => WindowActions.toggleWindowFloating(windowPill.modelData)
                            }

                            WindowActionButton {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
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
}
