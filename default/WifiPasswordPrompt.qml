import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Asks for the password of a Wi-Fi network, centred on the screen. Like
// ProgramPicker, it uses its own layer-shell window, because typing needs
// keyboard focus, which popups can't reliably get. It closes on Escape, on
// "Cancel", after submitting, or when a dropdown is opened.
PanelWindow {
    id: wifiPasswordPrompt

    property var network: null
    property string message: ""
    // WPA passphrases are 8 to 63 characters long.
    readonly property bool passwordValid: passwordField.text.length >= 8 && passwordField.text.length <= 63

    signal submitted(var network, string password)
    signal cancelled(var network)

    function ask(network, message) {
        wifiPasswordPrompt.network = network;
        wifiPasswordPrompt.message = message;
        passwordField.text = "";
        passwordField.echoMode = TextInput.Password;
        Dropdowns.current = wifiPasswordPrompt;
        wifiPasswordPrompt.visible = true;
        passwordField.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function hidePrompt() {
        wifiPasswordPrompt.visible = false;
        if (Dropdowns.current === wifiPasswordPrompt) {
            Dropdowns.current = null;
        }
    }

    function submit() {
        if (!wifiPasswordPrompt.passwordValid) {
            return;
        }
        let network = wifiPasswordPrompt.network;
        let password = passwordField.text;
        passwordField.text = "";
        wifiPasswordPrompt.hidePrompt();
        if (network) {
            wifiPasswordPrompt.submitted(network, password);
        }
    }

    function cancel() {
        let network = wifiPasswordPrompt.network;
        passwordField.text = "";
        wifiPasswordPrompt.hidePrompt();
        wifiPasswordPrompt.cancelled(network);
    }

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (Dropdowns.current !== wifiPasswordPrompt && wifiPasswordPrompt.visible) {
                wifiPasswordPrompt.cancel();
            }
        }
    }

    screen: AppConstants.primaryScreen
    visible: false
    focusable: true
    color: AppConstants.solidBgColor

    implicitWidth: 450
    // Rounded up: windows have whole-pixel sizes.
    implicitHeight: Math.max(1, Math.ceil(promptLayout.implicitHeight))

    ColumnLayout {
        id: promptLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        DropdownMenuHeader {
            text: wifiPasswordPrompt.network ? `Password for ${wifiPasswordPrompt.network.name}` : "Password"
        }

        DropdownMenuItem {
            visible: wifiPasswordPrompt.message !== ""
            StyledText {
                font.pixelSize: 16
                color: AppConstants.dangerColor
                text: wifiPasswordPrompt.message
            }
        }

        DropdownMenuItem {
            implicitHeight: 42
            showSeparator: false

            TextField {
                id: passwordField
                anchors.left: parent.left
                anchors.right: showPasswordButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 5
                font.pixelSize: 18
                font.family: AppConstants.defaultFont
                echoMode: TextInput.Password
                placeholderText: "Wi-Fi password"
                onAccepted: wifiPasswordPrompt.submit()
                Keys.onEscapePressed: wifiPasswordPrompt.cancel()
            }

            WindowActionButton {
                id: showPasswordButton
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                iconName: passwordField.echoMode === TextInput.Password ? "eye" : "eye-slash"
                action: () => {
                    passwordField.echoMode = passwordField.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password;
                    passwordField.forceActiveFocus();
                }
            }
        }

        Separator {
            vertical: false
            thickness: 1
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            DropdownMenuItem {
                opacity: wifiPasswordPrompt.passwordValid ? 1 : 0.4
                action: () => wifiPasswordPrompt.submit()
                StyledText {
                    font.pixelSize: 18
                    text: "Connect"
                }
            }

            Separator {
                thickness: 1
            }

            DropdownMenuItem {
                action: () => wifiPasswordPrompt.cancel()
                StyledText {
                    font.pixelSize: 18
                    text: "Cancel"
                }
            }
        }
    }
}
