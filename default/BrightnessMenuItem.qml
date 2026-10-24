import QtQuick
import Quickshell.Io

// Screen brightness row: "[-]  ☀ 35%  [+]", with a bar between the buttons
// showing the level. The buttons and the scroll wheel step it; clicking or
// dragging on the bar sets it directly. Uses `brightnessctl` on the first backlight device, and is
// hidden when there is none (e.g. on desktops).
DropdownMenuItem {
    id: brightnessItem

    // Refreshes the level while true, e.g. while the menu is open.
    property bool active: false
    property int step: 5
    // Never fully off, which would leave the screen black.
    readonly property int minimumPercent: 1

    property bool available: false
    property int percent: 0
    // Level waiting to be written while a write is still running.
    property int pendingPercent: -1

    function setPercent(value) {
        let clamped = Math.round(Math.min(Math.max(value, brightnessItem.minimumPercent), 100));
        brightnessItem.percent = clamped;
        brightnessItem.pendingPercent = clamped;
        if (!writeProcess.running) {
            brightnessItem.writePending();
        }
    }

    function writePending() {
        if (brightnessItem.pendingPercent < 0) {
            return;
        }
        writeProcess.command = ["brightnessctl", "--class", "backlight", "set", `${brightnessItem.pendingPercent}%`];
        brightnessItem.pendingPercent = -1;
        writeProcess.running = true;
    }

    // Scroll distance not yet turned into steps; touchpads scroll in small
    // increments, a mouse wheel in notches of 120.
    property real pendingScroll: 0

    visible: available

    onActiveChanged: {
        if (active) {
            readProcess.running = true;
        }
    }

    Process {
        id: readProcess
        command: ["brightnessctl", "--class", "backlight", "--machine-readable", "info"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                // e.g. "intel_backlight,backlight,33600,35%,96000"
                let fields = this.text.trim().split(",");
                if (fields.length < 5) {
                    brightnessItem.available = false;
                    return;
                }
                brightnessItem.available = true;
                // Don't jump back to an older level while one is being set.
                if (writeProcess.running || brightnessItem.pendingPercent >= 0 || barMouseArea.pressed) {
                    return;
                }
                let current = parseInt(fields[2]);
                let max = parseInt(fields[4]);
                if (max > 0) {
                    brightnessItem.percent = Math.round(current / max * 100);
                }
            }
        }
    }

    Process {
        id: writeProcess
        onExited: brightnessItem.writePending()
    }

    // Picks up changes made elsewhere (keys, hypridle dimming, ...).
    Timer {
        interval: 2000
        running: brightnessItem.active && brightnessItem.available
        repeat: true
        onTriggered: readProcess.running = true
    }

    WindowActionButton {
        id: decreaseButton
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "minus"
        enabledAction: brightnessItem.percent > brightnessItem.minimumPercent
        action: () => brightnessItem.setPercent(brightnessItem.percent - brightnessItem.step)
    }

    // The bar between the buttons, like a slider track: click or drag on it
    // to set the level.
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
            width: parent.width * brightnessItem.percent / 100
            color: AppConstants.indicatorBarColor

            Behavior on width {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: barMouseArea
            anchors.fill: parent
            preventStealing: true
            onPressed: mouse => brightnessItem.setPercent(mouse.x / width * 100)
            onPositionChanged: mouse => brightnessItem.setPercent(mouse.x / width * 100)
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        RecoloredIcon {
            anchors.verticalCenter: parent.verticalCenter
            iconWidth: 22
            iconHeight: 22
            source: Qt.resolvedUrl("assets/icons/fontawesome/solid/sun.svg")
            iconColor: AppConstants.iconColor
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 18
            text: `${brightnessItem.percent}%`
        }
    }

    WindowActionButton {
        id: increaseButton
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "plus"
        enabledAction: brightnessItem.percent < 100
        action: () => brightnessItem.setPercent(brightnessItem.percent + brightnessItem.step)
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            brightnessItem.pendingScroll += event.angleDelta.y;
            let steps = Math.trunc(brightnessItem.pendingScroll / 120);
            if (steps !== 0) {
                brightnessItem.pendingScroll -= steps * 120;
                brightnessItem.setPercent(brightnessItem.percent + steps * brightnessItem.step);
            }
        }
    }
}
