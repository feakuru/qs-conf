import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    color: oskToggleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real preferredWidth: oskIcon.iconWidth + 20

    RecoloredIcon {
        id: oskIcon
        anchors.centerIn: parent
        iconWidth: 26
        iconHeight: 26
        source: Qt.resolvedUrl(`assets/icons/fontawesome/solid/keyboard.svg`)
        iconColor: "lightgray"
    }

    IpcHandler {
        target: "osk"

        function toggle(): void {
            oskWindow.visible = !oskWindow.visible;
        }
    }

    MouseArea {
        id: oskToggleMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouseEvent => {
            oskWindow.visible = !oskWindow.visible;
        }
    }

    property var oskLeftModel: []
    property var oskRightModel: []

    Component.onCompleted: {
        if (typeof oskConfigProcess !== 'undefined')
            oskConfigProcess.running = true;
        if (typeof oskInputProcess !== 'undefined')
            oskInputProcess.running = true;
    }

    PanelWindow {
        id: oskWindow
        color: "transparent"
        visible: false
        screen: Quickshell.screens[0]
        aboveWindows: true
        anchors {
            left: true
            bottom: true
        }
        margins {
            left: 10
            right: 10
            top: 10
            bottom: 10
        }
        property string layerName: "main"

        implicitWidth: Quickshell.screens[0].width
        implicitHeight: Math.max(leftRegion.height, rightRegion.height)

        RowLayout {
            anchors.fill: parent
            Item {
                id: leftRegion
                width: oskLeftBody.rotatedWidth
                height: oskLeftBody.rotatedHeight
                Layout.fillHeight: true
                Layout.leftMargin: 50

                KeyGrid {
                    id: oskLeftBody
                    model: oskLeftModel
                    anchors.left: leftRegion.left
                    rotationAngle: 10
                    onLayerSwitched: layerName => {
                        oskWindow.layerName = layerName;
                        oskConfigProcess.running = true;
                    }
                }
            }

            Item {
                id: oskGap
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Item {
                id: rightRegion
                width: oskRightBody.rotatedWidth
                height: oskRightBody.rotatedHeight
                Layout.fillHeight: true

                KeyGrid {
                    id: oskRightBody
                    model: oskRightModel
                    isRightHalf: true
                    rotationAngle: -10

                    onLayerSwitched: layerName => {
                        oskWindow.layerName = layerName;
                        oskConfigProcess.running = true;
                    }
                }
            }
        }
    }

    ScriptProcess {
        id: oskConfigProcess
        scriptName: "osk_layout"
        scriptArgs: [oskWindow.layerName]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim();
                if (out.length === 0)
                    return;
                try {
                    var parsed = JSON.parse(out);
                    if (parsed.left && parsed.left instanceof Array && parsed.left.length > 0) {
                        oskLeftModel = parsed.left;
                    }
                    if (parsed.right && parsed.right instanceof Array && parsed.right.length > 0) {
                        oskRightModel = parsed.right;
                    }
                } catch (e) {
                    console.log("Failed to parse osk_layout output:", e);
                }
            }
        }
    }

    Timer {
        id: oskReloadTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: function () {
            oskConfigProcess.running = true;
        }
    }
}
