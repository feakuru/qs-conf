import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: trayPanel
    color: "transparent"
    property int preferredWidth: SystemTray.items.values.length * 40
    required property var trayMenuDisplayParent

    RowLayout {
        anchors.centerIn: parent
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                border.width: 1
                border.color: AppConstants.indicatorBorderColor
                Layout.preferredWidth: 40
                Layout.fillHeight: true
                color: iconMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

                IconImage {
                    anchors.centerIn: parent
                    anchors.margins: 5
                    width: 24
                    height: 24
                    source: {
                        modelData.icon
                    }
                    mipmap: true
                }

                MouseArea {
                    id: iconMouseArea
                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked: clickEvent => {
                        let globalCoords = mapToGlobal(clickEvent.x, clickEvent.y);
                        modelData.display(trayPanel.trayMenuDisplayParent, globalCoords.x, globalCoords.y);
                    }
                    onDoubleClicked: clickEvent => {
                        modelData.activate();
                    }
                    onWheel: wheelEvent => modelData.scroll(wheelEvent.angleDelta.y)
                }
            }
        }
    }
}
