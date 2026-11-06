import QtQuick

// Screen brightness row: "[-]  ☀ 35%  [+]", with a bar between the buttons
// showing the level. The buttons and the scroll wheel step it; clicking or
// dragging on the bar sets it directly. The level comes from qs-conf-daemon's
// `brightness` topic (the first backlight device, re-read so that changes
// made elsewhere show up), and the row is hidden when there is none (e.g. on
// desktops).
DropdownMenuItem {
    id: brightnessItem

    // Follows the level while true, e.g. while the menu is open.
    property bool active: false
    property int step: 5
    // Never fully off, which would leave the screen black.
    readonly property int minimumPercent: 1

    // {available, percent}; null while the daemon is unreachable.
    readonly property var brightness: Daemon.connected ? brightnessTopic.latest : null
    readonly property bool available: brightness !== null && brightness.available
    property int percent: 0

    // Fire-and-forget: the daemon writes only the latest of rapid requests
    // (dragging the bar).
    function setPercent(value) {
        let clamped = Math.round(Math.min(Math.max(value, brightnessItem.minimumPercent), 100));
        brightnessItem.percent = clamped;
        Daemon.call("brightness.set", {
            percent: clamped
        });
    }

    // Scroll distance not yet turned into steps; touchpads scroll in small
    // increments, a mouse wheel in notches of 120.
    property real pendingScroll: 0

    visible: available

    DaemonTopic {
        id: brightnessTopic
        topic: "brightness"
        // Until the first reading, so the row's visibility is known before
        // the menu opens.
        active: brightnessItem.active || brightnessTopic.latest === null
        onData: state => {
            // Don't jump back to an older level while the bar is dragged.
            if (state.available && !barMouseArea.pressed) {
                brightnessItem.percent = state.percent;
            }
        }
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
