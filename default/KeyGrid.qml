import QtQuick
import QtQuick.Layouts
import Quickshell
import QtMultimedia

RowLayout {
    id: keyGrid
    property var model: []
    spacing: 6

    property var expectedRows: 5
    property var expectedCols: 6
    property real rotationAngle: 10
    property bool isRightHalf: false
    property bool isShiftDown: false

    transform: Rotation {
        angle: rotationAngle
        origin.x: width / 2
        origin.y: height / 2
    }
    property real rotatedWidth: Math.abs(width * Math.cos(rotationAngle * Math.PI / 180)) + Math.abs(height * Math.sin(rotationAngle * Math.PI / 180))
    property real rotatedHeight: Math.abs(width * Math.sin(rotationAngle * Math.PI / 180)) + Math.abs(height * Math.cos(rotationAngle * Math.PI / 180)) - 30

    signal layerSwitched(layerName: string)

    SoundEffect {
        id: shortPressSound
        source: Qt.resolvedUrl("assets/sounds/osk_short_press.wav")
    }

    SoundEffect {
        id: longStartSound
        source: Qt.resolvedUrl("assets/sounds/osk_long_start.wav")
    }

    SoundEffect {
        id: longEndSound
        source: Qt.resolvedUrl("assets/sounds/osk_long_end.wav")
    }

    SoundEffect {
        id: layerSwitchStartSound
        source: Qt.resolvedUrl("assets/sounds/osk_layer_switch.wav")
    }

    Repeater {
        model: keyGrid.expectedCols
        delegate: ColumnLayout {
            id: keyCol
            spacing: 6
            property int realModelColIndex: index
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

            Rectangle {
                width: 30
                height: {
                    switch (keyGrid.isRightHalf ? (keyGrid.expectedCols - 1 - realModelColIndex) : realModelColIndex) {
                    case 0:
                    case 1:
                    case 5:
                        return 32;
                    case 2:
                    case 4:
                        return 16;
                    case 3:
                        return 0;
                    }
                }
                color: "transparent"
            }

            Repeater {
                model: keyGrid.expectedRows
                delegate: Rectangle {
                    property int realModelRowIndex: index
                    property var cell: {
                        if (keyGrid.model && keyGrid.model.length > realModelRowIndex && keyGrid.model[realModelRowIndex] && keyGrid.model[realModelRowIndex].length > realModelColIndex) {
                            return keyGrid.model[realModelRowIndex][keyCol.realModelColIndex];
                        }
                        return null;
                    }
                    property bool hasButton: cell !== null && typeof cell === "object"
                    color: hasButton ? AppConstants.solidBgColor : "transparent"
                    radius: 3
                    border.width: hasButton ? 2 : 0
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    opacity: hasButton ? 1 : 0
                    enabled: hasButton

                    ColumnLayout {
                        id: btnCol
                        anchors.fill: parent
                        spacing: 2
                        property string labelText: (cell && cell.label) ? cell.label : ""
                        Text {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                            visible: hasButton && btnCol.labelText !== ""
                            text: (visible && hasButton) ? btnCol.labelText : ""
                            font.pixelSize: 20
                            font.family: AppConstants.defaultFont
                            font.bold: true
                            color: AppConstants.styledTextColor
                            opacity: 0.8
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            property string heldText: {
                                if (cell) {
                                    if (cell.layer_switch) {
                                        return cell.layer_switch;
                                    }
                                    if (cell.keycodes_held) {
                                        if (cell.keycodes_held.length != cell.keycodes_pressed.length) {
                                            return cell.keys_held.join(" ");
                                        }
                                        for (var i = 0; i < cell.keycodes_held.length; ++i) {
                                            if (cell.keycodes_held[i] != cell.keycodes_pressed[i]) {
                                                return cell.keys_held.join(" ");
                                            }
                                        }
                                    }
                                }
                                return "";
                            }
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                            visible: heldText !== "" && hasButton
                            text: heldText.replace(/^RIGHT/, '').replace(/^LEFT/, '')
                            font.pixelSize: 16
                            font.family: AppConstants.defaultFont
                            color: AppConstants.styledTextColor
                            opacity: 0.8
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // Touch-friendly behaviour: use MultiPointTouchArea so multiple keys
                    // can be pressed simultaneously (important for multitouch tablets).
                    MultiPointTouchArea {
                        id: btnTouchArea
                        anchors.fill: parent

                        property var keycodesPressed: (cell && cell.keycodes_pressed) ? cell.keycodes_pressed : []
                        property var keycodesHeld: (cell && cell.keycodes_held) ? cell.keycodes_held : []
                        property var layerSwitch: (cell && cell.layer_switch) ? cell.layer_switch : null

                        property bool longHeld: false
                        property var currentlyHeldKeycodes: null
                        property int activePointId: -1

                        Timer {
                            id: holdTimer
                            interval: 200
                            repeat: false
                            onTriggered: {
                                btnTouchArea.longHeld = true;
                                var codesHeld = btnTouchArea.keycodesHeld;
                                if (btnTouchArea.layerSwitch) {
                                    keyGrid.layerSwitched(btnTouchArea.layerSwitch);
                                    layerSwitchStartSound.play();
                                } else if (codesHeld) {
                                    btnTouchArea.currentlyHeldKeycodes = codesHeld;
                                    if (cell.keys_held.includes("LEFTSHIFT") || cell.keys_held.includes("RIGHTSHIFT")) {
                                        keyGrid.isShiftDown = true;
                                    }
                                    Quickshell.execDetached({
                                        command: ["sh", "-c", "uv run python " + Qt.resolvedUrl("scripts/osk_zmq_client.py").toString().replace(/^file:\/{2}/, "") + " --event long_start --codes " + btnTouchArea.currentlyHeldKeycodes.join(",")],
                                        workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
                                    });
                                    longStartSound.play();
                                }
                            }
                        }

                        onPressed: function (points) {
                            if (!hasButton)
                                return;
                            if (!points || points.length === 0)
                                return;
                            var p = points[0];
                            p.accepted = true;

                            if (btnTouchArea.activePointId === -1) {
                                btnTouchArea.longHeld = false;
                                btnTouchArea.currentlyHeldKeycodes = null;
                                btnTouchArea.activePointId = p.pointId;
                                holdTimer.start();
                            }
                        }

                        onReleased: function (points) {
                            if (!hasButton)
                                return;
                            if (!points || points.length === 0)
                                return;

                            var match = null;
                            for (var i = 0; i < points.length; ++i) {
                                var rp = points[i];
                                if (btnTouchArea.activePointId === -1 || rp.pointId === btnTouchArea.activePointId) {
                                    match = rp;
                                    break;
                                }
                            }
                            if (!match)
                                return;

                            holdTimer.stop();
                            if (btnTouchArea.longHeld) {
                                if (btnTouchArea.currentlyHeldKeycodes && btnTouchArea.currentlyHeldKeycodes.length) {
                                    if (cell.keys_held.includes("LEFTSHIFT") || cell.keys_held.includes("RIGHTSHIFT")) {
                                        keyGrid.isShiftDown = false;
                                    }
                                    Quickshell.execDetached({
                                        command: ["sh", "-c", "uv run python " + Qt.resolvedUrl("scripts/osk_zmq_client.py").toString().replace(/^file:\/{2}/, "") + " --event long_end --codes " + btnTouchArea.currentlyHeldKeycodes.join(",")],
                                        workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
                                    });
                                    longEndSound.play();
                                } else if (btnTouchArea.layerSwitch) {
                                    keyGrid.layerSwitched("main");
                                    layerSwitchStartSound.play();
                                }
                                btnTouchArea.longHeld = false;
                                btnTouchArea.currentlyHeldKeycodes = null;
                            } else {
                                var codes = btnTouchArea.keycodesPressed;
                                if (codes) {
                                    Quickshell.execDetached({
                                        command: ["sh", "-c", "uv run python " + Qt.resolvedUrl("scripts/osk_zmq_client.py").toString().replace(/^file:\/{2}/, "") + " --event short_press --codes " + codes.join(",")],
                                        workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
                                    });
                                    shortPressSound.play();
                                }
                            }
                            btnTouchArea.activePointId = -1;
                        }

                        onCanceled: function (points) {
                            onReleased(points);
                        }
                    }
                }
            }
        }
    }
}
