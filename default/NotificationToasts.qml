import QtQuick
import QtQuick.Layouts
import Quickshell

// New notifications in the bottom-right corner of the screen, above the
// bottom bar, newest at the bottom. Clicking one opens the notification area
// on it. NotificationCenter decides which ones are shown and for how long.
PanelWindow {
    id: notificationToasts

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 8
        right: 8
    }

    visible: toastsRepeater.count > 0
    color: "transparent"
    surfaceFormat.opaque: false

    implicitWidth: 400
    // Rounded up: windows have whole-pixel sizes.
    implicitHeight: Math.max(1, Math.ceil(toastsLayout.implicitHeight))

    // The pointer can't leave a window that is gone.
    onVisibleChanged: {
        if (!visible) {
            NotificationCenter.toastsHovered = false;
        }
    }

    ColumnLayout {
        id: toastsLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        HoverHandler {
            onHoveredChanged: NotificationCenter.toastsHovered = hovered
        }

        Repeater {
            id: toastsRepeater
            model: ScriptModel {
                values: NotificationCenter.toasts
            }

            // The card slides in from the right edge of the screen.
            delegate: Item {
                id: toast
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: toastCard.implicitHeight

                NotificationCard {
                    id: toastCard
                    width: parent.width
                    notification: toast.modelData
                    compact: true
                    backgroundColor: AppConstants.solidBgColor
                    action: () => NotificationCenter.showInArea(toast.modelData)

                    NumberAnimation on x {
                        from: notificationToasts.implicitWidth
                        to: 0
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
