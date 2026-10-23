"""Print GPU load and memory usage as JSON for GpuIndicator.qml.

Output: {"name": str, "load": int, "memory_used": int, "memory_total": int}
Memory values are in MiB; memory_total is 0 when the GPU has no dedicated
memory (integrated GPUs share system RAM).

Backends, in order of preference:
- NVIDIA: `nvidia-smi`
- AMD (amdgpu): sysfs `gpu_busy_percent` and `mem_info_vram_*`
- Intel (i915 / xe): sysfs idle (RC6) residency sampled over a short interval,
  load being the share of time the GPU was not idle
"""

import json
import re
import shlex
import shutil
import subprocess
import time
from pathlib import Path

DRM_PATH = Path("/sys/class/drm")
SAMPLE_INTERVAL_S = 0.25
MIB = 1024 * 1024

type GpuInfo = dict[str, str | int]


def read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def drm_cards() -> list[Path]:
    if not DRM_PATH.is_dir():
        return []
    cards = [p for p in DRM_PATH.iterdir() if re.fullmatch(r"card\d+", p.name)]
    return sorted(cards, key=lambda p: int(p.name.removeprefix("card")))


def pci_name(device: Path) -> str:
    """Human-readable name of a PCI device, falling back to its IDs."""
    slot = ""
    pci_id = ""
    try:
        for line in (device / "uevent").read_text().splitlines():
            key, _, value = line.partition("=")
            if key == "PCI_SLOT_NAME":
                slot = value
            elif key == "PCI_ID":
                pci_id = value
    except OSError:
        pass

    if slot and shutil.which("lspci"):
        try:
            out = subprocess.run(
                ["lspci", "-mm", "-s", slot],
                capture_output=True,
                text=True,
                timeout=2,
            ).stdout
            # Fields: slot, class, vendor, device, ...
            fields = shlex.split(out)
            if len(fields) >= 4:
                vendor = fields[2].removesuffix(" Corporation")
                return f"{vendor} {fields[3]}"
        except (OSError, subprocess.SubprocessError, ValueError):
            pass

    return f"GPU {pci_id}" if pci_id else "GPU"


def nvidia() -> GpuInfo | None:
    if not shutil.which("nvidia-smi"):
        return None
    try:
        out = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=utilization.gpu,memory.used,memory.total,name",
                "--format=csv,noheader,nounits",
            ],
            capture_output=True,
            text=True,
            timeout=5,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return None

    lines = out.strip().splitlines()
    if not lines:
        return None
    fields = [f.strip() for f in lines[0].split(",")]
    if len(fields) < 4:
        return None
    try:
        return {
            "name": ",".join(fields[3:]),
            "load": int(fields[0]),
            "memory_used": int(fields[1]),
            "memory_total": int(fields[2]),
        }
    except ValueError:
        return None


def amd(card: Path) -> GpuInfo | None:
    device = card / "device"
    load = read_int(device / "gpu_busy_percent")
    if load is None:
        return None
    used = read_int(device / "mem_info_vram_used") or 0
    total = read_int(device / "mem_info_vram_total") or 0
    return {
        "name": pci_name(device),
        "load": load,
        "memory_used": used // MIB,
        "memory_total": total // MIB,
    }


def idle_counters(card: Path) -> list[Path]:
    # i915: card/gt/gtN/rc6_residency_ms
    # xe:   card/device/tileN/gtN/gtidle/idle_residency_ms
    return sorted(card.glob("gt/gt*/rc6_residency_ms")) + sorted(
        card.glob("device/tile*/gt*/gtidle/idle_residency_ms")
    )


def intel(card: Path) -> GpuInfo | None:
    counters = idle_counters(card)
    if not counters:
        return None

    start = time.monotonic()
    before = [read_int(c) for c in counters]
    time.sleep(SAMPLE_INTERVAL_S)
    after = [read_int(c) for c in counters]
    elapsed_ms = (time.monotonic() - start) * 1000

    loads = []
    for b, a in zip(before, after):
        if b is None or a is None:
            continue
        idle_share = min(max((a - b) / elapsed_ms, 0.0), 1.0)
        loads.append(round((1 - idle_share) * 100))
    if not loads:
        return None

    return {
        # With several GTs (e.g. render + media), report the busiest one.
        "name": pci_name(card / "device"),
        "load": max(loads),
        "memory_used": 0,
        "memory_total": 0,
    }


def gpu_info() -> GpuInfo:
    if info := nvidia():
        return info
    cards = drm_cards()
    for card in cards:
        if info := amd(card):
            return info
    for card in cards:
        if info := intel(card):
            return info
    return {"name": "No supported GPU found", "load": 0, "memory_used": 0, "memory_total": 0}


if __name__ == "__main__":
    print(json.dumps(gpu_info()), end="")
