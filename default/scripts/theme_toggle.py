"""Single source of truth for the desktop-wide dark/light colour scheme.

The mode is persisted to ``$XDG_STATE_HOME/quickshell/theme-mode`` so it
survives a Hyprland/quickshell restart, and `apply` re-projects that stored
mode onto every toolkit that needs to be told about it:

* GTK4/libadwaita   -> ``org.gnome.desktop.interface color-scheme``
* GTK3              -> ``org.gnome.desktop.interface gtk-theme`` (Adwaita[-dark])
* icons             -> ``org.gnome.desktop.interface icon-theme`` (Papirus-{Dark,Light})
* Qt (qt6ct)        -> ``~/.config/qt6ct/qt6ct.conf`` palette + icon theme

Every backend is best-effort: a missing binary/theme/config is reported on
stderr and skipped instead of aborting the whole switch.
"""

import argparse
import configparser
import os
import subprocess
import sys
from pathlib import Path

DARK = "dark"
LIGHT = "light"
MODES = (DARK, LIGHT)

GSETTINGS_SCHEMA = "org.gnome.desktop.interface"

# gsettings key -> {mode: value}. Values that name a theme are validated
# against the installed themes before being applied.
GSETTINGS_KEYS: dict[str, dict[str, str]] = {
    "color-scheme": {DARK: "prefer-dark", LIGHT: "prefer-light"},
    "gtk-theme": {DARK: "Adwaita-dark", LIGHT: "Adwaita"},
    "icon-theme": {DARK: "Papirus-Dark", LIGHT: "Papirus-Light"},
}

QT6CT_CONF = Path.home() / ".config" / "qt6ct" / "qt6ct.conf"
QT6CT_COLOR_SCHEMES = {
    DARK: "/usr/share/qt6ct/colors/darker.conf",
    LIGHT: "/usr/share/qt6ct/colors/airy.conf",
}

ICON_THEME_DIRS = (
    Path.home() / ".local" / "share" / "icons",
    Path("/usr/share/icons"),
)
GTK_THEME_DIRS = (
    Path.home() / ".themes",
    Path.home() / ".local" / "share" / "themes",
    Path("/usr/share/themes"),
)
# GTK ships these two in-tree, so they are usable even with no directory on disk.
GTK_BUILTIN_THEMES = frozenset({"Adwaita", "Adwaita-dark"})


def warn(message: str) -> None:
    print(f"theme_toggle: {message}", file=sys.stderr)


def state_file() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    return Path(base) / "quickshell" / "theme-mode"


def read_state() -> str | None:
    path = state_file()
    try:
        value = path.read_text().strip()
    except OSError:
        return None
    return value if value in MODES else None


def write_state(mode: str) -> None:
    path = state_file()
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"{mode}\n")
    except OSError as exc:
        warn(f"could not persist mode to {path}: {exc}")


def gsettings_get(key: str) -> str | None:
    try:
        result = subprocess.run(
            ["gsettings", "get", GSETTINGS_SCHEMA, key],
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        warn(f"gsettings get {key} failed: {exc}")
        return None
    return result.stdout.strip().strip("'")


def gsettings_set(key: str, value: str) -> None:
    try:
        subprocess.run(
            ["gsettings", "set", GSETTINGS_SCHEMA, key, value],
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        warn(f"gsettings set {key} {value} failed: {exc}")


def theme_installed(name: str, search_dirs: tuple[Path, ...]) -> bool:
    return any((directory / name).is_dir() for directory in search_dirs)


def resolve_theme(key: str, value: str) -> str | None:
    """Return `value` if the named theme can actually be loaded, else None."""
    if key == "icon-theme":
        if theme_installed(value, ICON_THEME_DIRS):
            return value
        warn(f"icon theme {value!r} is not installed, keeping the current one")
        return None
    if key == "gtk-theme":
        if value in GTK_BUILTIN_THEMES or theme_installed(value, GTK_THEME_DIRS):
            return value
        warn(f"gtk theme {value!r} is not installed, keeping the current one")
        return None
    return value


def apply_gsettings(mode: str) -> None:
    for key, per_mode in GSETTINGS_KEYS.items():
        value = resolve_theme(key, per_mode[mode])
        if value is not None:
            gsettings_set(key, value)


def apply_qt6ct(mode: str) -> None:
    """Patch qt6ct's palette/icon theme in place.

    qt6ct watches its own config file, so already-running Qt apps pick the new
    palette up without a restart.
    """
    if not QT6CT_CONF.is_file():
        warn(f"{QT6CT_CONF} not found, skipping Qt theming")
        return

    color_scheme = QT6CT_COLOR_SCHEMES[mode]
    if not Path(color_scheme).is_file():
        warn(f"qt6ct colour scheme {color_scheme} is missing, skipping Qt theming")
        return

    parser = configparser.ConfigParser(interpolation=None)
    # qt6ct keys are case sensitive and contain raw values; keep them verbatim.
    parser.optionxform = str  # type: ignore[method-assign, assignment]
    try:
        parser.read(QT6CT_CONF)
    except (OSError, configparser.Error) as exc:
        warn(f"could not parse {QT6CT_CONF}: {exc}")
        return

    if not parser.has_section("Appearance"):
        parser.add_section("Appearance")
    parser.set("Appearance", "color_scheme_path", color_scheme)
    parser.set("Appearance", "custom_palette", "true")

    icon_theme = resolve_theme("icon-theme", GSETTINGS_KEYS["icon-theme"][mode])
    if icon_theme is not None:
        parser.set("Appearance", "icon_theme", icon_theme)

    tmp = QT6CT_CONF.with_suffix(QT6CT_CONF.suffix + ".tmp")
    try:
        with tmp.open("w") as handle:
            parser.write(handle, space_around_delimiters=False)
        tmp.replace(QT6CT_CONF)
    except OSError as exc:
        tmp.unlink(missing_ok=True)
        warn(f"could not write {QT6CT_CONF}: {exc}")


def current_mode() -> str:
    """Effective mode: persisted preference first, live gsettings as fallback."""
    stored = read_state()
    if stored is not None:
        return stored
    scheme = gsettings_get("color-scheme")
    return LIGHT if scheme == "prefer-light" else DARK


def apply_mode(mode: str) -> None:
    apply_gsettings(mode)
    apply_qt6ct(mode)


def set_mode(mode: str) -> str:
    write_state(mode)
    apply_mode(mode)
    return mode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("get", help="print the effective mode")
    sub.add_parser("toggle", help="switch between dark and light")
    sub.add_parser("apply", help="re-apply the persisted mode (use at session start)")
    set_parser = sub.add_parser("set", help="switch to an explicit mode")
    set_parser.add_argument("mode", choices=MODES)

    args = parser.parse_args()

    if args.command == "get":
        print(current_mode())
    elif args.command == "apply":
        print(set_mode(current_mode()))
    elif args.command == "set":
        print(set_mode(args.mode))
    elif args.command == "toggle":
        print(set_mode(LIGHT if current_mode() == DARK else DARK))

    return 0


if __name__ == "__main__":
    sys.exit(main())
