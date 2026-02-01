import Quickshell
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
                model: {
                    var KeyDef = function KeyDef(text, key) {
                        this.text = text;
                        this.key = key;
                    };
                    [new KeyDef("Esc", 1), new KeyDef("1", 2), new KeyDef("2", 3), new KeyDef("3", 4), new KeyDef("4", 5), new KeyDef("5", 6), new KeyDef(""), new KeyDef("q", 16), new KeyDef("w", 17), new KeyDef("e", 18), new KeyDef("r", 19), new KeyDef("t", 20), new KeyDef("Esc", 1), new KeyDef("a", 30), new KeyDef("s", 31), new KeyDef("d", 32), new KeyDef("f", 33), new KeyDef("g", 34), new KeyDef(""), new KeyDef("z", 44), new KeyDef("x", 45), new KeyDef("c", 46), new KeyDef("v", 47), new KeyDef("b", 48),];
                }
                delegate: Rectangle {
                    color: AppConstants.solidBgColor
                    radius: 3
                    border.width: 2
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    StyledText {
                        text: modelData.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: () => {
                            if (!modelData.key) {
                                console.log("no key");
                                return;
                            }
                            console.log("clicked", JSON.stringify(modelData));
                            Quickshell.execDetached(["ydotool", "key", `${modelData.key}:1`, `${modelData.key}:0`]);
                        }
                    }
                }
            }
            Rectangle {
                Layout.columnSpan: 4
                color: "transparent"
            }
            Rectangle {
                Layout.preferredHeight: 64
                Layout.preferredWidth: 64
                color: AppConstants.solidBgColor
                border.width: 2
                StyledText {
                    text: "↵"
                }
            }
            Rectangle {
                Layout.preferredHeight: 64
                Layout.preferredWidth: 64
                color: AppConstants.solidBgColor
                border.width: 2
                StyledText {
                    text: "⌘"
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
                model: {
                    var KeyDef = function KeyDef(text, key) {
                        this.text = text;
                        this.key = key;
                    };
                    [new KeyDef("6", 7), new KeyDef("7", 8), new KeyDef("8", 9), new KeyDef("9", 10), new KeyDef("0", 11), new KeyDef(""), new KeyDef("y", 21), new KeyDef("u", 22), new KeyDef("i", 23), new KeyDef("o", 24), new KeyDef("p", 25), new KeyDef(""), new KeyDef("h", 35), new KeyDef("j", 36), new KeyDef("k", 37), new KeyDef("l", 38), new KeyDef(";", 39), new KeyDef(""), new KeyDef("n", 49), new KeyDef("m", 50), new KeyDef(",", 51), new KeyDef(".", 52), new KeyDef("/", 53), new KeyDef("")];
                }
                delegate: Rectangle {
                    color: AppConstants.solidBgColor
                    radius: 3
                    border.width: 2
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    StyledText {
                        text: modelData.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: (event) => {
                            event.accepted = true;
                            if (!modelData.key) {
                                console.log("no key");
                                return;
                            }
                            console.log("clicked", JSON.stringify(modelData));
                            Quickshell.execDetached(["ydotool", "key", `${modelData.key}:1`, `${modelData.key}:0`]);
                        }
                    }
                }
            }
            Rectangle {
                Layout.preferredHeight: 64
                Layout.preferredWidth: 64
                color: AppConstants.solidBgColor
                border.width: 2
                StyledText {
                    text: "⌫"
                }
            }
            Rectangle {
                Layout.preferredHeight: 64
                Layout.preferredWidth: 64
                color: AppConstants.solidBgColor
                border.width: 2
                StyledText {
                    text: "␣"
                }
            }
        }
    }
}
