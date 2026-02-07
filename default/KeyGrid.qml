import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: keyGrid
    property var model: []
    spacing: 6

    property var expectedRows: 5
    property var expectedCols: 6

    signal layerSwitched(layerName: string)

    Repeater {
        id: rowRepeater
        model: keyGrid.expectedRows
        delegate: RowLayout {
            id: repeatedRow
            spacing: 6
            property int realModelRowIndex: index

            Repeater {
                model: keyGrid.expectedCols
                delegate: Rectangle {
                    property int realModelColIndex: index
                    property var cell: {
                        if (keyGrid.model
                                && keyGrid.model.length > repeatedRow.realModelRowIndex
                                && keyGrid.model[repeatedRow.realModelRowIndex]
                                && keyGrid.model[repeatedRow.realModelRowIndex].length > realModelColIndex) {
                                    // console.log(JSON.stringify(keyGrid.model[repeatedRow.realModelRowIndex][realModelColIndex]));
                            return keyGrid.model[repeatedRow.realModelRowIndex][realModelColIndex];
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
                            font.pixelSize: 16
                            font.family: AppConstants.defaultFont
                            color: AppConstants.styledTextColor
                            opacity: 0.8
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            property string heldText: {
                                if (cell) {
                                    if (cell.key_held) {
                                        return cell.key_held;
                                    } else if (cell.layer_switch) {
                                        return cell.layer_switch;
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

                        property var primaryKeyCode: (cell && cell.keycode_pressed) ? cell.keycode_pressed : null
                        property var heldKeyCodeProp: (cell && cell.keycode_held) ? cell.keycode_held : null
                        property var layerSwitch: (cell && cell.layer_switch) ? cell.layer_switch : null
                        property bool hasPrimaryKey: primaryKeyCode !== null && primaryKeyCode !== undefined

                        property bool longHeld: false
                        property int heldKeyCode: -1
                        property int activePointId: -1

                        Timer {
                            id: holdTimer
                            interval: 200
                            repeat: false
                            onTriggered: {
                                btnTouchArea.longHeld = true
                                var codeHeld = btnTouchArea.heldKeyCodeProp
                                if (codeHeld !== null && codeHeld !== undefined) {
                                    btnTouchArea.heldKeyCode = codeHeld;
                                    Quickshell.execDetached({
                                        command: [
                                            "sh",
                                            "-c",
                                            "uv run python " + 
                                            Qt.resolvedUrl("scripts/osk_zmq_client.py").toString().replace(/^file:\/{2}/, "")
                                            + " --event long_start --code "
                                            + String(btnTouchArea.heldKeyCode)
                                        ],
                                        workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
                                    });
                                } else if (btnTouchArea.layerSwitch) {
                                    keyGrid.layerSwitched(btnTouchArea.layerSwitch);
                                }
                            }
                        }

                        onPressed: function(points) {
                            if (!hasButton) return;
                            if (!points || points.length === 0) return;
                            var p = points[0];
                            p.accepted = true;

                            if (btnTouchArea.activePointId === -1) {
                                btnTouchArea.longHeld = false;
                                btnTouchArea.heldKeyCode = -1;
                                btnTouchArea.activePointId = p.pointId;
                                holdTimer.start();
                            }
                        }

                        onReleased: function(points) {
                            if (!hasButton) return;
                            if (!points || points.length === 0) return;

                            var match = null;
                            for (var i = 0; i < points.length; ++i) {
                                var rp = points[i];
                                if (btnTouchArea.activePointId === -1 || rp.pointId === btnTouchArea.activePointId) {
                                    match = rp;
                                    break;
                                }
                            }
                            if (!match) return;

                            holdTimer.stop()
                            if (btnTouchArea.longHeld) {
                                if (btnTouchArea.heldKeyCode !== -1) {
                                    Quickshell.execDetached({
                                        command: [
                                            "sh",
                                            "-c",
                                            "uv run python " + 
                                            Qt.resolvedUrl("scripts/osk_zmq_client.py").toString().replace(/^file:\/{2}/, "")
                                            + " --event long_end --code "
                                            + String(btnTouchArea.heldKeyCode)
                                        ],
                                        workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
                                    });
                                } else if (btnTouchArea.layerSwitch) {
                                    keyGrid.layerSwitched("main");
                                }
                                btnTouchArea.longHeld = false;
                                btnTouchArea.heldKeyCode = -1;
                            } else {
                                var code = btnTouchArea.primaryKeyCode;
                                if (code !== null && code !== undefined) {
                                    Quickshell.execDetached({
                                        command: [
                                            "sh",
                                            "-c",
                                            "uv run python " +
                                            Qt.resolvedUrl("scripts/osk_zmq_client.py").toString().replace(/^file:\/{2}/, "")
                                            + " --event short_press --code "
                                            + String(code)
                                        ],
                                        workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
                                    });
                                }
                            }
                            btnTouchArea.activePointId = -1;
                        }

                        onCanceled: function(points) {
                            onReleased(points);
                        }
                    }
                }
            }
        }
    }
}
