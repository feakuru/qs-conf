import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Confirmation for logging out, restarting or powering off: a dimmed
// full-screen overlay with a card in the middle. Like GNOME's, it runs the
// action by itself when the countdown ends. Enter confirms; Escape, "Cancel"
// or a click outside the card cancels.
//
// Uses its own layer-shell window, like ProgramPicker, because it needs
// keyboard focus, which popups can't reliably get.
PanelWindow {
    id: sessionActionDialog

    property var sessionAction: null
    readonly property int timeoutSeconds: 20
    property int remainingSeconds: timeoutSeconds

    // sessionAction.title: e.g. "Power off?"
    // sessionAction.countdownLabel: e.g. "Powering off in"
    // sessionAction.confirmLabel: e.g. "Power off"
    // sessionAction.iconName: FontAwesome icon of the confirm button
    // sessionAction.run: function performing the action
    function ask(sessionAction) {
        sessionActionDialog.sessionAction = sessionAction;
        sessionActionDialog.remainingSeconds = sessionActionDialog.timeoutSeconds;
        Dropdowns.current = sessionActionDialog;
        sessionActionDialog.visible = true;
        countdownTimer.restart();
        keyHandler.forceActiveFocus();
    }

    function cancel() {
        countdownTimer.stop();
        sessionActionDialog.visible = false;
        if (Dropdowns.current === sessionActionDialog) {
            Dropdowns.current = null;
        }
    }

    function confirm() {
        let sessionAction = sessionActionDialog.sessionAction;
        sessionActionDialog.cancel();
        if (sessionAction) {
            sessionAction.run();
        }
    }

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (Dropdowns.current !== sessionActionDialog && sessionActionDialog.visible) {
                sessionActionDialog.cancel();
            }
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            sessionActionDialog.remainingSeconds -= 1;
            if (sessionActionDialog.remainingSeconds <= 0) {
                sessionActionDialog.confirm();
            }
        }
    }

    screen: AppConstants.primaryScreen
    visible: false
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    surfaceFormat.opaque: false
    color: AppConstants.dialogScrimColor

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: sessionActionDialog.cancel()
        Keys.onReturnPressed: sessionActionDialog.confirm()
        Keys.onEnterPressed: sessionActionDialog.confirm()

        MouseArea {
            anchors.fill: parent
            onClicked: sessionActionDialog.cancel()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: dialogLayout.implicitHeight
        color: AppConstants.solidBgColor

        // Keeps clicks on the card from reaching the scrim behind it.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: dialogLayout
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            DropdownMenuHeader {
                text: sessionActionDialog.sessionAction ? sessionActionDialog.sessionAction.title : ""
            }

            UsageMenuItem {
                // The bar empties as the countdown runs out.
                label: sessionActionDialog.sessionAction ? sessionActionDialog.sessionAction.countdownLabel : ""
                valueText: `${sessionActionDialog.remainingSeconds} s`
                percent: sessionActionDialog.remainingSeconds / sessionActionDialog.timeoutSeconds * 100
                barColor: AppConstants.dangerBarColor
            }

            Separator {
                vertical: false
                thickness: 1
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                IconMenuItem {
                    iconNames: ["xmark"]
                    text: "Cancel"
                    action: () => sessionActionDialog.cancel()
                }

                Separator {
                    thickness: 1
                }

                IconMenuItem {
                    iconNames: sessionActionDialog.sessionAction ? [sessionActionDialog.sessionAction.iconName] : []
                    iconColor: AppConstants.dangerColor
                    text: sessionActionDialog.sessionAction ? sessionActionDialog.sessionAction.confirmLabel : ""
                    action: () => sessionActionDialog.confirm()
                }
            }
        }
    }
}
