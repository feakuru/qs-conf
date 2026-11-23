# My Quickshell config

This is my personal config for Quickshell. It includes a top bar and a bottom bar and multiple widgets. I should write/record a proper explanation here when I develop a fully functional version.

## Dependencies

This list might not be exhaustive. I am running this over Arch with Gnome installed, so a lot of deps are already available by default.

- [`qs-conf-daemon`](https://github.com/feakuru/qs-conf-daemon), installed and enabled as a systemd user service (see its README). It provides the system data (CPU, RAM, GPU, disk, network, VPN, keyboard state, brightness, Bluetooth rfkill) and the actions (theme, lock, screenshots, on-screen keyboard, running custom actions and their file chooser); its README also lists what it needs at runtime
- `ydotoold` running, for the on-screen keyboard (started by the Hyprland config)
- `pw-play` (part of PipeWire), for the on-screen keyboard's key sounds
- `nmcli`
- `nethogs`, for per-process network usage in the network dropdown (see below)
- `pactl`
- `hyprshot`
- a file manager implementing `org.freedesktop.FileManager1` (e.g. Nautilus), to show a screenshot in its folder (otherwise the folder is opened with `xdg-open`)
- `xdg-terminal-exec` (available on Arch only as a separate AUR at the time of writing)

### nethogs setup

The network dropdown lists the processes using the most bandwidth, measured by `nethogs` (run by `qs-conf-daemon`, only while the dropdown is open). `nethogs` captures packets, so to run it without root it needs these capabilities on its binary:

```sh
sudo pacman -S nethogs
sudo setcap "cap_net_admin,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+pe" "$(command -v nethogs)"
```

Check with `getcap "$(command -v nethogs)"`. Package upgrades replace the binary and drop the capabilities, so re-run `setcap` after `nethogs` updates (or add a pacman hook for it). Without them, the dropdown shows the error instead of the process list.

The GPU dropdown's process list needs no setup: it reads DRM fdinfo from `/proc` (AMD, Intel and other DRM drivers; only your own processes are visible) or uses NVML (the NVIDIA driver's `libnvidia-ml`) on NVIDIA.

## On-screen keyboard

The keyboard is toggled from its bar button or with `qs ipc call osk toggle`. The small `…` button on the keyboard (top-left by default) opens its menu, which has:
- Float / Top / Bottom: float it anywhere, or pin it to the top or bottom of the screen (pinned, windows make room for it);
- Move / resize: drag it around, or drag the handle to resize it;
- Hide;
- the key sound volume and mute.

These choices are saved in Quickshell's state directory. Options that are only set by hand go in `osk.json` at the root of this repository (gitignored, created with the defaults on first start, reloaded on save):

```json
{
    "menuButton": {
        "position": "top-left"
    }
}
```

`menuButton.position` is one of `top-left`, `top-center`, `top-right`, `bottom-left`, `bottom-center`, `bottom-right`.
