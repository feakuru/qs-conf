import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Asks for an inline reply to a notification, centred on the screen. Like
// WifiPasswordPrompt, it uses its own layer-shell window, because typing needs
// keyboard focus, which popups can't reliably get. It closes on Escape, on
// "Cancel", after sending, when the notification goes away, or when a
// dropdown is opened.
PanelWindow {
    id: replyPrompt

    property var notification: null
    readonly property bool replyValid: replyField.text.trim().length > 0

    function ask(notification) {
        replyPrompt.notification = notification;
        replyField.text = "";
        Dropdowns.current = replyPrompt;
        replyPrompt.visible = true;
        replyField.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    function hidePrompt() {
        replyField.text = "";
        replyPrompt.visible = false;
        if (Dropdowns.current === replyPrompt) {
            Dropdowns.current = null;
        }
    }

    function send() {
        if (!replyPrompt.replyValid) {
            return;
        }
        let notification = replyPrompt.notification;
        let reply = replyField.text.trim();
        replyPrompt.hidePrompt();
        if (notification && notification.tracked) {
            notification.sendInlineReply(reply);
        }
    }

    Connections {
        target: Dropdowns
        function onCurrentChanged() {
            if (Dropdowns.current !== replyPrompt && replyPrompt.visible) {
                replyPrompt.hidePrompt();
            }
        }
    }

    Connections {
        target: replyPrompt.notification
        ignoreUnknownSignals: true
        function onClosed(reason) {
            replyPrompt.hidePrompt();
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
            text: replyPrompt.notification && replyPrompt.notification.appName ? `Reply to ${replyPrompt.notification.appName}` : "Reply"
        }

        DropdownMenuItem {
            visible: summaryText.text !== ""
            showSeparator: false

            StyledText {
                id: summaryText
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 14
                color: AppConstants.mutedIconColor
                textFormat: Text.PlainText
                elide: Text.ElideRight
                text: replyPrompt.notification ? replyPrompt.notification.summary : ""
            }
        }

        DropdownMenuItem {
            implicitHeight: 42
            showSeparator: false

            TextField {
                id: replyField
                anchors.fill: parent
                anchors.margins: 5
                font.pixelSize: 18
                font.family: AppConstants.defaultFont
                placeholderText: replyPrompt.notification && replyPrompt.notification.inlineReplyPlaceholder ? replyPrompt.notification.inlineReplyPlaceholder : "Reply"
                onAccepted: replyPrompt.send()
                Keys.onEscapePressed: replyPrompt.hidePrompt()
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
                opacity: replyPrompt.replyValid ? 1 : 0.4
                action: () => replyPrompt.send()
                StyledText {
                    font.pixelSize: 18
                    text: "Send"
                }
            }

            Separator {
                thickness: 1
            }

            DropdownMenuItem {
                action: () => replyPrompt.hidePrompt()
                StyledText {
                    font.pixelSize: 18
                    text: "Cancel"
                }
            }
        }
    }
}
