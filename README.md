# My Quickshell config

This is my personal config for Quickshell. It includes a top bar and a bottom bar and multiple widgets. I should write/record a proper explanation here when I develop a fully functional version.

## Dependencies

This list might not be exhaustive. I am running this over Arch with Gnome installed, so a lot of deps are already available by default.

- `jq`
- `sar`
- `nmcli`
- `pactl`
- `sensors`
- `uv` with a Python 3.12 or greater available
- `xdg-terminal-exec` (available on Arch only as a separate AUR at the time of writing)
- need to fill in values in `qs-osk.service` and add it to systemd services (enable and start)
