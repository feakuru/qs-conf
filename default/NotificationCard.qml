import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification: a header with the app's name, when it arrived and a close
// button; the image (or the app's icon) next to the summary and body; then
// the actions. Compact cards (toasts) cut the text short and leave out the
// actions.
Rectangle {
    id: card

    required property var notification
    property bool compact: false
    // Highlighted, e.g. after its toast was clicked.
    property bool focused: false
    // Called when the card itself (not one of its buttons) is clicked; the
    // card isn't clickable without one.
    property var action: null
    property color backgroundColor: AppConstants.cardBgColor

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property bool hasImage: notification.image !== ""
    readonly property string appIconSource: NotificationCenter.iconSource(notification.appIcon)
    // Clicking the notification is meant to invoke its "default" action,
    // which therefore gets no button.
    readonly property var defaultAction: notification.actions.find(a => a.identifier === "default") ?? null
    readonly property int padding: 10

    implicitHeight: cardLayout.implicitHeight + 2 * padding
    radius: 8
    color: card.action && (cardHover.hovered || cardMouseArea.pressed) ? AppConstants.focusedSolidBgColor : card.backgroundColor
    border.width: card.focused ? 2 : 1
    border.color: card.focused ? AppConstants.indicatorOnColor : card.critical ? AppConstants.dangerColor : AppConstants.indicatorBorderColor

    // See DropdownMenuItem for why hover is tracked by a HoverHandler.
    HoverHandler {
        id: cardHover
        cursorShape: card.action ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    // Below the content, so that buttons and links get their clicks first.
    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        enabled: card.action !== null
        onClicked: card.action()
    }

    ColumnLayout {
        id: cardLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // The big icon spot shows the image instead.
            IconImage {
                visible: card.hasImage && card.appIconSource !== ""
                implicitSize: 16
                source: visible ? card.appIconSource : ""
            }

            StyledText {
                anchors.centerIn: undefined
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 12
                color: AppConstants.mutedIconColor
                textFormat: Text.PlainText
                elide: Text.ElideRight
                text: (card.notification.appName || "Notification").toUpperCase()
            }

            StyledText {
                anchors.centerIn: undefined
                font.pixelSize: 12
                color: AppConstants.mutedIconColor
                text: NotificationCenter.ageText(card.notification)
            }

            WindowActionButton {
                implicitWidth: 24
                implicitHeight: 24
                iconName: "xmark"
                action: () => card.notification.dismiss()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ClippingRectangle {
                id: avatar
                readonly property string source: card.hasImage ? card.notification.image : card.appIconSource

                visible: source !== "" && avatarImage.status !== Image.Error
                Layout.alignment: Qt.AlignTop
                implicitWidth: card.compact ? 40 : 48
                implicitHeight: implicitWidth
                radius: 6
                color: "transparent"

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: avatar.source
                    // Photos fill the square; app icons keep their shape.
                    fillMode: card.hasImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    sourceSize.width: avatar.implicitWidth * 2
                    sourceSize.height: avatar.implicitHeight * 2
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                StyledText {
                    anchors.centerIn: undefined
                    Layout.fillWidth: true
                    visible: text !== ""
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 15
                    font.bold: true
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: card.compact ? 1 : 3
                    elide: Text.ElideRight
                    text: card.notification.summary
                }

                // The body may contain simple markup and links.
                StyledText {
                    anchors.centerIn: undefined
                    Layout.fillWidth: true
                    visible: text !== ""
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 13
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: card.compact ? 2 : 20
                    elide: Text.ElideRight
                    linkColor: AppConstants.indicatorOnColor
                    text: card.notification.body.replace(/\n/g, "<br>")
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: !card.compact && (card.notification.hasInlineReply || card.notification.actions.some(a => a.identifier !== "default"))
            spacing: 6

            Repeater {
                model: card.notification.actions

                delegate: ActionButton {
                    required property var modelData
                    visible: modelData.identifier !== "default"
                    text: modelData.text
                    // With action icons, identifiers are icon names.
                    iconSource: card.notification.hasActionIcons ? NotificationCenter.iconSource(modelData.identifier) : ""
                    action: () => modelData.invoke()
                }
            }

            ActionButton {
                visible: card.notification.hasInlineReply
                text: card.notification.inlineReplyPlaceholder || "Reply"
                iconName: "reply"
                action: () => NotificationCenter.replyRequested(card.notification)
            }
        }
    }

    component ActionButton: Rectangle {
        id: actionButton

        property string text: ""
        // A theme icon (iconSource) or a Font Awesome one (iconName).
        property string iconSource: ""
        property string iconName: ""
        property var action: () => {}

        implicitWidth: actionButtonContent.implicitWidth + 20
        implicitHeight: 28
        radius: 6
        color: actionButtonHover.hovered || actionButtonMouseArea.pressed ? AppConstants.focusedSolidBgColor : "transparent"
        border.width: 1
        border.color: AppConstants.indicatorBorderColor

        RowLayout {
            id: actionButtonContent
            anchors.centerIn: parent
            spacing: 6

            IconImage {
                visible: actionButton.iconSource !== ""
                implicitSize: 14
                source: actionButton.iconSource
            }

            RecoloredIcon {
                visible: actionButton.iconName !== ""
                iconWidth: 12
                iconHeight: 12
                source: actionButton.iconName === "" ? "" : Qt.resolvedUrl(`assets/icons/fontawesome/solid/${actionButton.iconName}.svg`)
                iconColor: AppConstants.styledTextColor
            }

            StyledText {
                anchors.centerIn: undefined
                font.pixelSize: 13
                textFormat: Text.PlainText
                text: actionButton.text
            }
        }

        HoverHandler {
            id: actionButtonHover
            cursorShape: Qt.PointingHandCursor
        }

        MouseArea {
            id: actionButtonMouseArea
            anchors.fill: parent
            onClicked: actionButton.action()
        }
    }
}
