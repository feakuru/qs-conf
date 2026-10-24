pragma Singleton
import Quickshell

// Tracks which dropdown (or launcher) is open, so that opening one closes the
// others.
Singleton {
    property var current: null
}
