pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/// Hand-edited options of the on-screen keyboard, kept in `osk.json` at the
/// root of this repository (gitignored, so each machine has its own). It is
/// created with the defaults below if it doesn't exist, and changes to it
/// apply right away. Invalid values fall back to the defaults.
///
/// - `menuButton.position`: where the button that opens the keyboard's menu
///   sits, one of `menuButtonPositions`. These are the spots the angled
///   halves leave free: the outer corners, and the notches between the
///   halves at the top and bottom.
///
/// Settings changed from the keyboard's own menu (position, size, volume)
/// are kept apart, in OskState.
Singleton {
    id: oskConfig

    readonly property var menuButtonPositions: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right"]
    readonly property string defaultMenuButtonPosition: "top-left"

    readonly property string menuButtonPosition: oskConfig.menuButtonPositions.includes(menuButtonAdapter.position) ? menuButtonAdapter.position : oskConfig.defaultMenuButtonPosition

    FileView {
        path: Quickshell.shellPath("../osk.json")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            property JsonObject menuButton: JsonObject {
                id: menuButtonAdapter

                property string position: oskConfig.defaultMenuButtonPosition

                onPositionChanged: {
                    if (!oskConfig.menuButtonPositions.includes(position)) {
                        console.warn(`OskConfig: menuButton.position "${position}" isn't one of ${oskConfig.menuButtonPositions.join(", ")}; using ${oskConfig.defaultMenuButtonPosition}`);
                    }
                }
            }
        }
    }
}
