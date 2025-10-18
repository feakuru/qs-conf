import QtQuick
import Quickshell.Io

Rectangle {
    color: "transparent"
    border.width: 1
    border.color: AppConstants.indicatorBorderColor

    StyledText {
        id: kbLayoutIndicator
    }

    Process {
        id: kbLayoutProc
        command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | \"\\(.layout) \\(.active_layout_index)\"'",]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var [layouts, layoutIdx] = this.text.trim().split(' ');
                layoutIdx = parseInt(layoutIdx);
                layouts = layouts.split(',');
                switch (layouts[layoutIdx]) {
                case 'ru':
                    kbLayoutIndicator.text = '🇷🇺';
                    break;
                case 'us':
                    kbLayoutIndicator.text = '🇺🇸';
                    break;
                default:
                    kbLayoutIndicator.text = layouts[layoutIdx];
                }
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
