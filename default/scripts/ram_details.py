"""Stream RAM/swap usage and the most memory-hungry processes as JSON lines for RamIndicator.qml.

Runs until killed; RamIndicator only keeps it alive while its menu is open.

Each line: {
    "memory": str,  e.g. "7.8 / 31.2 GiB"
    "swap": str,    same format, empty when there is no swap
    "processes": [{"name": str, "pid": int, "percent": float, "value": str}, ...]
}
Process memory is resident set size, as a percentage of total RAM.
"""

import psutil

from json_stream import stream_json_lines

INTERVAL_S = 1.0
FIRST_INTERVAL_S = 0.1
TOP_PROCESS_COUNT = 5
MIB = 1024**2
GIB = 1024**3

type ProcessInfo = dict[str, str | int | float]


def format_size(size: float) -> str:
    if size < GIB:
        return f"{size / MIB:.0f} MiB"
    return f"{size / GIB:.2f} GiB"


def format_usage(used: float, total: float) -> str:
    return f"{used / GIB:.1f} / {total / GIB:.1f} GiB"


def top_processes(total_memory: int) -> list[ProcessInfo]:
    samples: list[tuple[int, int, str]] = []
    for proc in psutil.process_iter(["name", "memory_info"]):
        memory_info = proc.info["memory_info"]
        if memory_info is None:
            continue
        samples.append((memory_info.rss, proc.pid, proc.info["name"] or str(proc.pid)))

    samples.sort(key=lambda s: s[0], reverse=True)
    result: list[ProcessInfo] = []
    for rss, pid, name in samples[:TOP_PROCESS_COUNT]:
        percent = rss / total_memory * 100
        result.append(
            {
                "name": name,
                "pid": pid,
                "percent": round(percent, 1),
                "value": f"{format_size(rss)} · {percent:.1f}%",
            }
        )
    return result


def sample() -> dict[str, object]:
    memory = psutil.virtual_memory()
    swap = psutil.swap_memory()
    return {
        # Same notion of "used" as ram_usage.py (virtual_memory().percent).
        "memory": format_usage(memory.total - memory.available, memory.total),
        "swap": format_usage(swap.used, swap.total) if swap.total else "",
        "processes": top_processes(memory.total),
    }


if __name__ == "__main__":
    stream_json_lines(sample, INTERVAL_S, FIRST_INTERVAL_S)
