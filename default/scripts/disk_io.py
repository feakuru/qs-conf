"""Stream how busy the physical disks are as JSON lines for DiskIndicator.qml's bar.

Runs until killed.

Each line: {
    "busy": int,  percentage of time the busiest disk was doing I/O
}
Only whole physical disks are counted (not partitions, device-mapper, loop or
zram devices). The sampler is shared with disk_details.py.
"""

import os
import time
from dataclasses import dataclass

import psutil

from json_stream import stream_json_lines

INTERVAL_S = 1.0
FIRST_INTERVAL_S = 0.3
SYS_BLOCK = "/sys/block"


def physical_disks() -> list[str]:
    """Kernel names of whole physical disks, e.g. ["nvme0n1", "sda"].

    Virtual block devices (loop, zram, dm-*, ...) have no `device` link, and
    empty card readers report a size of 0.
    """
    disks: list[str] = []
    for name in sorted(os.listdir(SYS_BLOCK)):
        if not os.path.exists(os.path.join(SYS_BLOCK, name, "device")):
            continue
        if read_sys_int(os.path.join(SYS_BLOCK, name, "size")) == 0:
            continue
        disks.append(name)
    return disks


def read_sys_text(path: str) -> str:
    try:
        with open(path) as sys_file:
            return sys_file.read().strip()
    except OSError:
        return ""


def read_sys_int(path: str) -> int:
    try:
        return int(read_sys_text(path))
    except ValueError:
        return 0


@dataclass
class DiskRates:
    read: float  # bytes/s
    write: float  # bytes/s
    busy: float  # percent of the interval spent doing I/O


class DiskIoSampler:
    def __init__(self) -> None:
        # disk -> (bytes read, bytes written, busy ms, timestamp)
        self.previous: dict[str, tuple[int, int, int, float]] = {}

    def rates(self) -> dict[str, DiskRates]:
        """Rates of each physical disk since the previous call."""
        now = time.monotonic()
        counters = psutil.disk_io_counters(perdisk=True) or {}
        current: dict[str, tuple[int, int, int, float]] = {}
        rates: dict[str, DiskRates] = {}
        for disk in physical_disks():
            if disk not in counters:
                continue
            counter = counters[disk]
            busy_ms = getattr(counter, "busy_time", 0)
            current[disk] = (counter.read_bytes, counter.write_bytes, busy_ms, now)
            previous = self.previous.get(disk)
            if previous is None:
                continue
            elapsed = now - previous[3]
            if elapsed <= 0:
                continue
            rates[disk] = DiskRates(
                read=max(counter.read_bytes - previous[0], 0) / elapsed,
                write=max(counter.write_bytes - previous[1], 0) / elapsed,
                busy=min(max(busy_ms - previous[2], 0) / (elapsed * 1000) * 100, 100),
            )
        self.previous = current
        return rates


def bar_sample(sampler: DiskIoSampler) -> dict[str, object]:
    rates = sampler.rates().values()
    return {"busy": round(max((rate.busy for rate in rates), default=0))}


if __name__ == "__main__":
    sampler = DiskIoSampler()
    # Prime the counters; rates are measured between two samples.
    sampler.rates()
    stream_json_lines(lambda: bar_sample(sampler), INTERVAL_S, FIRST_INTERVAL_S)
