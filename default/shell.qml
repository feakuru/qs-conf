//@ pragma UseQApplication
import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: mainPanelWindow

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

        CpuIndicator {
            Layout.preferredWidth: preferredWidth
            Layout.fillHeight: true
        }

        RamIndicator {
            Layout.preferredWidth: preferredWidth
            Layout.fillHeight: true
        }

        Rectangle {
            color: "transparent"
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        SystemTrayPanel {
            Layout.fillHeight: true
            Layout.preferredWidth: preferredWidth
        }

        NetworkIndicator {
            Layout.preferredWidth: preferredWidth
            Layout.fillHeight: true
        }

        BluetoothIndicator {
            Layout.fillHeight: true
            Layout.preferredWidth: preferredWidth
        }

        SoundIndicator {
            Layout.fillHeight: true
            Layout.preferredWidth: childrenRect.width + 20
        }

        KbLayoutIndicator {
            Layout.fillHeight: true
            Layout.preferredWidth: preferredWidth
        }

        DateClock {
            Layout.preferredWidth: childrenRect.width + 20
            Layout.fillHeight: true
        }

        PowerIndicator {
            Layout.preferredWidth: childrenRect.width + 20
            Layout.fillHeight: true
        }
    }

    ToplevelTitle {}

    NotificationPanel {}
}
