import QtQuick
import Quickshell
import Quickshell.Wayland

// Moves and resizes the on-screen keyboard: a frame over the keyboard, with a
// handle on its edge to resize it and, while floating, dragged anywhere
// inside to move it. "Done" or a tap outside the frame ends it.
//
// A screen-sized window of its own, mapped over the keyboard, rather than
// handles inside the keyboard's window: that window moves and resizes under
// the finger, so drags measured in it would feed back on themselves. Here
// the coordinates stay put. While floating, it covers the whole screen like
// the keyboard does; pinned, it covers the area left by other panels (the
// keyboard stops reserving its own while it's edited), so in both cases its
// coordinates match those of the keyboard's margins.
PanelWindow {
    id: editOverlay

    // The keyboard's size and place, from OnScreenKeyboard.
    required property real naturalHeight
    // The largest scale at which the keyboard still fits.
    required property real fitScale
    required property real keyboardWidth
    required property real keyboardHeight
    required property real floatLeft
    required property real floatTop
    required property int edgeMargin

    signal done

    readonly property bool floating: OskState.floating
    readonly property rect frameRect: {
        if (editOverlay.floating) {
            return Qt.rect(editOverlay.floatLeft, editOverlay.floatTop, editOverlay.keyboardWidth, editOverlay.keyboardHeight);
        }
        let width = editOverlay.width - 2 * editOverlay.edgeMargin;
        let y = OskState.mode === "top" ? editOverlay.edgeMargin : editOverlay.height - editOverlay.edgeMargin - editOverlay.keyboardHeight;
        return Qt.rect(editOverlay.edgeMargin, y, width, editOverlay.keyboardHeight);
    }
    // The resize handle is on the edge that faces the middle of the screen:
    // the top one when pinned to the bottom or floating in the lower half.
    // It stays put while it's dragged.
    property bool handleOnTop: false

    Binding on handleOnTop {
        when: !resizeArea.pressed
        restoreMode: Binding.RestoreNone
        value: editOverlay.floating ? editOverlay.frameRect.y + editOverlay.frameRect.height / 2 > editOverlay.height / 2 : OskState.mode === "bottom"
    }

    // Where a drag started, in this window, and the keyboard's place then.
    property point dragStart: Qt.point(0, 0)
    property rect startRect: Qt.rect(0, 0, 0, 0)

    function beginDrag(item: Item, x: real, y: real): void {
        editOverlay.dragStart = item.mapToItem(null, x, y);
        editOverlay.startRect = editOverlay.frameRect;
    }

    function dragDelta(item: Item, x: real, y: real): point {
        let position = item.mapToItem(null, x, y);
        return Qt.point(position.x - editOverlay.dragStart.x, position.y - editOverlay.dragStart.y);
    }

    // As OnScreenKeyboard places the floating keyboard: within edgeMargin of
    // the screen's edges. A keyboard as wide as that room keeps its floatX.
    function setFloatPlace(left: real, top: real, width: real, height: real): void {
        let freeWidth = editOverlay.width - 2 * editOverlay.edgeMargin - width;
        let freeHeight = editOverlay.height - 2 * editOverlay.edgeMargin - height;
        OskState.setFloatPosition(freeWidth > 0 ? (left - editOverlay.edgeMargin) / freeWidth : OskState.floatX, freeHeight > 0 ? (top - editOverlay.edgeMargin) / freeHeight : OskState.floatY);
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osk-editor"
    exclusionMode: editOverlay.floating ? ExclusionMode.Ignore : ExclusionMode.Normal
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: editOverlay.done()
    }

    Rectangle {
        id: frame
        x: editOverlay.frameRect.x
        y: editOverlay.frameRect.y
        width: editOverlay.frameRect.width
        height: editOverlay.frameRect.height
        radius: 8
        color: Qt.rgba(AppConstants.accentColor.r, AppConstants.accentColor.g, AppConstants.accentColor.b, 0.25)
        border.width: 3
        border.color: AppConstants.indicatorOnColor

        // Moves the floating keyboard; pinned, it only keeps taps from
        // ending the editing.
        MouseArea {
            id: moveArea
            anchors.fill: parent
            preventStealing: true
            cursorShape: editOverlay.floating ? Qt.SizeAllCursor : Qt.ArrowCursor
            onPressed: mouse => editOverlay.beginDrag(moveArea, mouse.x, mouse.y)
            onPositionChanged: mouse => {
                if (!editOverlay.floating) {
                    return;
                }
                let delta = editOverlay.dragDelta(moveArea, mouse.x, mouse.y);
                let start = editOverlay.startRect;
                editOverlay.setFloatPlace(start.x + delta.x, start.y + delta.y, start.width, start.height);
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 8

            StyledText {
                anchors.centerIn: undefined
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 16
                text: editOverlay.floating ? "Drag to move, or drag the handle to resize" : "Drag the handle to resize"
            }

            OskButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                iconName: "check"
                label: "Done"
                action: () => editOverlay.done()
            }
        }

        // Sets the height, and with it the size of the keys. The opposite
        // edge stays in place.
        OskButton {
            anchors.horizontalCenter: parent.horizontalCenter
            y: editOverlay.handleOnTop ? -height / 2 : parent.height - height / 2
            width: 120
            height: 44
            iconName: "up-down"

            MouseArea {
                id: resizeArea
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.SizeVerCursor
                onPressed: mouse => editOverlay.beginDrag(resizeArea, mouse.x, mouse.y)
                onPositionChanged: mouse => {
                    let delta = editOverlay.dragDelta(resizeArea, mouse.x, mouse.y);
                    let start = editOverlay.startRect;
                    let height = start.height + (editOverlay.handleOnTop ? -delta.y : delta.y);
                    OskState.setScale(Math.min(Math.max(height / editOverlay.naturalHeight, OskState.minScale), editOverlay.fitScale));
                    if (editOverlay.floating) {
                        let scale = Math.min(OskState.scale, editOverlay.fitScale);
                        let newHeight = Math.ceil(editOverlay.naturalHeight * scale);
                        let top = editOverlay.handleOnTop ? start.y + start.height - newHeight : start.y;
                        editOverlay.setFloatPlace(start.x, top, start.width, newHeight);
                    }
                }
            }
        }
    }
}
