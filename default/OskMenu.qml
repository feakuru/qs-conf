import QtQuick

// The on-screen keyboard's menu, opened from its menu button:
//   [Float] [Top] [Bottom]        where the keyboard is (OskState.mode)
//   [Move / resize] [Hide]
//   [mute] [-] ████░░░░ 40% [+]   key sound volume
Rectangle {
    id: oskMenu

    signal editRequested
    signal hideRequested

    readonly property int padding: 10
    readonly property int spacing: 6
    readonly property int rowWidth: 3 * 84 + 2 * oskMenu.spacing
    readonly property int volumePercent: Math.round(OskState.volume * 100)
    readonly property int volumeStep: 5

    implicitWidth: menuColumn.implicitWidth + 2 * oskMenu.padding
    implicitHeight: menuColumn.implicitHeight + 2 * oskMenu.padding

    radius: 8
    color: AppConstants.solidBgColor
    border.width: 1
    border.color: AppConstants.indicatorBorderColor

    // Taps between the buttons mustn't reach the keys underneath.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: menuColumn
        x: oskMenu.padding
        y: oskMenu.padding
        spacing: oskMenu.spacing

        Row {
            spacing: oskMenu.spacing

            Repeater {
                model: [
                    {
                        mode: "floating",
                        label: "Float",
                        icon: "up-down-left-right"
                    },
                    {
                        mode: "top",
                        label: "Top",
                        icon: "arrows-up-to-line"
                    },
                    {
                        mode: "bottom",
                        label: "Bottom",
                        icon: "arrows-down-to-line"
                    }
                ]

                delegate: OskButton {
                    required property var modelData
                    width: (oskMenu.rowWidth - 2 * oskMenu.spacing) / 3
                    iconName: modelData.icon
                    label: modelData.label
                    highlighted: OskState.mode === modelData.mode
                    action: () => OskState.setMode(modelData.mode)
                }
            }
        }

        Row {
            spacing: oskMenu.spacing

            OskButton {
                width: (oskMenu.rowWidth - oskMenu.spacing) / 2
                iconName: "up-right-and-down-left-from-center"
                // Pinned, it spans the screen's width and can't be moved.
                label: OskState.floating ? "Move / resize" : "Resize"
                action: () => oskMenu.editRequested()
            }

            OskButton {
                width: (oskMenu.rowWidth - oskMenu.spacing) / 2
                iconName: "eye-slash"
                label: "Hide"
                action: () => oskMenu.hideRequested()
            }
        }

        Row {
            spacing: oskMenu.spacing

            OskButton {
                id: muteButton
                width: 44
                iconName: {
                    if (OskState.muted) {
                        return "volume-xmark";
                    }
                    if (oskMenu.volumePercent === 0) {
                        return "volume-off";
                    }
                    return oskMenu.volumePercent < 50 ? "volume-low" : "volume-high";
                }
                highlighted: OskState.muted
                activeIconColor: AppConstants.dangerColor
                action: () => OskState.setMuted(!OskState.muted)
            }

            OskButton {
                id: decreaseButton
                width: 44
                iconName: "minus"
                enabledAction: oskMenu.volumePercent > 0
                action: () => OskState.setVolume((oskMenu.volumePercent - oskMenu.volumeStep) / 100)
            }

            Rectangle {
                id: volumeBar
                width: oskMenu.rowWidth - 3 * 44 - 3 * oskMenu.spacing
                height: 44
                radius: 6
                color: AppConstants.cardBgColor
                border.width: 1
                border.color: AppConstants.indicatorBorderColor
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * OskState.volume
                    radius: parent.radius
                    color: OskState.muted ? AppConstants.mutedBarColor : AppConstants.indicatorBarColor
                }

                StyledText {
                    font.pixelSize: 16
                    color: OskState.muted ? AppConstants.mutedIconColor : AppConstants.styledTextColor
                    text: OskState.muted ? "muted" : `${oskMenu.volumePercent}%`
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onPressed: mouse => OskState.setVolume(mouse.x / width)
                    onPositionChanged: mouse => OskState.setVolume(mouse.x / width)
                }
            }

            OskButton {
                width: 44
                iconName: "plus"
                enabledAction: oskMenu.volumePercent < 100
                action: () => OskState.setVolume((oskMenu.volumePercent + oskMenu.volumeStep) / 100)
            }
        }
    }
}
