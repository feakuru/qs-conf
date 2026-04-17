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
        id: kbDevicesProc
        command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | \"\\(.main) \\(.capsLock) \\(.numLock) \\(.layout) \\(.active_layout_index)\"'"]
        running: true

        stdout: StdioCollector {
            function flagEmojiFromCountryCode(code) {
                if (!code || code.length !== 2)
                    return code;
                code = code.toUpperCase();
                return String.fromCodePoint(...[...code].map(c => 0x1F1E6 + c.charCodeAt(0) - 65));
            }

            onStreamFinished: {
                var lines = this.text.trim().split('\n').filter(l => l.length > 0);
                var anyCaps = false;
                var anyNum = false;
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(' ');
                    // parts: [main, capsLock, numLock, layout, active_layout_index]
                    if (parts[1] === "true")
                        anyCaps = true;
                    if (parts[2] === "true")
                        anyNum = true;
                    if (parts[0] === "true") {
                        // main keyboard — update layout indicator
                        var layoutIdx = parseInt(parts[4]);
                        var layouts = parts[3].split(',');
                        kbLayoutIndicator.text = flagEmojiFromCountryCode(layouts[layoutIdx]);
                        kbLayoutIndicatorContainer.currentLayoutName = layouts[layoutIdx];
                    }
                }
                kbLayoutIndicatorContainer.capsLockOn = anyCaps;
                kbLayoutIndicatorContainer.numLockOn = anyNum;
            }
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: function () {
            kbDevicesProc.running = true;
        }
    }
}
