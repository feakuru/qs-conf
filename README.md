# My Quickshell config

This is my personal config for Quickshell. It includes a top bar and a bottom bar and multiple widgets. I should write/record a proper explanation here when I develop a fully functional version.

## Dependencies

This list might not be exhaustive. I am running this over Arch with Gnome installed, so a lot of deps are already available by default.

- `jq`
- `sar`
- `nmcli`
- `nethogs`, for per-process network usage in the network dropdown (see below)
- `pactl`
- `sensors`
- `uv` with a Python 3.12 or greater available
- `xdg-terminal-exec` (available on Arch only as a separate AUR at the time of writing)
- need to fill in values in `qs-osk.service` and add it to systemd services (enable and start)

### nethogs setup

The network dropdown lists the processes using the most bandwidth, measured by `nethogs` (only while the dropdown is open). `nethogs` captures packets, so to run it without root it needs these capabilities on its binary:

```sh
sudo pacman -S nethogs
sudo setcap "cap_net_admin,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+pe" "$(command -v nethogs)"
```

Check with `getcap "$(command -v nethogs)"`. Package upgrades replace the binary and drop the capabilities, so re-run `setcap` after `nethogs` updates (or add a pacman hook for it). Without them, the dropdown shows the error instead of the process list.

The GPU dropdown's process list needs no setup: it reads DRM fdinfo from `/proc` (AMD, Intel and other DRM drivers; only your own processes are visible) or uses `nvidia-smi pmon` on NVIDIA.
