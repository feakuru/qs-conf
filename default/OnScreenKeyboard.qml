import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
        // The overlay layer is drawn above fullscreen windows too (the
        // default, top layer, is covered by them).
        WlrLayershell.layer: WlrLayer.Overlay
        // Spans the screen's width, so the compositor resizes it when the
        // screen rotates. Pinned, it reserves its height at the bottom of
        // the screen so that windows aren't covered by it.
        property bool pinned: false
        exclusionMode: pinned ? ExclusionMode.Auto : ExclusionMode.Normal
        anchors {
            left: true
            right: true
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

        // Shrinks the keyboard to fit screens narrower than it (e.g. the
        // tablet in portrait).
        readonly property real contentScale: width > 0 && oskLayout.implicitWidth > width ? width / oskLayout.implicitWidth : 1

        // Rounded up: windows have whole-pixel sizes.
        implicitHeight: Math.max(1, Math.ceil(oskLayout.implicitHeight * contentScale))

        RowLayout {
            id: oskLayout
            width: oskWindow.width / oskWindow.contentScale
            height: implicitHeight
            scale: oskWindow.contentScale
            transformOrigin: Item.TopLeft

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
                // Reserves room for the controls, so that the keyboard halves
                // don't cover them when the keyboard is shrunk.
                implicitWidth: oskControls.implicitWidth
                implicitHeight: oskControls.implicitHeight
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridLayout {
                    id: oskControls
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    columns: 3
                    columnSpacing: 10

                    ListModel {
                        id: oskControlsModel
                        ListElement {
                            text: "pin"
                            onPressed: points => {
                                oskWindow.pinned = !oskWindow.pinned;
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
