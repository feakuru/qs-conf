"""Stream disks, their filesystems and the processes doing the most disk I/O as JSON lines for DiskIndicator.qml.

Runs until killed; DiskIndicator only keeps it alive while its menu is open.

Each line: {
    "disks": [{
        "name": str,   kernel name, e.g. "nvme0n1"; empty for the "Other" group
        "title": str,  e.g. "HFB1M8MO331C0MR (nvme0n1) · 238.5 GiB"
        "mounts": [{"id": str, "label": str, "details": str}, ...],
    }, ...],
    "stats": {
        "disk:<name>": {"label": str, "value": str, "percent": float},
        "mount:<id>": {"value": str, "detail": str, "percent": float},
    },
    "processes": [{"name": str, "pid": int, "percent": float, "value": str}, ...],
}
`disks` only describes the layout and rarely changes; the numbers are in
`stats`, so the menu can keep its rows while they update.

A disk's percentage is how busy it was; a filesystem's is how full it is.
Filesystems are listed under the physical disk they are on, following
partitions and device-mapper layers (LUKS, LVM); a device mounted in several
places (e.g. btrfs subvolumes) is one row. Filesystems not on a physical disk
(e.g. loop-mounted images) are listed under "Other".

Process percentages are a share of all I/O done by the listed processes. Only
the current user's processes can be inspected without root.
"""

import os
import time
from dataclasses import dataclass, field

import psutil

from disk_io import DiskIoSampler, DiskRates, SYS_BLOCK, physical_disks, read_sys_int, read_sys_text
from json_stream import stream_json_lines

INTERVAL_S = 1.0
FIRST_INTERVAL_S = 0.3
# More than the menu shows at once; the rest scroll.
TOP_PROCESS_COUNT = 10
SYS_CLASS_BLOCK = "/sys/class/block"
SECTOR_SIZE = 512
# Read-only images (e.g. snaps) that would only clutter the list.
SKIPPED_FSTYPES = {"squashfs"}
KIB = 1024
SIZE_UNITS = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]

type ProcessInfo = dict[str, str | int | float]


def format_size(size: float) -> str:
    unit = 0
    while size >= 1000 and unit < len(SIZE_UNITS) - 1:
        size /= KIB
        unit += 1
    return f"{size:.0f} {SIZE_UNITS[unit]}" if unit == 0 else f"{size:.1f} {SIZE_UNITS[unit]}"


def format_rate(rate: float) -> str:
    return f"{format_size(rate)}/s"


def format_usage(used: float, total: float) -> str:
    """E.g. "180.1 / 225.3 GiB", or "800.0 MiB / 1.5 GiB" when the units differ."""
    used_text, total_text = format_size(used), format_size(total)
    used_number, _, used_unit = used_text.partition(" ")
    if used_unit == total_text.partition(" ")[2]:
        return f"{used_number} / {total_text}"
    return f"{used_text} / {total_text}"


def backing_disks(name: str) -> set[str]:
    """The block devices at the bottom of `name`'s stack, e.g. dm-0 -> {"nvme0n1"}."""
    path = os.path.join(SYS_CLASS_BLOCK, name)
    if os.path.exists(os.path.join(path, "partition")):
        # A partition's sysfs directory is inside its disk's.
        return {os.path.basename(os.path.dirname(os.path.realpath(path)))}
    try:
        slaves = os.listdir(os.path.join(path, "slaves"))
    except OSError:
        slaves = []
    if not slaves:
        return {name}
    return set().union(*(backing_disks(slave) for slave in slaves))


def disk_title(disk: str) -> str:
    model = " ".join(read_sys_text(os.path.join(SYS_BLOCK, disk, "device", "model")).split())
    size = read_sys_int(os.path.join(SYS_BLOCK, disk, "size")) * SECTOR_SIZE
    parts = [f"{model} ({disk})" if model else disk, format_size(size)]
    if read_sys_text(os.path.join(SYS_BLOCK, disk, "removable")) == "1":
        parts.append("removable")
    return " · ".join(parts)


@dataclass
class Filesystem:
    device: str  # resolved, e.g. /dev/dm-0
    display_device: str  # as mounted, without /dev/, e.g. mapper/root
    fstype: str
    mountpoints: list[str] = field(default_factory=list)


def mounted_filesystems() -> list[Filesystem]:
    filesystems: dict[str, Filesystem] = {}
    for partition in psutil.disk_partitions(all=False):
        if not partition.device.startswith("/dev/") or partition.fstype in SKIPPED_FSTYPES:
            continue
        device = os.path.realpath(partition.device)
        filesystem = filesystems.setdefault(
            device,
            Filesystem(device, partition.device.removeprefix("/dev/"), partition.fstype),
        )
        filesystem.mountpoints.append(partition.mountpoint)
    for filesystem in filesystems.values():
        filesystem.mountpoints.sort(key=lambda mountpoint: (len(mountpoint), mountpoint))
    return sorted(filesystems.values(), key=lambda filesystem: filesystem.mountpoints[0])


def disk_layout(disks: list[str], filesystems: list[Filesystem]) -> list[dict[str, object]]:
    mounts_by_disk: dict[str, list[dict[str, str]]] = {disk: [] for disk in disks}
    other_mounts: list[dict[str, str]] = []
    for filesystem in filesystems:
        mount = {
            "id": filesystem.device,
            "label": ", ".join(filesystem.mountpoints),
            "details": f"{filesystem.display_device} · {filesystem.fstype}",
        }
        backing = sorted(backing_disks(os.path.basename(filesystem.device)) & set(disks))
        if backing:
            mounts_by_disk[backing[0]].append(mount)
        else:
            other_mounts.append(mount)

    layout: list[dict[str, object]] = [
        {"name": disk, "title": disk_title(disk), "mounts": mounts_by_disk[disk]} for disk in disks
    ]
    if other_mounts:
        layout.append({"name": "", "title": "Other", "mounts": other_mounts})
    return layout


def disk_stats(rates: DiskRates | None) -> dict[str, object]:
    if rates is None:
        return {"label": "…", "value": "", "percent": 0}
    return {
        "label": f"R {format_rate(rates.read)} · W {format_rate(rates.write)}",
        "value": f"{rates.busy:.0f}% busy",
        "percent": round(rates.busy, 1),
    }


def filesystem_stats(filesystem: Filesystem) -> dict[str, object]:
    try:
        usage = psutil.disk_usage(filesystem.mountpoints[0])
    except OSError:
        return {"value": "unavailable", "detail": "", "percent": 0}
    return {
        "value": f"{format_usage(usage.used, usage.total)} · {usage.percent:.0f}%",
        "detail": f"{format_size(usage.free)} free",
        "percent": usage.percent,
    }


class ProcessIoSampler:
    def __init__(self) -> None:
        # pid -> (bytes read, bytes written)
        self.previous: dict[int, tuple[int, int]] = {}
        self.previous_time = time.monotonic()

    def top_processes(self) -> list[ProcessInfo]:
        now = time.monotonic()
        elapsed = now - self.previous_time
        current: dict[int, tuple[int, int]] = {}
        samples: list[tuple[float, float, int, str]] = []
        for proc in psutil.process_iter(["name", "io_counters"]):
            # None for other users' processes, whose I/O counters are private.
            io_counters = proc.info["io_counters"]
            if io_counters is None:
                continue
            current[proc.pid] = (io_counters.read_bytes, io_counters.write_bytes)
            previous = self.previous.get(proc.pid)
            if previous is None or elapsed <= 0:
                continue
            read = max(io_counters.read_bytes - previous[0], 0) / elapsed
            write = max(io_counters.write_bytes - previous[1], 0) / elapsed
            if read + write > 0:
                samples.append((read, write, proc.pid, proc.info["name"] or str(proc.pid)))
        self.previous = current
        self.previous_time = now

        total = sum(read + write for read, write, _, _ in samples)
        samples.sort(key=lambda sample: sample[0] + sample[1], reverse=True)
        return [
            {
                "name": name,
                "pid": pid,
                "percent": round((read + write) / total * 100, 1),
                "value": f"R {format_rate(read)} · W {format_rate(write)}",
            }
            for read, write, pid, name in samples[:TOP_PROCESS_COUNT]
        ]


class DiskDetailsSampler:
    def __init__(self) -> None:
        self.disk_io = DiskIoSampler()
        self.process_io = ProcessIoSampler()

    def prime(self) -> None:
        """Take the first counter readings; rates are measured between two samples."""
        self.disk_io.rates()
        self.process_io.top_processes()

    def sample(self) -> dict[str, object]:
        disks = physical_disks()
        filesystems = mounted_filesystems()
        rates = self.disk_io.rates()
        stats: dict[str, object] = {f"disk:{disk}": disk_stats(rates.get(disk)) for disk in disks}
        for filesystem in filesystems:
            stats[f"mount:{filesystem.device}"] = filesystem_stats(filesystem)
        return {
            "disks": disk_layout(disks, filesystems),
            "stats": stats,
            "processes": self.process_io.top_processes(),
        }


if __name__ == "__main__":
    sampler = DiskDetailsSampler()
    sampler.prime()
    stream_json_lines(sampler.sample, INTERVAL_S, FIRST_INTERVAL_S)
