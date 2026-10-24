import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: trayPanel
    readonly property bool hasItems: SystemTray.items.values.length > 0

    implicitWidth: trayRow.implicitWidth
    Layout.fillHeight: true

    Row {
        id: trayRow
        height: parent.height

        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                implicitWidth: 40
                height: trayRow.height
                color: iconMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

                IconImage {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: modelData.icon
                    mipmap: true
                }

                MouseArea {
                    id: iconMouseArea
                    acceptedButtons: Qt.AllButtons
                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked: clickEvent => {
                        if (!modelData.hasMenu) {
                            modelData.activate();
                            return;
                        }
                        // Menus are positioned relative to the bar window.
                        let windowPosition = iconMouseArea.mapToItem(null, clickEvent.x, clickEvent.y);
                        modelData.display(trayPanel.QsWindow.window, windowPosition.x, windowPosition.y);
                    }
                    onDoubleClicked: clickEvent => {
                        modelData.secondaryActivate();
                    }
                    onWheel: wheelEvent => modelData.scroll(wheelEvent.angleDelta.y, wheelEvent.angleDelta.x)
                }
            }
        }
    }
}
