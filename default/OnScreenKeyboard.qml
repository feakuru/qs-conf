import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: oskContainer
    color: oskToggleMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real preferredWidth: oskIcon.iconWidth + 20
    property bool isShiftDown: oskLeftBody.isShiftDown || oskRightBody.isShiftDown

    onIsShiftDownChanged: () => {
        oskConfigProcess.running = true;
    }

    required property string layoutName

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
                        oskConfigProcess.running = true;
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
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 60
                            border.width: 2
                            radius: 3
                            color: AppConstants.solidBgColor

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
                                onPressed: points => model.onPressed(points)
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
                        oskConfigProcess.running = true;
                    }
                }
            }
        }

        ScriptProcess {
            id: oskConfigProcess
            scriptName: "osk_layout"
            scriptArgs: [oskWindow.layerName, oskContainer.layoutName, oskContainer.isShiftDown ? "on" : "off"]
            running: false

            stdout: StdioCollector {
                onStreamFinished: {
                    var out = this.text.trim();
                    if (out.length === 0)
                        return;
                    try {
                        var parsed = JSON.parse(out);
                        if (parsed.left && parsed.left instanceof Array && parsed.left.length > 0) {
                            oskContainer.oskLeftModel = parsed.left;
                        }
                        if (parsed.right && parsed.right instanceof Array && parsed.right.length > 0) {
                            oskContainer.oskRightModel = parsed.right;
                        }
                    } catch (e) {
                        console.log("Failed to parse osk_layout output:", e);
                    }
                }
            }
        }

        Timer {
            id: oskReloadTimer
            interval: 500
            running: true
            repeat: true
            onTriggered: function () {
                if (oskWindow.visible) {
                    oskConfigProcess.running = true;
                }
            }
        }
    }
}
