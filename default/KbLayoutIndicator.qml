import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: kbLayoutIndicatorContainer
    color: kbLayoutMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real preferredWidth: kbLayoutRow.width + 20
    property string currentLayoutName
    property bool capsLockOn: false
    property bool numLockOn: false

    Process {
        id: toggleKeyboardProcess
        command: ["hyprctl", "switchxkblayout", "current", "next"]
    }

    Row {
        id: kbLayoutRow
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            id: kbLayoutIndicator
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: capsLockIndicator
            text: "Caps"
            color: AppConstants.indicatorOnColor
            visible: kbLayoutIndicatorContainer.capsLockOn
            styleColor: AppConstants.styledTextOutlineColor
            font.pixelSize: 16
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: numLockIndicator
            text: "Num"
            color: AppConstants.indicatorOnColor
            visible: kbLayoutIndicatorContainer.numLockOn
            styleColor: AppConstants.styledTextOutlineColor
            font.pixelSize: 16
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: kbLayoutMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mouseEvent => {
            toggleKeyboardProcess.running = true;
        }
    }

    Process {
        id: kbLayoutProc
        command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | \"\\(.layout) \\(.active_layout_index)\"'",]
        running: true

        stdout: StdioCollector {
            function flagEmojiFromCountryCode(code) {
                if (!code || code.length !== 2)
                    return code;
                code = code.toUpperCase();
                return String.fromCodePoint(...[...code].map(c => 0x1F1E6 + c.charCodeAt(0) - 65));
            }

            onStreamFinished: {
                var [layouts, layoutIdx] = this.text.trim().split(' ');
                layoutIdx = parseInt(layoutIdx);
                layouts = layouts.split(',');
                kbLayoutIndicator.text = flagEmojiFromCountryCode(layouts[layoutIdx]);
                kbLayoutIndicatorContainer.currentLayoutName = layouts[layoutIdx];
            }
        }
    }

    Process {
        id: capsLockProc
        command: ["bash", "-c", "cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                kbLayoutIndicatorContainer.capsLockOn = this.text.trim() === "1";
            }
        }
    }

    Process {
        id: numLockProc
        command: ["bash", "-c", "cat /sys/class/leds/input*::numlock/brightness 2>/dev/null | head -1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                kbLayoutIndicatorContainer.numLockOn = this.text.trim() === "1";
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: function () {
            kbLayoutProc.running = true;
            capsLockProc.running = true;
            numLockProc.running = true;
        }
    }
}
