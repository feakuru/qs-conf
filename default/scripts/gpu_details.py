"""Stream the busiest GPU processes as JSON lines for GpuIndicator.qml.

Runs until killed; GpuIndicator only keeps it alive while its menu is open.

Each line: {
    "processes": [{"name": str, "pid": int, "percent": float, "value": str}, ...],
    "error": str,  empty unless per-process usage is unavailable
}
A process's percentage is the load of its busiest engine (render, video,
...), so it is comparable to the GPU load shown on the indicator itself.

Backends, matching gpu_usage.py:
- NVIDIA: `nvidia-smi pmon`
- Others (amdgpu, i915, xe, ...): DRM fdinfo (/proc/<pid>/fdinfo), which only
  covers processes of the current user
"""

import os
import re
import shutil
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path

import psutil

from gpu_usage import drm_cards, idle_counters, read_int
from json_stream import stream_json_lines

INTERVAL_S = 1.0
FIRST_INTERVAL_S = 0.3
TOP_PROCESS_COUNT = 5
MIB = 1024**2
UNIT_BYTES = {"": 1, "KiB": 1024, "MiB": MIB, "GiB": 1024**3}

type ProcessInfo = dict[str, str | int | float]


@dataclass
class ProcessUsage:
    pid: int
    load: float = 0.0  # percent, busiest engine
    memory: int = 0  # bytes; dedicated memory when there is any


def process_name(pid: int, fallback: str = "") -> str:
    try:
        return psutil.Process(pid).name()
    except psutil.Error:
        return fallback or str(pid)


def format_size(size: float) -> str:
    if size < 1024**3:
        return f"{size / MIB:.0f} MiB"
    return f"{size / 1024**3:.2f} GiB"


def to_process_infos(usages: list[ProcessUsage], names: dict[int, str]) -> list[ProcessInfo]:
    usages.sort(key=lambda u: (u.load, u.memory), reverse=True)
    result: list[ProcessInfo] = []
    for usage in usages[:TOP_PROCESS_COUNT]:
        value = f"{usage.load:.0f}%"
        if usage.memory:
            value = f"{format_size(usage.memory)} · {value}"
        result.append(
            {
                "name": process_name(usage.pid, names.get(usage.pid, "")),
                "pid": usage.pid,
                "percent": round(usage.load, 1),
                "value": value,
            }
        )
    return result


# --- NVIDIA ---------------------------------------------------------------


def nvidia_processes() -> list[ProcessInfo]:
    try:
        out = subprocess.run(
            ["nvidia-smi", "pmon", "--count", "1", "--select", "um"],
            capture_output=True,
            text=True,
            timeout=5,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return []

    # Columns differ between driver versions, so they are looked up by the
    # header, e.g. "# gpu  pid  type  sm  mem  enc  dec  jpg  ofa  fb  command".
    columns: list[str] = []
    usages: dict[int, ProcessUsage] = {}
    names: dict[int, str] = {}
    for line in out.splitlines():
        fields = line.lstrip("#").split()
        if line.startswith("#"):
            if "pid" in fields and not columns:
                columns = fields
            continue
        if not columns or len(fields) < len(columns):
            continue
        row = dict(zip(columns, fields))
        # Same GPU as gpu_usage.py, which reads the first one.
        if row.get("gpu") != "0" or not row.get("pid", "").isdigit():
            continue
        pid = int(row["pid"])
        usage = usages.setdefault(pid, ProcessUsage(pid))
        # A process can be listed twice, as a graphics and a compute client.
        if row.get("sm", "-").isdigit():
            usage.load = min(usage.load + int(row["sm"]), 100)
        if row.get("fb", "-").isdigit():
            usage.memory += int(row["fb"]) * MIB
        names[pid] = " ".join(fields[len(columns) - 1 :]) if columns[-1] == "command" else ""
    return to_process_infos(list(usages.values()), names)


# --- DRM fdinfo -----------------------------------------------------------

FDINFO_LINE = re.compile(r"^(drm-[\w-]+):\s+(\d+)(?:\s*(\w+))?$")


@dataclass
class ClientSample:
    """Counters of one DRM client (an open GPU context) at one point in time."""

    pid: int
    timestamp_ns: int
    # drm-engine-<engine>: busy time in ns (i915, amdgpu, ...)
    engine_ns: dict[str, int] = field(default_factory=dict)
    # drm-engine-capacity-<engine>: number of engines of that class
    capacity: dict[str, int] = field(default_factory=dict)
    # drm-cycles-<engine> / drm-total-cycles-<engine> (xe)
    cycles: dict[str, int] = field(default_factory=dict)
    total_cycles: dict[str, int] = field(default_factory=dict)
    # memory region -> resident bytes
    memory: dict[str, int] = field(default_factory=dict)


def pci_slot(card: Path) -> str:
    try:
        for line in (card / "device" / "uevent").read_text().splitlines():
            key, _, value = line.partition("=")
            if key == "PCI_SLOT_NAME":
                return value
    except OSError:
        pass
    return ""


def tracked_pdev() -> str:
    """PCI slot of the GPU gpu_usage.py reports on, or "" for any GPU."""
    cards = drm_cards()
    for card in cards:
        if read_int(card / "device" / "gpu_busy_percent") is not None:
            return pci_slot(card)
    for card in cards:
        if idle_counters(card):
            return pci_slot(card)
    return ""


def parse_fdinfo(text: str, pid: int, timestamp_ns: int) -> tuple[str, str, ClientSample] | None:
    """Return (pdev, client id, sample) for a DRM file descriptor's fdinfo."""
    values: dict[str, tuple[int, str]] = {}
    for line in text.splitlines():
        if match := FDINFO_LINE.match(line):
            values[match[1]] = (int(match[2]), match[3] or "")
    if "drm-client-id" not in values:
        return None

    client_id = str(values["drm-client-id"][0])
    pdev = ""
    for line in text.splitlines():
        if line.startswith("drm-pdev:"):
            pdev = line.partition(":")[2].strip()

    sample = ClientSample(pid, timestamp_ns)
    resident: dict[str, int] = {}
    total: dict[str, int] = {}
    for key, (number, unit) in values.items():
        size = number * UNIT_BYTES.get(unit, 1)
        if key.startswith("drm-engine-capacity-"):
            sample.capacity[key.removeprefix("drm-engine-capacity-")] = number
        elif key.startswith("drm-engine-"):
            sample.engine_ns[key.removeprefix("drm-engine-")] = number
        elif key.startswith("drm-total-cycles-"):
            sample.total_cycles[key.removeprefix("drm-total-cycles-")] = number
        elif key.startswith("drm-cycles-"):
            sample.cycles[key.removeprefix("drm-cycles-")] = number
        elif key.startswith("drm-resident-"):
            resident[key.removeprefix("drm-resident-")] = size
        elif key.startswith("drm-memory-"):
            # Older amdgpu name for resident memory.
            resident.setdefault(key.removeprefix("drm-memory-"), size)
        elif key.startswith("drm-total-"):
            total[key.removeprefix("drm-total-")] = size
    sample.memory = resident or total
    return pdev, client_id, sample


def read_drm_clients(pdev: str) -> dict[tuple[str, str], ClientSample]:
    own_pid = os.getpid()
    clients: dict[tuple[str, str], ClientSample] = {}
    for proc_entry in os.scandir("/proc"):
        if not proc_entry.name.isdigit() or int(proc_entry.name) == own_pid:
            continue
        pid = int(proc_entry.name)
        try:
            fds = list(os.scandir(f"/proc/{pid}/fd"))
        except OSError:
            continue  # other users' processes, or exited
        for fd in fds:
            try:
                if not os.readlink(fd.path).startswith("/dev/dri/"):
                    continue
                text = Path(f"/proc/{pid}/fdinfo/{fd.name}").read_text()
            except OSError:
                continue
            parsed = parse_fdinfo(text, pid, time.monotonic_ns())
            if parsed is None:
                continue
            client_pdev, client_id, sample = parsed
            if pdev and client_pdev and client_pdev != pdev:
                continue
            # A client shows up once per fd referring to it, possibly in
            # several processes; count it once, for the first one.
            clients.setdefault((client_pdev, client_id), sample)
    return clients


def engine_loads(before: ClientSample, after: ClientSample) -> dict[str, float]:
    loads: dict[str, float] = {}
    elapsed_ns = after.timestamp_ns - before.timestamp_ns
    if elapsed_ns > 0:
        for engine, busy_ns in after.engine_ns.items():
            if engine in before.engine_ns:
                capacity = max(after.capacity.get(engine, 1), 1)
                busy = busy_ns - before.engine_ns[engine]
                loads[engine] = busy / elapsed_ns / capacity * 100
    for engine, cycles in after.cycles.items():
        if engine in before.cycles and engine in after.total_cycles and engine in before.total_cycles:
            total = after.total_cycles[engine] - before.total_cycles[engine]
            if total > 0:
                capacity = max(after.capacity.get(engine, 1), 1)
                loads[engine] = (cycles - before.cycles[engine]) / total / capacity * 100
    return loads


def dedicated_memory(memory: dict[str, int]) -> int:
    # Only dedicated memory (VRAM) is shown when the GPU has any, otherwise
    # GPU buffers in system RAM (integrated GPUs).
    vram = [size for region, size in memory.items() if region.startswith("vram")]
    return sum(vram) if vram else sum(memory.values())


class DrmSampler:
    def __init__(self) -> None:
        self.pdev = tracked_pdev()
        self.previous: dict[tuple[str, str], ClientSample] = {}

    def processes(self) -> list[ProcessInfo]:
        clients = read_drm_clients(self.pdev)
        engine_totals: dict[int, dict[str, float]] = {}
        usages: dict[int, ProcessUsage] = {}
        for key, sample in clients.items():
            usage = usages.setdefault(sample.pid, ProcessUsage(sample.pid))
            usage.memory += dedicated_memory(sample.memory)
            if previous := self.previous.get(key):
                totals = engine_totals.setdefault(sample.pid, {})
                for engine, load in engine_loads(previous, sample).items():
                    totals[engine] = totals.get(engine, 0.0) + load
        for pid, totals in engine_totals.items():
            usages[pid].load = min(max(max(totals.values(), default=0.0), 0.0), 100.0)
        self.previous = clients
        return to_process_infos(list(usages.values()), {})


def main() -> None:
    if shutil.which("nvidia-smi"):

        def sample() -> dict[str, object]:
            return {"processes": nvidia_processes(), "error": ""}

        stream_json_lines(sample, INTERVAL_S, 0)
        return

    sampler = DrmSampler()
    # Prime the counters; loads are measured between two samples.
    sampler.processes()

    def drm_sample() -> dict[str, object]:
        processes = sampler.processes()
        error = "" if processes else "No GPU clients found for this user"
        return {"processes": processes, "error": error}

    stream_json_lines(drm_sample, INTERVAL_S, FIRST_INTERVAL_S)


if __name__ == "__main__":
    main()
