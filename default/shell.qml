//@ pragma UseQApplication
import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
    // Panels are recreated whenever the primary screen changes: when an output
    // is unplugged the compositor closes its layer surfaces, and Quickshell
    // does not reopen a closed window just because its `screen` changes.
    Variants {
        model: AppConstants.primaryScreen ? [AppConstants.primaryScreen] : []

        PanelWindow {
            id: topPanelWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 42

            surfaceFormat.opaque: false
            color: AppConstants.bgColor

            RowLayout {
                spacing: 0
                anchors.fill: parent

                WorkspaceControl {
                    Layout.fillHeight: true
                    Layout.preferredWidth: preferredWidth
                    Layout.leftMargin: 5
                }

                WindowControls {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumWidth: preferredWidth
                }

                Rectangle {
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SystemTrayPanel {
                    Layout.fillHeight: true
                    Layout.preferredWidth: preferredWidth
                    trayMenuDisplayParent: topPanelWindow
                }

                BluetoothIndicator {
                    Layout.fillHeight: true
                    Layout.preferredWidth: preferredWidth
                }

                SoundIndicator {
                    Layout.fillHeight: true
                    Layout.preferredWidth: preferredWidth
                }

                OnScreenKeyboard {
                    Layout.fillHeight: true
                    Layout.preferredWidth: preferredWidth
                    layoutName: kbLayoutIndicator.currentLayoutName
                }

                KbLayoutIndicator {
                    id: kbLayoutIndicator
                    Layout.fillHeight: true
                    Layout.preferredWidth: preferredWidth
                }

                PowerIndicator {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }
            }
        }
    }

    Variants {
        model: AppConstants.primaryScreen ? [AppConstants.primaryScreen] : []

        PanelWindow {
            id: bottomPanelWindow
            required property var modelData
            screen: modelData

            anchors {
                bottom: true
                left: true
                right: true
            }
            implicitHeight: 42

            surfaceFormat.opaque: false
            color: AppConstants.bgColor

            RowLayout {
                spacing: 0
                anchors.fill: parent

                ProgramPicker {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }

                Rectangle {
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                NetworkIndicator {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }

                VpnIndicator {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }

                CpuIndicator {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }

                RamIndicator {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }

                GpuIndicator {
                    Layout.preferredWidth: preferredWidth
                    Layout.fillHeight: true
                }

                DateClock {
                    Layout.preferredWidth: childrenRect.width + 20
                    Layout.fillHeight: true
                }
            }
        }
    }

    // NotificationPanel {}
}
