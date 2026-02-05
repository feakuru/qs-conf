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

    MouseArea {
        id: oskToggleMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouseEvent => {
            oskLeft.visible = !oskLeft.visible;
            oskRight.visible = !oskRight.visible;
        }
    }

    property var oskLeftModel: []
    property var oskRightModel: []

    Component.onCompleted: {
        if (typeof oskConfigProcess !== 'undefined') oskConfigProcess.running = true;
        if (typeof oskInputProcess !== 'undefined') oskInputProcess.running = true;
    }

    PanelWindow {
        id: oskLeft
        color: "transparent"
        visible: false
        screen: Quickshell.screens[0]
        anchors {
            left: true
            top: true
        }
        margins {
            left: 10
            top: parseInt(screen.height / 2)
        }
        implicitWidth: oskLeftBody.width
        implicitHeight: oskLeftBody.height

        KeyGrid {
            id: oskLeftBody
            model: oskLeftModel
        }
    }

    PanelWindow {
        id: oskRight
        color: "transparent"
        visible: false
        screen: Quickshell.screens[0]
        anchors {
            right: true
            top: true
        }
        margins {
            right: 10
            top: parseInt(screen.height / 2)
        }
        implicitWidth: oskRightBody.width
        implicitHeight: oskRightBody.height

        KeyGrid {
            id: oskRightBody
            model: oskRightModel
        }
    }

    ScriptProcess {
        id: oskConfigProcess
        scriptName: "osk_layout"
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

    ScriptProcess {
        id: oskInputProcess
        scriptName: "osk_zmq_daemon"
        running: false
    }

    Timer {
        id: oskReloadTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: function () { oskConfigProcess.running = true }
    }
}
