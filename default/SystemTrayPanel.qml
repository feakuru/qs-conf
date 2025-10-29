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
        spacing: 5
        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                border.width: 1
                border.color: AppConstants.indicatorBorderColor
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 5
                color: iconMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

                IconImage {
                    anchors.centerIn: parent
                    anchors.fill: parent
                    anchors.margins: 5
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
