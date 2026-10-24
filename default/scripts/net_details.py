"""Stream per-process network usage as JSON lines for NetworkIndicator.qml.

Runs until killed; NetworkIndicator only keeps it alive while its menu is open.

Each line: {
    "processes": [{"name": str, "pid": int, "percent": float, "value": str}, ...],
    "error": str,  empty unless per-process usage is unavailable
}
Process percentages are a share of all traffic nethogs attributed in that
sample (sent and received combined), including traffic it could not match to
a process.

Data comes from `nethogs` in trace mode, which needs packet-capture
capabilities when not run as root (see README.md). Its rates are averaged over
the last 5 seconds.
"""

import os
import queue
import shutil
import signal
import subprocess
import sys
import threading
from dataclasses import dataclass
from typing import IO

import psutil

from json_stream import print_json_line, silence_stdout

TOP_PROCESS_COUNT = 5
REFRESH_S = 1
# nethogs prints a whole refresh at once; a pause this long ends the block.
BLOCK_GAP_S = 0.2
KIB = 1024
MIB = 1024**2

type ProcessInfo = dict[str, str | int | float]


@dataclass
class Traffic:
    name: str
    pid: int
    sent: float  # bytes/s
    received: float  # bytes/s

    @property
    def total(self) -> float:
        return self.sent + self.received


def parse_trace_line(line: str) -> Traffic | None:
    """Parse a `program/pid/uid<TAB>sent<TAB>received` line (rates in KiB/s)."""
    fields = line.rstrip("\n").split("\t")
    if len(fields) != 3:
        return None
    program, _, rest = fields[0].rpartition("/")
    program, _, pid_text = program.rpartition("/")
    try:
        pid = int(pid_text)
        int(rest)  # uid
        sent = float(fields[1]) * KIB
        received = float(fields[2]) * KIB
    except ValueError:
        return None
    return Traffic(program, pid, sent, received)


def format_rate(rate: float) -> str:
    if rate < KIB:
        return f"{rate:.0f} B/s"
    if rate < MIB:
        return f"{rate / KIB:.1f} KiB/s"
    return f"{rate / MIB:.2f} MiB/s"


def process_name(traffic: Traffic) -> str:
    # Same names as the CPU and RAM menus; nethogs reports the full path.
    try:
        return psutil.Process(traffic.pid).name()
    except psutil.Error:
        return os.path.basename(traffic.name) or str(traffic.pid)


def summarise(block: list[Traffic]) -> dict[str, object]:
    total = sum(t.total for t in block)
    busiest = sorted(
        (t for t in block if t.pid > 0 and t.total > 0),
        key=lambda t: t.total,
        reverse=True,
    )
    processes: list[ProcessInfo] = []
    for traffic in busiest[:TOP_PROCESS_COUNT]:
        percent = traffic.total / total * 100
        processes.append(
            {
                "name": process_name(traffic),
                "pid": traffic.pid,
                "percent": round(percent, 1),
                "value": f"↑ {format_rate(traffic.sent)} · ↓ {format_rate(traffic.received)}",
            }
        )
    return {"processes": processes, "error": ""}


def read_lines(stream: IO[str], lines: "queue.Queue[str | None]") -> None:
    for line in stream:
        lines.put(line)
    lines.put(None)


def stream_nethogs() -> None:
    nethogs = subprocess.Popen(
        # -C also captures UDP (e.g. QUIC), not just TCP.
        ["nethogs", "-t", "-C", "-d", str(REFRESH_S)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        # Merged so that a failure message is seen in order, and so that a
        # full stderr pipe can never block nethogs.
        stderr=subprocess.STDOUT,
        text=True,
    )
    assert nethogs.stdout is not None
    lines: queue.Queue[str | None] = queue.Queue()
    threading.Thread(target=read_lines, args=(nethogs.stdout, lines), daemon=True).start()

    block: list[Traffic] | None = None
    last_message = ""
    try:
        while True:
            try:
                line = lines.get(timeout=BLOCK_GAP_S if block is not None else None)
            except queue.Empty:
                print_json_line(summarise(block or []))
                block = None
                continue

            if line is None:
                nethogs.wait()
                message = last_message or f"nethogs exited with code {nethogs.returncode}"
                print_json_line({"processes": [], "error": message})
                return

            text = line.strip()
            if text == "Refreshing:":
                if block is not None:
                    print_json_line(summarise(block))
                block = []
            elif traffic := parse_trace_line(line):
                if block is not None:
                    block.append(traffic)
            elif text and not text.startswith("Unknown connection:"):
                last_message = text
    finally:
        if nethogs.poll() is None:
            nethogs.terminate()
            try:
                nethogs.wait(timeout=1)
            except subprocess.TimeoutExpired:
                nethogs.kill()


def main() -> None:
    # Quickshell stops the script with SIGTERM; exit through `finally` so
    # nethogs is stopped too.
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        if not shutil.which("nethogs"):
            print_json_line({"processes": [], "error": "nethogs is not installed"})
            return
        stream_nethogs()
    except BrokenPipeError:
        silence_stdout()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
