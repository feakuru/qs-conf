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
    property var defaultLeftModel: [
        {"text": "Esc", "key": 1}, {"text": "1", "key": 2}, {"text": "2", "key": 3}, {"text": "3", "key": 4}, {"text": "4", "key": 5}, {"text": "5", "key": 6},
        {"text": "", "key": null}, {"text": "q", "key": 16}, {"text": "w", "key": 17}, {"text": "e", "key": 18}, {"text": "r", "key": 19}, {"text": "t", "key": 20},
        {"text": "Esc", "key": 1}, {"text": "a", "key": 30}, {"text": "s", "key": 31}, {"text": "d", "key": 32}, {"text": "f", "key": 33}, {"text": "g", "key": 34},
        {"text": "", "key": null}, {"text": "z", "key": 44}, {"text": "x", "key": 45}, {"text": "c", "key": 46}, {"text": "v", "key": 47}, {"text": "b", "key": 48},
        null, null, null, null, {"text": "↵", "key": null}, {"text": "⌘", "key": null}
    ]
    property var defaultRightModel: [
        {"text": "6", "key": 7}, {"text": "7", "key": 8}, {"text": "8", "key": 9}, {"text": "9", "key": 10}, {"text": "0", "key": 11}, {"text": "", "key": null},
        {"text": "y", "key": 21}, {"text": "u", "key": 22}, {"text": "i", "key": 23}, {"text": "o", "key": 24}, {"text": "p", "key": 25}, {"text": "", "key": null},
        {"text": "h", "key": 35}, {"text": "j", "key": 36}, {"text": "k", "key": 37}, {"text": "l", "key": 38}, {"text": ";", "key": 39}, {"text": "", "key": null},
        {"text": "n", "key": 49}, {"text": "m", "key": 50}, {"text": ",", "key": 51}, {"text": ".", "key": 52}, {"text": "/", "key": 53}, {"text": "", "key": null},
        {"text": "⌫", "key": null}, {"text": "␣", "key": null}, null, null, null, null
    ]

    Component.onCompleted: {
        if (oskLeftModel.length === 0) oskLeftModel = defaultLeftModel;
        if (oskRightModel.length === 0) oskRightModel = defaultRightModel;
        if (typeof oskConfigProcess !== 'undefined') oskConfigProcess.running = true;
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

        GridLayout {
            id: oskLeftBody
            columns: 6
            Repeater {
                model: oskLeftModel
                delegate: Rectangle {
                    // allow model entries to be null (meaning no button)
                    property bool hasButton: modelData !== null && typeof modelData === "object"
                    color: hasButton ? AppConstants.solidBgColor : "transparent"
                    radius: 3
                    border.width: hasButton ? 2 : 0
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64

                    StyledText {
                        visible: hasButton && modelData.text !== undefined
                        text: hasButton ? modelData.text : ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: hasButton && modelData.key !== null && modelData.key !== undefined
                        onClicked: () => {
                            if (!enabled) {
                                console.log("no key");
                                return;
                            }
                            console.log("clicked", JSON.stringify(modelData));
                            Quickshell.execDetached(["ydotool", "key", `${modelData.key}:1`, `${modelData.key}:0`]);
                        }
                    }
                }
            }
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

        GridLayout {
            id: oskRightBody
            columns: 6
            Repeater {
                model: oskRightModel
                delegate: Rectangle {
                    property bool hasButton: modelData !== null && typeof modelData === "object"
                    color: hasButton ? AppConstants.solidBgColor : "transparent"
                    radius: 3
                    border.width: hasButton ? 2 : 0
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    opacity: hasButton ? 1 : 0
                    enabled: hasButton

                    StyledText {
                        visible: hasButton && modelData.text !== undefined
                        text: hasButton ? modelData.text : ""
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: hasButton && modelData.key !== null && modelData.key !== undefined
                        acceptedButtons: hasButton ? Qt.AllButtons : Qt.NoButton
                        onClicked: (event) => {
                            if (!enabled) {
                                console.log("no key");
                                return;
                            }
                            event.accepted = true;
                            console.log("clicked", JSON.stringify(modelData));
                            Quickshell.execDetached(["ydotool", "key", `${modelData.key}:1`, `${modelData.key}:0`]);
                        }
                    }
                }
            }
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

    Timer {
        id: oskReloadTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: function () { oskConfigProcess.running = true; }
    }
}
