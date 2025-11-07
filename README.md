# My Quickshell config

This is my personal config for Quickshell. It includes a top bar and a bottom bar and multiple widgets. I should write/record a proper explanation here when I develop a fully functional version.

## Dependencies
- `jq`
- `sar`
- `nmcli`
- `pactl`
- `uv` with a Python 3.12 or greater available
- `xdg-terminal-exec` (available on Arch only as a separate AUR at the time of writing)
        // TODO:
        // use `nmcli -t -f GENERAL.DEVICE,IP4.GATEWAY dev show` to get this:
        // GENERAL.DEVICE:enp4s0
        // IP4.GATEWAY:192.168.0.1      <-- means it is used for internet (duh)
        // GENERAL.DEVICE:someotherdev
        // IP4.GATEWAY:

