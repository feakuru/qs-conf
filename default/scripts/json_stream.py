"""Helpers for scripts that stream JSON lines to a long-running Quickshell Process."""

import json
import os
import sys
import time
from collections.abc import Callable
from typing import Any


def print_json_line(value: Any) -> None:
    print(json.dumps(value), flush=True)


def silence_stdout() -> None:
    """Point stdout at devnull after the reader went away.

    Without this, the interpreter's flush on exit raises BrokenPipeError again
    (see Python docs on SIGPIPE).
    """
    devnull = os.open(os.devnull, os.O_WRONLY)
    os.dup2(devnull, sys.stdout.fileno())


def stream_json_lines(
    sample: Callable[[], Any],
    interval_s: float,
    first_interval_s: float | None = None,
) -> None:
    """Print `sample()` as one JSON line every `interval_s` until the reader goes away."""
    try:
        time.sleep(interval_s if first_interval_s is None else first_interval_s)
        while True:
            print_json_line(sample())
            time.sleep(interval_s)
    except BrokenPipeError:
        silence_stdout()
    except KeyboardInterrupt:
        pass
