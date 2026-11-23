import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

BarButton {
    id: oskContainer
    toggleIconSource: Qt.resolvedUrl(`assets/icons/fontawesome/solid/keyboard.svg`)
    property bool isShiftDown: oskLeftBody.isShiftDown || oskRightBody.isShiftDown

    onIsShiftDownChanged: oskContainer.requestLayout()

    // The active xkb layout, e.g. "us" (from KbLayoutIndicator).
    required property string layoutName

    onLayoutNameChanged: oskContainer.requestLayout()

    // Numbers the osk.layout requests: replies arrive in the order they're
    // ready, and only the latest request's counts.
    property int layoutRequest: 0

    // The menu opened from the keyboard's menu button, and the editor that
    // moves and resizes the keyboard (OskEditOverlay).
    property bool menuOpen: false
    property bool editing: false

    // Asks the daemon for the keys of the current layer, labelled for the
    // active layout and Shift. While it's unreachable, this waits for the
    // connection (see the Connections below).
    function requestLayout(): void {
        if (!Daemon.connected) {
            return;
        }
        let request = ++oskContainer.layoutRequest;
        Daemon.call("osk.layout", {
            layer: oskWindow.layerName,
            layout: oskContainer.layoutName,
            shift: oskContainer.isShiftDown
        }, (layout, error) => {
            if (request !== oskContainer.layoutRequest) {
                return;
            }
            if (error !== undefined) {
                console.warn("OnScreenKeyboard: osk.layout failed:", error);
                return;
            }
            if (layout.left && layout.left.length > 0) {
                oskContainer.oskLeftModel = layout.left;
            }
            if (layout.right && layout.right.length > 0) {
                oskContainer.oskRightModel = layout.right;
            }
        });
    }

    function setShown(shown: bool): void {
        oskWindow.visible = shown;
        if (!shown) {
            oskContainer.menuOpen = false;
            oskContainer.editing = false;
        }
    }

    Connections {
        target: Daemon

        function onConnectedChanged() {
            if (Daemon.connected) {
                oskContainer.requestLayout();
            }
        }
    }

    onClicked: oskContainer.setShown(!oskWindow.visible)

    IpcHandler {
        target: "osk"

        function toggle(): void {
            oskContainer.setShown(!oskWindow.visible);
        }
    }

    property var oskLeftModel: []
    property var oskRightModel: []

    Component.onCompleted: oskContainer.requestLayout()

    PanelWindow {
        id: oskWindow
        color: "transparent"
        visible: false
        screen: Quickshell.screens[0]
        // The overlay layer is drawn above fullscreen windows too (the
        // default, top layer, is covered by them).
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osk"

        // Where it is and how big: see OskState. The halves are spread to
        // the sides of the screen: the keyboard spans its width, and the
        // space between them lets touches through to the windows underneath
        // (see the mask below). Floating, it's placed by its top and left
        // margins (within edgeMargin of the screen's edges), over panels and
        // windows alike. Pinned, it's anchored to the top or bottom (so the
        // compositor resizes it when the screen rotates) and reserves its
        // height, except while it's being resized.
        readonly property int edgeMargin: 10
        readonly property real screenWidth: screen ? screen.width : 0
        readonly property real screenHeight: screen ? screen.height : 0
        readonly property real availableWidth: Math.max(1, screenWidth - 2 * edgeMargin)
        readonly property real availableHeight: Math.max(1, screenHeight - 2 * edgeMargin)
        readonly property real naturalWidth: oskLayout.implicitWidth
        readonly property real naturalHeight: oskLayout.implicitHeight
        // The largest scale at which the keys fit across the screen, and in
        // its height when floating or half of it when pinned.
        readonly property real fitScale: {
            if (naturalWidth <= 0 || naturalHeight <= 0) {
                return 1;
            }
            let height = OskState.floating ? availableHeight : screenHeight / 2;
            return Math.min(availableWidth / naturalWidth, height / naturalHeight);
        }
        readonly property real contentScale: Math.max(0.05, Math.min(OskState.scale, fitScale))
        // Rounded up: windows have whole-pixel sizes.
        readonly property int keyboardWidth: Math.round(availableWidth)
        readonly property int keyboardHeight: Math.max(1, Math.ceil(naturalHeight * contentScale))
        readonly property int floatLeft: edgeMargin + Math.round(OskState.floatX * Math.max(0, availableWidth - keyboardWidth))
        readonly property int floatTop: edgeMargin + Math.round(OskState.floatY * Math.max(0, availableHeight - keyboardHeight))

        exclusionMode: {
            if (OskState.floating) {
                return ExclusionMode.Ignore;
            }
            // Resizing would otherwise make every window resize with it.
            return oskContainer.editing ? ExclusionMode.Normal : ExclusionMode.Auto;
        }
        anchors {
            left: true
            right: !OskState.floating
            top: OskState.floating || OskState.mode === "top"
            bottom: OskState.mode === "bottom"
        }
        margins {
            left: OskState.floating ? oskWindow.floatLeft : oskWindow.edgeMargin
            right: oskWindow.edgeMargin
            top: OskState.floating ? oskWindow.floatTop : oskWindow.edgeMargin
            bottom: oskWindow.edgeMargin
        }
        implicitWidth: oskWindow.keyboardWidth
        implicitHeight: oskWindow.keyboardHeight

        // Takes input everywhere but between the halves (other than on the
        // menu button), so that the windows there can still be used. While
        // the menu is open, it takes it everywhere, so that a tap anywhere
        // closes it.
        mask: Region {
            width: oskWindow.width
            height: oskWindow.height

            Region {
                intersection: Intersection.Subtract
                x: Math.floor(middleGap.x * oskWindow.contentScale)
                width: oskContainer.menuOpen ? 0 : Math.ceil(middleGap.width * oskWindow.contentScale)
                height: oskWindow.height
            }

            Region {
                x: Math.floor(menuButton.x * oskWindow.contentScale)
                y: Math.floor(menuButton.y * oskWindow.contentScale)
                width: Math.ceil(menuButton.width * oskWindow.contentScale)
                height: Math.ceil(menuButton.height * oskWindow.contentScale)
            }
        }

        property string layerName: "main"

        Item {
            id: scaledContent
            width: oskWindow.width / oskWindow.contentScale
            height: oskWindow.naturalHeight
            scale: oskWindow.contentScale
            transformOrigin: Item.TopLeft

            RowLayout {
                id: oskLayout
                width: scaledContent.width
                height: implicitHeight

                Item {
                    id: leftRegion
                    implicitWidth: oskLeftBody.rotatedWidth
                    implicitHeight: oskLeftBody.rotatedHeight
                    Layout.fillHeight: true

                    // Centred, so that the rotated half fits the region.
                    KeyGrid {
                        id: oskLeftBody
                        model: oskContainer.oskLeftModel
                        anchors.horizontalCenter: leftRegion.horizontalCenter
                        rotationAngle: 10
                        onLayerSwitched: layerName => {
                            oskWindow.layerName = layerName;
                            oskContainer.requestLayout();
                        }
                    }
                }

                // Space between the halves, taking up the rest of the
                // screen's width.
                Item {
                    id: middleGap
                    implicitWidth: 16
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Item {
                    id: rightRegion
                    implicitWidth: oskRightBody.rotatedWidth
                    implicitHeight: oskRightBody.rotatedHeight
                    Layout.fillHeight: true

                    KeyGrid {
                        id: oskRightBody
                        model: oskContainer.oskRightModel
                        anchors.horizontalCenter: rightRegion.horizontalCenter
                        isRightHalf: true
                        rotationAngle: -10
                        onLayerSwitched: layerName => {
                            oskWindow.layerName = layerName;
                            oskContainer.requestLayout();
                        }
                    }
                }
            }

            // Opens the menu. It sits in one of the spots the angled halves
            // leave free (OskConfig.menuButtonPosition, "<top|bottom>-
            // <left|center|right>") and is scaled with the keys.
            Rectangle {
                id: menuButton
                readonly property string vertical: OskConfig.menuButtonPosition.split("-")[0]
                readonly property string horizontal: OskConfig.menuButtonPosition.split("-")[1]
                readonly property int inset: 4

                width: 48
                height: 48
                x: {
                    switch (menuButton.horizontal) {
                    case "left":
                        return menuButton.inset;
                    case "right":
                        return scaledContent.width - menuButton.width - menuButton.inset;
                    default:
                        return (scaledContent.width - menuButton.width) / 2;
                    }
                }
                y: menuButton.vertical === "top" ? menuButton.inset : scaledContent.height - menuButton.height - menuButton.inset

                // Styled like the keys (KeyGrid), shown pressed while the
                // menu is open.
                radius: 3
                border.width: 2
                color: oskContainer.menuOpen ? AppConstants.pressedSolidBgColor : AppConstants.solidBgColor

                IconImage {
                    id: menuButtonIcon
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: Qt.resolvedUrl("assets/icons/fontawesome/solid/ellipsis.svg")
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: menuButtonIcon
                    source: menuButtonIcon
                    color: AppConstants.styledTextColor
                    opacity: 0.8
                }

                TapHandler {
                    // Grabs the touch on press, so that it never reaches a
                    // key underneath.
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: oskContainer.menuOpen = !oskContainer.menuOpen
                }
            }
        }

        // Over the keys while the menu is open, unscaled so that it stays
        // usable on a small keyboard (it's only shrunk to fit the window).
        Item {
            id: menuLayer
            anchors.fill: parent
            visible: oskContainer.menuOpen

            // A tap outside the menu closes it instead of typing.
            MultiPointTouchArea {
                anchors.fill: parent
                onPressed: oskContainer.menuOpen = false
            }

            OskMenu {
                id: oskMenu

                readonly property real fitScale: Math.min(1, (oskWindow.width - 8) / implicitWidth, (oskWindow.height - 8) / implicitHeight)
                readonly property real shownWidth: implicitWidth * fitScale
                readonly property real shownHeight: implicitHeight * fitScale
                // The menu button, in this window's coordinates.
                readonly property rect buttonRect: Qt.rect(menuButton.x * oskWindow.contentScale, menuButton.y * oskWindow.contentScale, menuButton.width * oskWindow.contentScale, menuButton.height * oskWindow.contentScale)
                // Beside the button in the corners, under or above it in
                // the middle; always inside the window.
                readonly property real wantedX: {
                    switch (menuButton.horizontal) {
                    case "left":
                        return buttonRect.x + buttonRect.width + 6;
                    case "right":
                        return buttonRect.x - 6 - shownWidth;
                    default:
                        return buttonRect.x + (buttonRect.width - shownWidth) / 2;
                    }
                }
                readonly property real wantedY: {
                    let top = menuButton.vertical === "top";
                    if (menuButton.horizontal === "center") {
                        return top ? buttonRect.y + buttonRect.height + 6 : buttonRect.y - 6 - shownHeight;
                    }
                    return top ? buttonRect.y : buttonRect.y + buttonRect.height - shownHeight;
                }

                width: implicitWidth
                height: implicitHeight
                scale: fitScale
                transformOrigin: Item.TopLeft
                x: Math.max(4, Math.min(wantedX, oskWindow.width - shownWidth - 4))
                y: Math.max(4, Math.min(wantedY, oskWindow.height - shownHeight - 4))

                onEditRequested: {
                    oskContainer.menuOpen = false;
                    oskContainer.editing = true;
                }
                onHideRequested: oskContainer.setShown(false)
            }
        }
    }

    OskEditOverlay {
        visible: oskContainer.editing && oskWindow.visible
        screen: oskWindow.screen
        naturalHeight: oskWindow.naturalHeight
        fitScale: oskWindow.fitScale
        keyboardWidth: oskWindow.keyboardWidth
        keyboardHeight: oskWindow.keyboardHeight
        floatLeft: oskWindow.floatLeft
        floatTop: oskWindow.floatTop
        edgeMargin: oskWindow.edgeMargin
        onDone: oskContainer.editing = false
    }
}
