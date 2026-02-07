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
        if (typeof oskConfigProcess !== 'undefined') oskConfigProcess.running = true;
        if (typeof oskInputProcess !== 'undefined') oskInputProcess.running = true;
    }

    PanelWindow {
        id: oskWindow
        color: "transparent"
        visible: false
        screen: Quickshell.screens[0]
        aboveWindows: true
        anchors {
            left: true
            right: true
        }
        margins {
            left: 10
            right: 10
            top: parseInt(screen.height / 2)
        }
        property string layerName: "main"

        implicitHeight: Math.max(oskLeftBody.height, oskRightBody.height)

        Item {
            id: leftRegion
            anchors.left: parent.left
            x: 0
            width: oskLeftBody.width
            height: parent.height

            KeyGrid {
                id: oskLeftBody
                model: oskLeftModel
                onLayerSwitched: layerName => {
                    oskWindow.layerName = layerName;
                    console.log(layerName);
                }
            }
        }

        Item {
            id: rightRegion
            anchors.right: parent.right
            width: oskRightBody.width
            x: parent.width - width
            height: parent.height

            KeyGrid {
                id: oskRightBody
                model: oskRightModel
                onLayerSwitched: layerName => {
                    oskWindow.layerName = layerName;
                }
            }
        }

        Item {
            id: oskGap
            x: leftRegion.width
            width: Math.max(0, rightRegion.x - leftRegion.width)
            height: parent.height
            enabled: false
            visible: false
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
                if (out.length === 0) return;
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

    // ScriptProcess {
    //     id: oskInputProcess
    //     scriptName: "osk_zmq_daemon"
    //     running: false
    // }

    Timer {
        id: oskReloadTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: function () { oskConfigProcess.running = true }
    }
}
