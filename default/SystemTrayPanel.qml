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

    RowLayout {
        id: trayRow
        height: parent.height
        spacing: 0

        Repeater {
            model: SystemTray.items
            delegate: RowLayout {
                id: trayItem
                required property var modelData
                required property int index

                Layout.fillHeight: true
                spacing: 0

                Separator {
                    visible: trayItem.index > 0
                }

                Rectangle {
                    implicitWidth: 40
                    Layout.fillHeight: true
                    color: iconMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"

                    IconImage {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: trayItem.modelData.icon
                        mipmap: true
                    }

                    MouseArea {
                        id: iconMouseArea
                        acceptedButtons: Qt.AllButtons
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: clickEvent => {
                            if (!trayItem.modelData.hasMenu) {
                                trayItem.modelData.activate();
                                return;
                            }
                            // Menus are positioned relative to the bar window.
                            let windowPosition = iconMouseArea.mapToItem(null, clickEvent.x, clickEvent.y);
                            trayItem.modelData.display(trayPanel.QsWindow.window, windowPosition.x, windowPosition.y);
                        }
                        onDoubleClicked: clickEvent => {
                            trayItem.modelData.secondaryActivate();
                        }
                        onWheel: wheelEvent => trayItem.modelData.scroll(wheelEvent.angleDelta.y, wheelEvent.angleDelta.x)
                    }
                }
            }
        }
    }
}
