import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Rectangle {
    id: kbLayoutIndicatorContainer
    color: kbLayoutMouseArea.containsMouse ? AppConstants.focusedBgColor : "transparent"
    implicitWidth: kbLayoutRow.implicitWidth + 20
    Layout.fillHeight: true
    // The daemon's `kb` topic: {layouts, index, caps, num}, from Hyprland's
    // main keyboard (Caps/Num Lock: any keyboard); null while it's unreachable.
    readonly property var kbState: Daemon.connected ? kbTopic.latest : null
    // E.g. "us"; empty while unknown. Also feeds the on-screen keyboard.
    readonly property string currentLayoutName: kbState ? kbState.layouts[kbState.index] || "" : ""
    readonly property bool capsLockOn: kbState ? kbState.caps : false
    readonly property bool numLockOn: kbState ? kbState.num : false

    function flagEmojiFromCountryCode(code) {
        if (!code || code.length !== 2)
            return code;
        code = code.toUpperCase();
        return String.fromCodePoint(...[...code].map(c => 0x1F1E6 + c.charCodeAt(0) - 65));
    }

    DaemonTopic {
        id: kbTopic
        topic: "kb"
    }

    Row {
        id: kbLayoutRow
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            id: kbLayoutIndicator
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
            text: kbLayoutIndicatorContainer.kbState ? kbLayoutIndicatorContainer.flagEmojiFromCountryCode(kbLayoutIndicatorContainer.currentLayoutName) : "…"
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
            Daemon.call("kb.next_layout", undefined, (result, error) => {
                if (error !== undefined) {
                    console.warn("KbLayoutIndicator: kb.next_layout failed:", error);
                }
            });
        }
    }
}
