//@ pragma UseQApplication
import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
    PanelWindow {
        id: topPanelWindow

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

            KbLayoutIndicator {
                Layout.fillHeight: true
                Layout.preferredWidth: preferredWidth
            }

            PowerIndicator {
                Layout.preferredWidth: preferredWidth
                Layout.fillHeight: true
            }
        }
    }

    PanelWindow {
        id: bottomPanelWindow

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
            CpuIndicator {
                Layout.preferredWidth: preferredWidth
                Layout.fillHeight: true
            }

            RamIndicator {
                Layout.preferredWidth: preferredWidth
                Layout.fillHeight: true
            }

            NetworkIndicator {
                Layout.preferredWidth: preferredWidth
                Layout.fillHeight: true
            }

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            SoundIndicator {
                Layout.fillHeight: true
                Layout.preferredWidth: preferredWidth
            }

            DateClock {
                Layout.preferredWidth: childrenRect.width + 20
                Layout.fillHeight: true
            }
        }
    }

    NotificationPanel {}
}
