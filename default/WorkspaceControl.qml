import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Rectangle {
    color: "transparent"

    property real preferredWidth: {
        let result = 0;
        for (let ws of Hyprland.workspaces.values) {
            result += 54;
            for (let tl of ws.toplevels.values) {
                result += 24;
            }
        }
        result
    }

    RowLayout {
        spacing: 5
        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                Layout.preferredWidth: this.childrenRect.width
                Layout.preferredHeight: 32
                Layout.margins: 5
                border.width: 3
                border.color: AppConstants.accentColor
                color: modelData.focused ? AppConstants.accentColor : wsMouseArea.containsMouse ? AppConstants.bgColor : "transparent"
                radius: 7

                MouseArea {
                    id: wsMouseArea
                    width: childrenRect.width
                    height: childrenRect.height
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    onClicked: {
                        Hyprland.dispatch(`workspace ${modelData.id}`);
                    }
                    Row {
                        Rectangle {
                            width: wsIdText.width + 22
                            height: wsIdText.height
                            color: "transparent"

                            StyledText {
                                id: wsIdText
                                text: `${modelData.id}`
                            }
                        }

                        Repeater {
                            model: [...new Set(modelData.toplevels.values.filter(item => item.wayland != null).map(item => item.wayland.appId))]
                            delegate: Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                source: `image://icon/${modelData}`
                                mipmap: true
                            }
                        }
                        Rectangle {
                            color: "transparent"
                            visible: modelData.toplevels.values.length > 0
                            width: 4
                            height: 10
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onWheel: wheelEvent => {
            // because inconsistency has been observed
            let delta = wheelEvent.angleDelta.x ? wheelEvent.angleDelta.x : wheelEvent.angleDelta.y;
            if (delta > 0) {
                Hyprland.dispatch("workspace -1");
            } else if (delta < 0) {
                Hyprland.dispatch("workspace +1");
            }
        }
    }
}
