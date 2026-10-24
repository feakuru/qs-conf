import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: wsControlContainer
    implicitWidth: wsControlRow.implicitWidth
    Layout.fillHeight: true

    property var currentWorkspaces: {
        let workspaces = new Array();
        let firstWs = Hyprland.workspaces.values[0];
        // Hyprland hasn't reported any workspaces yet (e.g. right at startup).
        if (!firstWs) {
            return workspaces;
        }
        if (firstWs.id > 1) {
            for (let idx = 1; idx < firstWs.id; idx++) {
                workspaces.push({
                    id: idx,
                    toplevels: {
                        values: []
                    }
                });
            }
        }
        for (let idx = 0; idx < Hyprland.workspaces.values.length; idx++) {
            if (idx > 0 && Hyprland.workspaces.values[idx].id > Hyprland.workspaces.values[idx - 1].id + 1) {
                for (let subid = Hyprland.workspaces.values[idx - 1].id + 1; subid < Hyprland.workspaces.values[idx].id; subid++) {
                    workspaces.push({
                        id: subid,
                        toplevels: {
                            values: []
                        }
                    });
                }
            }
            workspaces.push(Hyprland.workspaces.values[idx]);
        }
        return workspaces;
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: wheelEvent => {
            // because inconsistency has been observed
            let delta = wheelEvent.angleDelta.x ? wheelEvent.angleDelta.x : wheelEvent.angleDelta.y;
            if (delta > 0) {
                Hyprland.dispatch("hl.dsp.focus({ workspace = \"-1\" })");
            } else if (delta < 0) {
                Hyprland.dispatch("hl.dsp.focus({ workspace = \"+1\" })");
            }
        }
    }

    RowLayout {
        id: wsControlRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            model: wsControlContainer.currentWorkspaces
            delegate: Rectangle {
                implicitWidth: wsPillContent.implicitWidth
                implicitHeight: 32
                Layout.margins: 5
                border.width: 3
                border.color: AppConstants.accentColor
                color: modelData.focused ? AppConstants.accentColor : wsMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
                radius: 7

                Row {
                    id: wsPillContent
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: modelData.toplevels.values.length > 0 ? 4 : 0

                    StyledText {
                        anchors.centerIn: undefined
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 11
                        rightPadding: 11
                        text: `${modelData.id}`
                    }

                    Repeater {
                        model: [...new Set(modelData.toplevels.values.filter(item => item.wayland != null).map(item => item.wayland.appId.toLowerCase()))]
                        delegate: Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            source: Quickshell.iconPath(modelData.toLowerCase(), "application-x-executable")
                            mipmap: true
                        }
                    }
                }

                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${modelData.id}" })`);
                    }
                }
            }
        }

        Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            Layout.margins: 2
            border.width: 3
            border.color: AppConstants.accentColor
            color: addWsMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
            radius: 9

            StyledText {
                font.pixelSize: 16
                text: "+"
            }

            MouseArea {
                id: addWsMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Hyprland.dispatch("hl.dsp.focus({ workspace = \"emptyn\" })");
                }
            }
        }
    }
}
