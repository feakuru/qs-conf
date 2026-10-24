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

        Scope {
            id: screenScope
            required property var modelData

            Bar {
                screen: screenScope.modelData

                WorkspaceControl {
                    Layout.leftMargin: 5
                }

                Separator {
                    visible: windowControls.hasWindows
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                }

                // Takes up all the space between the workspaces and the
                // right-hand widgets.
                WindowControls {
                    id: windowControls
                }

                SystemTrayPanel {
                    id: systemTrayPanel
                }

                Separator {
                    visible: systemTrayPanel.hasItems
                }

                BluetoothIndicator {}

                Separator {}

                SoundIndicator {}

                Separator {}

                OnScreenKeyboard {
                    layoutName: kbLayoutIndicator.currentLayoutName
                }

                Separator {}

                KbLayoutIndicator {
                    id: kbLayoutIndicator
                }

                Separator {}

                DiskIndicator {}

                Separator {}

                ScreenshotMenu {}

                Separator {}

                PowerIndicator {}
            }

            Bar {
                screen: screenScope.modelData
                atBottom: true

                ProgramPicker {}

                Item {
                    Layout.fillWidth: true
                }

                NetworkIndicator {}

                Separator {}

                VpnIndicator {}

                Separator {}

                CpuIndicator {}

                Separator {}

                RamIndicator {}

                Separator {}

                GpuIndicator {}

                Separator {}

                DateClock {}
            }

            NotificationToasts {
                screen: screenScope.modelData
            }
        }
    }
}
