"""Stream CPU temperature and the busiest processes as JSON lines for CpuIndicator.qml.

Runs until killed; CpuIndicator only keeps it alive while its menu is open.

Each line: {
    "temperature": {"text": str, "hot": bool} | null,
    "processes": [{"name": str, "pid": int, "percent": float, "value": str}, ...]
}
Process percentages are a share of the whole CPU (all cores), matching the
total shown on the indicator itself.
"""

import os

import psutil

from json_stream import stream_json_lines

INTERVAL_S = 1.0
FIRST_INTERVAL_S = 0.3
TOP_PROCESS_COUNT = 5

# Sensor chips that measure the CPU itself, in order of preference.
CPU_CHIPS = ("coretemp", "k10temp", "zenpower", "cpu_thermal")
# Labels of the single most representative reading, in order of preference.
PRIMARY_LABELS = ("Package id 0", "Tdie", "Tctl")
DISPLAY_LABELS = {"Package id 0": "Package"}
# Per-core / per-die readings, summarised as a min-max range.
GROUP_PREFIXES = {"Core": "cores", "Tccd": "CCDs"}

type Temperature = dict[str, str | bool]
type ProcessInfo = dict[str, str | int | float]


def read_temperature() -> Temperature | None:
    try:
        sensors = psutil.sensors_temperatures()
    except (AttributeError, OSError):
        return None
    entries = next((sensors[chip] for chip in CPU_CHIPS if sensors.get(chip)), None)
    if not entries:
        return None

    primary = next(
        (e for label in PRIMARY_LABELS for e in entries if e.label == label),
        entries[0],
    )
    label = DISPLAY_LABELS.get(primary.label, primary.label) or "CPU"
    text = f"{label} {primary.current:.0f}°C"

    for prefix, group_label in GROUP_PREFIXES.items():
        group = [e.current for e in entries if e.label.startswith(prefix)]
        if not group:
            continue
        low, high = min(group), max(group)
        if round(low) == round(high):
            text += f" · {group_label} {low:.0f}°C"
        else:
            text += f" · {group_label} {low:.0f}–{high:.0f}°C"
        break

    threshold = primary.high or primary.critical
    return {"text": text, "hot": bool(threshold and primary.current >= threshold)}


def top_processes() -> list[ProcessInfo]:
    # process_iter() caches Process objects between calls, so cpu_percent()
    # measures usage since the previous call for the same process.
    cpu_count = psutil.cpu_count() or 1
    own_pid = os.getpid()
    samples: list[tuple[float, int, str]] = []
    for proc in psutil.process_iter(["name"]):
        if proc.pid == own_pid:
            continue
        try:
            percent = proc.cpu_percent(None) / cpu_count
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
        samples.append((percent, proc.pid, proc.info["name"] or str(proc.pid)))

    samples.sort(key=lambda s: s[0], reverse=True)
    return [
        {"name": name, "pid": pid, "percent": round(percent, 1), "value": f"{percent:.1f}%"}
        for percent, pid, name in samples[:TOP_PROCESS_COUNT]
    ]


def sample() -> dict[str, object]:
    return {"temperature": read_temperature(), "processes": top_processes()}


if __name__ == "__main__":
    # Prime per-process CPU counters; the first reading is always 0.
    top_processes()
    stream_json_lines(sample, INTERVAL_S, FIRST_INTERVAL_S)
