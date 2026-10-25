import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// The notification area at the top of DateClock's menu: a header with
// do-not-disturb and clear-all buttons, then the notifications, newest first,
// at most maxListHeight tall (the rest scrolls). Scrolls to and highlights
// the notification whose toast was clicked (NotificationCenter.focusedId).
ColumnLayout {
    id: notificationList

    property int maxListHeight: 460

    function scrollToFocused() {
        let target = 0;
        for (let i = 0; i < cardsRepeater.count; i++) {
            let card = cardsRepeater.itemAt(i);
            if (card && card.notification.id === NotificationCenter.focusedId) {
                target = card.y - (listFlickable.height - card.height) / 2;
                break;
            }
        }
        scrollAnimation.to = Math.max(0, Math.min(target, listFlickable.contentHeight - listFlickable.height));
        scrollAnimation.restart();
    }

    Layout.fillWidth: true
    spacing: 0

    Connections {
        target: NotificationCenter

        function onFocusRequested() {
            // The menu has only just been shown; let its layout settle first.
            scrollTimer.restart();
        }

        function onAreaOpenChanged() {
            if (NotificationCenter.areaOpen && NotificationCenter.focusedId < 0) {
                listFlickable.contentY = 0;
            }
        }
    }

    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: notificationList.scrollToFocused()
    }

    NumberAnimation {
        id: scrollAnimation
        target: listFlickable
        property: "contentY"
        duration: 250
        easing.type: Easing.OutCubic
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 8
        Layout.minimumHeight: 42
        spacing: 4

        StyledText {
            anchors.centerIn: undefined
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 18
            text: "NOTIFICATIONS"
        }

        StyledText {
            anchors.centerIn: undefined
            Layout.fillWidth: true
            Layout.leftMargin: 4
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            color: AppConstants.mutedIconColor
            text: NotificationCenter.count > 0 ? NotificationCenter.count : ""
        }

        WindowActionButton {
            iconName: NotificationCenter.doNotDisturb ? "bell-slash" : "bell"
            highlighted: NotificationCenter.doNotDisturb
            action: () => NotificationCenter.doNotDisturb = !NotificationCenter.doNotDisturb
        }

        WindowActionButton {
            iconName: "trash-can"
            enabledAction: NotificationCenter.count > 0
            activeIconColor: AppConstants.dangerColor
            action: () => NotificationCenter.dismissAll()
        }
    }

    StyledText {
        anchors.centerIn: undefined
        visible: NotificationCenter.count === 0
        Layout.fillWidth: true
        Layout.bottomMargin: 12
        font.pixelSize: 14
        color: AppConstants.mutedIconColor
        text: NotificationCenter.doNotDisturb ? "no notifications · do not disturb on" : "no notifications"
    }

    Flickable {
        id: listFlickable
        visible: NotificationCenter.count > 0
        Layout.fillWidth: true
        implicitHeight: Math.min(cardsLayout.implicitHeight, notificationList.maxListHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: cardsLayout.implicitHeight

        ScrollBar.vertical: ScrollBar {
            id: listScrollBar
            // Hover-enabled controls swallow hover events, which would hide
            // the pointer from the menu (see DropdownMenu.qml).
            hoverEnabled: false
            policy: listFlickable.contentHeight > listFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: cardsLayout
            width: listFlickable.width - (listScrollBar.policy === ScrollBar.AlwaysOn ? listScrollBar.width : 0)
            spacing: 6

            Repeater {
                id: cardsRepeater
                // ScriptModel keeps the cards of notifications that are still
                // there when one comes or goes.
                model: ScriptModel {
                    values: NotificationCenter.notifications.slice().reverse()
                }

                delegate: NotificationCard {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    notification: modelData
                    focused: modelData.id === NotificationCenter.focusedId
                    action: defaultAction ? () => defaultAction.invoke() : null
                }
            }

            // Space below the last card (on top of the spacing).
            Item {
                implicitHeight: 2
            }
        }
    }

    Separator {
        vertical: false
        thickness: 1
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
    }
}
