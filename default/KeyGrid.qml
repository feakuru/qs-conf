import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    property var model: []
    property bool longPressEnabled: false
    spacing: 6

    // model is expected to be a list of rows (each row is an array or null)
    Repeater {
        model: root.model
        delegate: RowLayout {
            spacing: 6

            Repeater {
                model: modelData === null ? [] : modelData
                delegate: Rectangle {
                    property var cell: modelData
                    property bool hasButton: cell !== null && typeof cell === "object"
                    color: hasButton ? AppConstants.solidBgColor : "transparent"
                    radius: 3
                    border.width: hasButton ? 2 : 0
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
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
                            property string heldText: (cell && cell.key_held) ? cell.key_held : ""
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

                        // long-press behaviour (mirror of original left-hand logic)
                        property var primaryKeyCode: (cell && (cell.keycode_pressed !== undefined ? cell.keycode_pressed : (cell.key_pressed !== undefined ? cell.key_pressed : (cell.key !== undefined ? cell.key : null))))
                        property var heldKeyCodeProp: (cell && (cell.keycode_held !== undefined ? cell.keycode_held : (cell.key_held !== undefined ? cell.key_held : null)))
                        property bool hasPrimaryKey: primaryKeyCode !== null && primaryKeyCode !== undefined

                        // state for press/hold logic (per-area; typically one touch per key)
                        property bool longHeld: false
                        property int heldKeyCode: -1
                        property int activePointId: -1

                        Timer {
                            id: holdTimer
                            interval: 200
                            repeat: false
                            onTriggered: {
                                console.log("timer triggered")
                                btnTouchArea.longHeld = true
                                var codeHeld = btnTouchArea.heldKeyCodeProp
                                if (codeHeld !== null && codeHeld !== undefined) {
                                    btnTouchArea.heldKeyCode = codeHeld
                                    Quickshell.execDetached(["ydotool", "key", `${btnTouchArea.heldKeyCode}:1`])
                                }
                            }
                        }

                        onPressed: function(points) {
                            if (!hasButton) return;
                            if (!points || points.length === 0) return;
                            // take the first new contact for this key
                            var p = points[0]
                            p.accepted = true
                            // only set active point if none set yet
                            if (btnTouchArea.activePointId === -1) {
                                btnTouchArea.longHeld = false
                                btnTouchArea.heldKeyCode = -1
                                btnTouchArea.activePointId = p.pointId
                                if (root.longPressEnabled) {
                                    holdTimer.start()
                                }
                            }
                        }

                        onReleased: function(points) {
                            if (!hasButton) return;
                            if (!points || points.length === 0) return;
                            // find the released point that matches our activePointId (if set)
                            var match = null
                            for (var i = 0; i < points.length; ++i) {
                                var rp = points[i]
                                if (btnTouchArea.activePointId === -1 || rp.pointId === btnTouchArea.activePointId) {
                                    match = rp
                                    break
                                }
                            }
                            if (!match) return;
                            console.log("released triggered", match.pointId)
                            if (root.longPressEnabled) {
                                holdTimer.stop()
                                if (btnTouchArea.longHeld) {
                                    if (btnTouchArea.heldKeyCode !== -1) {
                                        Quickshell.execDetached(["ydotool", "key", `${btnTouchArea.heldKeyCode}:0`])
                                    }
                                    btnTouchArea.longHeld = false
                                    btnTouchArea.heldKeyCode = -1
                                } else {
                                    var code = btnTouchArea.primaryKeyCode
                                    if (code !== null && code !== undefined) {
                                        Quickshell.execDetached(["ydotool", "key", `${code}:1`, `${code}:0`])
                                    }
                                }
                            } else {
                                // simple click behaviour: use the resolved primary key code
                                var code = btnTouchArea.primaryKeyCode
                                if (code !== null && code !== undefined) {
                                    Quickshell.execDetached(["ydotool", "key", `${code}:1`, `${code}:0`])
                                }
                            }
                            btnTouchArea.activePointId = -1
                        }

                        onCanceled: function(points) {
                            // treat cancellations similar to releases; use same points list
                            onReleased(points)
                        }
                    }
                }
            }
        }
    }
}
