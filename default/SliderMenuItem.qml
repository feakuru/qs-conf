import QtQuick

// A level row: "[-]  icon text  [+]", with a bar between the buttons showing
// `value` between `from` and `to`. The buttons and the scroll wheel step it;
// clicking or dragging on the bar sets it directly. Every change is reported
// through `moved`; the owner applies it and feeds the new level back into
// `value`. While not `available`, it is faded and can't be changed.
DropdownMenuItem {
    id: sliderItem

    // The level from its source, e.g. a daemon topic.
    property int value: 0
    property int from: 0
    property int to: 100
    property int step: 5
    property string iconName: ""
    property string text: `${sliderItem.shownValue}%`
    property bool available: true
    property color barColor: AppConstants.indicatorBarColor
    readonly property bool dragging: barMouseArea.pressed

    signal moved(int value)

    // What the row shows: the requested level until the source catches up,
    // and not an older level from the source while the bar is dragged.
    property int shownValue: 0

    function setValue(newValue) {
        if (!sliderItem.available) {
            return;
        }
        let clamped = Math.round(Math.min(Math.max(newValue, sliderItem.from), sliderItem.to));
        if (clamped === sliderItem.shownValue) {
            return;
        }
        sliderItem.shownValue = clamped;
        sliderItem.moved(clamped);
    }

    function setFromBar(x) {
        sliderItem.setValue(sliderItem.from + x / barArea.width * (sliderItem.to - sliderItem.from));
    }

    onValueChanged: {
        if (!sliderItem.dragging) {
            sliderItem.shownValue = sliderItem.value;
        }
    }
    Component.onCompleted: sliderItem.shownValue = sliderItem.value

    // Scroll distance not yet turned into steps; touchpads scroll in small
    // increments, a mouse wheel in notches of 120.
    property real pendingScroll: 0

    opacity: available ? 1 : 0.4

    WindowActionButton {
        id: decreaseButton
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "minus"
        enabledAction: sliderItem.available && sliderItem.shownValue > sliderItem.from
        action: () => sliderItem.setValue(sliderItem.shownValue - sliderItem.step)
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
            width: sliderItem.to > sliderItem.from ? parent.width * (sliderItem.shownValue - sliderItem.from) / (sliderItem.to - sliderItem.from) : 0
            color: sliderItem.barColor

            Behavior on width {
                enabled: !sliderItem.dragging
                NumberAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: barMouseArea
            anchors.fill: parent
            preventStealing: true
            onPressed: mouse => sliderItem.setFromBar(mouse.x)
            onPositionChanged: mouse => sliderItem.setFromBar(mouse.x)
            // Shows the source's level again if it differs from the dragged one.
            onReleased: Qt.callLater(() => {
                if (!sliderItem.dragging) {
                    sliderItem.shownValue = sliderItem.value;
                }
            })
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        RecoloredIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: sliderItem.iconName !== ""
            iconWidth: 22
            iconHeight: 22
            source: sliderItem.iconName === "" ? "" : Qt.resolvedUrl(`assets/icons/fontawesome/solid/${sliderItem.iconName}.svg`)
            iconColor: AppConstants.iconColor
        }

        StyledText {
            anchors.centerIn: undefined
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 18
            text: sliderItem.text
        }
    }

    WindowActionButton {
        id: increaseButton
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        iconName: "plus"
        enabledAction: sliderItem.available && sliderItem.shownValue < sliderItem.to
        action: () => sliderItem.setValue(sliderItem.shownValue + sliderItem.step)
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            sliderItem.pendingScroll += event.angleDelta.y;
            let steps = Math.trunc(sliderItem.pendingScroll / 120);
            if (steps !== 0) {
                sliderItem.pendingScroll -= steps * 120;
                sliderItem.setValue(sliderItem.shownValue + steps * sliderItem.step);
            }
        }
    }
}
