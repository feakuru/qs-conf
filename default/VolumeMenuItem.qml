import QtQuick
import Quickshell.Services.Pipewire

// Volume row for a PipeWire audio node (a device or an application stream):
//   [mute] [-] name ███████████░░░░░ 45% [+] [extra]
// Clicking or dragging on the bar sets the volume; the -/+ buttons (for touch)
// and the scroll wheel step it. All of these unmute. While `monitorPeaks` is
// true, a thin meter along the bottom of the bar shows the live audio level.
//
// The node must be bound with a PwObjectTracker for its volume to be valid.
DropdownMenuItem {
    id: volumeItem

    property var node: null
    property string label: ""
    property int labelElide: Text.ElideRight
    property color labelColor: AppConstants.styledTextColor
    // Microphone instead of speaker icons.
    property bool isInput: false
    property bool monitorPeaks: false
    property int step: 5
    // Optional button at the right end, e.g. to pick a device.
    property string extraButtonIcon: ""
    property bool extraButtonHighlighted: false
    property var extraButtonAction: () => {}

    readonly property var nodeAudio: node ? node.audio : null
    readonly property bool muted: nodeAudio ? nodeAudio.muted : false
    readonly property int volumePercent: nodeAudio ? Math.round(nodeAudio.volume * 100) : 0
    // Scroll distance not yet turned into steps; touchpads scroll in small
    // increments, a mouse wheel in notches of 120.
    property real pendingScroll: 0

    // The bar covers 0-100%; louder volumes (set elsewhere) are kept until
    // the volume is changed here.
    function setVolume(percent) {
        if (!volumeItem.nodeAudio) {
            return;
        }
        volumeItem.nodeAudio.volume = Math.min(Math.max(percent, 0), 100) / 100;
        if (volumeItem.nodeAudio.muted) {
            volumeItem.nodeAudio.muted = false;
        }
    }

    function toggleMute() {
        if (volumeItem.nodeAudio) {
            volumeItem.nodeAudio.muted = !volumeItem.nodeAudio.muted;
        }
    }

    PwNodePeakMonitor {
        id: peakMonitor
        node: volumeItem.node
        enabled: volumeItem.monitorPeaks && volumeItem.node !== null
    }

    WindowActionButton {
        id: muteButton
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: {
            if (volumeItem.isInput) {
                return volumeItem.muted ? "microphone-slash" : "microphone";
            }
            if (volumeItem.muted) {
                return "volume-xmark";
            }
            if (volumeItem.volumePercent === 0) {
                return "volume-off";
            }
            return volumeItem.volumePercent < 50 ? "volume-low" : "volume-high";
        }
        highlighted: volumeItem.muted
        activeIconColor: AppConstants.dangerColor
        action: () => volumeItem.toggleMute()
    }

    WindowActionButton {
        id: decreaseButton
        anchors.left: muteButton.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "minus"
        enabledAction: volumeItem.volumePercent > 0
        action: () => volumeItem.setVolume(Math.min(volumeItem.volumePercent, 100) - volumeItem.step)
    }

    Item {
        id: barArea
        anchors.left: decreaseButton.right
        anchors.leftMargin: 6
        anchors.right: increaseButton.left
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 1
        anchors.bottomMargin: 1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.min(volumeItem.volumePercent, 100) / 100
            color: volumeItem.muted ? AppConstants.mutedBarColor : AppConstants.indicatorBarColor

            Behavior on width {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // Live level, on a -60..0 dB scale so that quiet audio still shows.
        Rectangle {
            readonly property real level: peakMonitor.peak > 0 ? Math.min(Math.max((20 * Math.log10(peakMonitor.peak) + 60) / 60, 0), 1) : 0

            visible: peakMonitor.enabled
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 3
            width: parent.width * level
            color: AppConstants.indicatorOnColor
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.right: volumeValueText.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
            color: volumeItem.muted ? AppConstants.mutedIconColor : volumeItem.labelColor
            horizontalAlignment: Text.AlignLeft
            elide: volumeItem.labelElide
            text: volumeItem.label
        }

        StyledText {
            id: volumeValueText
            anchors.centerIn: undefined
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
            color: volumeItem.muted ? AppConstants.mutedIconColor : AppConstants.styledTextColor
            text: volumeItem.muted ? "muted" : `${volumeItem.volumePercent}%`
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onPressed: mouse => volumeItem.setVolume(mouse.x / width * 100)
            onPositionChanged: mouse => volumeItem.setVolume(mouse.x / width * 100)
        }
    }

    WindowActionButton {
        id: increaseButton
        anchors.right: extraButton.visible ? extraButton.left : parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "plus"
        enabledAction: volumeItem.volumePercent < 100
        action: () => volumeItem.setVolume(volumeItem.volumePercent + volumeItem.step)
    }

    WindowActionButton {
        id: extraButton
        visible: volumeItem.extraButtonIcon !== ""
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: volumeItem.extraButtonIcon
        highlighted: volumeItem.extraButtonHighlighted
        action: () => volumeItem.extraButtonAction()
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            volumeItem.pendingScroll += event.angleDelta.y;
            let steps = Math.trunc(volumeItem.pendingScroll / 120);
            if (steps !== 0) {
                volumeItem.pendingScroll -= steps * 120;
                volumeItem.setVolume(Math.min(volumeItem.volumePercent, 100) + steps * volumeItem.step);
            }
        }
    }
}
