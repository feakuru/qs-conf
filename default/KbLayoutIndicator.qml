import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    color: kbLayoutMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor
    property real preferredWidth: kbLayoutIndicator.width + 20

    Process {
        id: toggleKeyboardProcess
        command: ["hyprctl", "switchxkblayout", "current", "next"]
    }

    StyledText {
        id: kbLayoutIndicator
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
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: function () {
            kbLayoutProc.running = true;
        }
    }
}
