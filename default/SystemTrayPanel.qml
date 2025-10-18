import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    color: "transparent"
    property int preferredWidth: SystemTray.items.values.length * 40

    RowLayout {
        anchors.centerIn: parent
        spacing: 5
        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                border.width: 1
                border.color: AppConstants.indicatorBorderColor
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 7
                color: "transparent"

                Image {
                    anchors.centerIn: parent
                    anchors.fill: parent
                    anchors.margins: 5
                    source: modelData.icon
                    sourceSize.width: this.width
                    sourceSize.height: this.height
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: clickEvent => {
                        let globalCoords = mapToGlobal(clickEvent.x, clickEvent.y);
                        modelData.display(mainPanelWindow, globalCoords.x, globalCoords.y);
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
