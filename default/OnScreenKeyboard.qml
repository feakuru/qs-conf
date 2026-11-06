import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

BarButton {
    id: oskContainer
    toggleIconSource: Qt.resolvedUrl(`assets/icons/fontawesome/solid/keyboard.svg`)
    property bool isShiftDown: oskLeftBody.isShiftDown || oskRightBody.isShiftDown

    onIsShiftDownChanged: oskContainer.requestLayout()

    // The active xkb layout, e.g. "us" (from KbLayoutIndicator).
    required property string layoutName

    onLayoutNameChanged: oskContainer.requestLayout()

    // Numbers the osk.layout requests: replies arrive in the order they're
    // ready, and only the latest request's counts.
    property int layoutRequest: 0

    // Asks the daemon for the keys of the current layer, labelled for the
    // active layout and Shift. While it's unreachable, this waits for the
    // connection (see the Connections below).
    function requestLayout(): void {
        if (!Daemon.connected) {
            return;
        }
        let request = ++oskContainer.layoutRequest;
        Daemon.call("osk.layout", {
            layer: oskWindow.layerName,
            layout: oskContainer.layoutName,
            shift: oskContainer.isShiftDown
        }, (layout, error) => {
            if (request !== oskContainer.layoutRequest) {
                return;
            }
            if (error !== undefined) {
                console.warn("OnScreenKeyboard: osk.layout failed:", error);
                return;
            }
            if (layout.left && layout.left.length > 0) {
                oskContainer.oskLeftModel = layout.left;
            }
            if (layout.right && layout.right.length > 0) {
                oskContainer.oskRightModel = layout.right;
            }
        });
    }

    Connections {
        target: Daemon

        function onConnectedChanged() {
            if (Daemon.connected) {
                oskContainer.requestLayout();
            }
        }
    }

    onClicked: {
        oskWindow.visible = !oskWindow.visible;
    }

    IpcHandler {
        target: "osk"

        function toggle(): void {
            oskWindow.visible = !oskWindow.visible;
        }
    }

    property var oskLeftModel: []
    property var oskRightModel: []

    Component.onCompleted: oskContainer.requestLayout()

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
        property real soundVolume: 0.1
        property bool soundMuted: false

        implicitWidth: Quickshell.screens[0].width
        implicitHeight: Math.max(leftRegion.height, rightRegion.height)

        RowLayout {
            anchors.fill: parent
            Item {
                id: leftRegion
                implicitWidth: oskLeftBody.rotatedWidth
                implicitHeight: oskLeftBody.rotatedHeight
                Layout.fillHeight: true
                Layout.leftMargin: 50

                KeyGrid {
                    id: oskLeftBody
                    model: oskContainer.oskLeftModel
                    anchors.left: leftRegion.left
                    rotationAngle: 10
                    soundMuted: oskWindow.soundMuted
                    soundVolume: oskWindow.soundVolume
                    onLayerSwitched: layerName => {
                        oskWindow.layerName = layerName;
                        oskContainer.requestLayout();
                    }
                }
            }

            Item {
                id: oskControlGap
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    columns: 3
                    columnSpacing: 10

                    ListModel {
                        id: oskControlsModel
                        ListElement {
                            text: "pin"
                            onPressed: points => {
                                oskWindow.anchors.right = !oskWindow.anchors.right;
                            }
                        }
                        ListElement {
                            text: "hide"
                            onPressed: points => {
                                oskWindow.visible = false;
                            }
                        }
                        ListElement {
                            text: "log"
                            onPressed: points => {
                                console.log("hello!");
                            }
                        }
                        ListElement {
                            text: "mute"
                            onPressed: points => {
                                oskWindow.soundMuted = !oskWindow.soundMuted;
                            }
                        }
                        ListElement {
                            text: "quiet"
                            onPressed: points => {
                                oskWindow.soundVolume = 0.1;
                            }
                        }
                        ListElement {
                            text: "loud"
                            onPressed: points => {
                                oskWindow.soundVolume = 0.5;
                            }
                        }
                    }

                    Repeater {
                        model: oskControlsModel
                        delegate: Rectangle {
                            property int pressedPoints: 0
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 60
                            border.width: 2
                            radius: 3
                            color: pressedPoints > 0 ? AppConstants.pressedSolidBgColor : AppConstants.solidBgColor

                            Text {
                                anchors.centerIn: parent
                                text: model.text
                                font.family: AppConstants.defaultFont
                                color: AppConstants.styledTextColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MultiPointTouchArea {
                                anchors.fill: parent
                                onPressed: points => {
                                    parent.pressedPoints += points.length;
                                    model.onPressed(points);
                                }
                                onReleased: points => parent.pressedPoints = Math.max(0, parent.pressedPoints - points.length)
                                onCanceled: points => parent.pressedPoints = Math.max(0, parent.pressedPoints - points.length)
                            }
                        }
                    }
                }
            }

            Item {
                id: rightRegion
                implicitWidth: oskRightBody.rotatedWidth
                implicitHeight: oskRightBody.rotatedHeight
                Layout.fillHeight: true

                KeyGrid {
                    id: oskRightBody
                    model: oskContainer.oskRightModel
                    isRightHalf: true
                    rotationAngle: -10
                    soundMuted: oskWindow.soundMuted
                    soundVolume: oskWindow.soundVolume
                    onLayerSwitched: layerName => {
                        oskWindow.layerName = layerName;
                        oskContainer.requestLayout();
                    }
                }
            }
        }
    }
}
