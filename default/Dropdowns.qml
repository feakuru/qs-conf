pragma Singleton
import Quickshell

// Tracks which dropdown (or launcher) is open, so that opening one closes the
// others.
Singleton {
    property var current: null
    // Every existing DropdownMenu; they add and remove themselves.
    property var menus: []
    // Menus that show a key label (see DropdownHints): the menu at index i is
    // toggled with hintKeys[i]. Empty while the labels are hidden.
    property var hintedMenus: []
    readonly property string hintKeys: "asdfghjklqwertyuiopzxcvbnm"
}
