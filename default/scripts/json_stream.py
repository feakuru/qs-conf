"""Helper for scripts that stream JSON lines to a long-running Quickshell Process."""

import json
import os
import sys
import time
from collections.abc import Callable
from typing import Any


def stream_json_lines(
    sample: Callable[[], Any],
    interval_s: float,
    first_interval_s: float | None = None,
) -> None:
    """Print `sample()` as one JSON line every `interval_s` until the reader goes away."""
    try:
        time.sleep(interval_s if first_interval_s is None else first_interval_s)
        while True:
            print(json.dumps(sample()), flush=True)
            time.sleep(interval_s)
    except BrokenPipeError:
        # Quickshell stopped reading. Point stdout at devnull so the
        # interpreter's flush on exit doesn't raise again (see Python docs on
        # SIGPIPE).
        devnull = os.open(os.devnull, os.O_WRONLY)
        os.dup2(devnull, sys.stdout.fileno())
    except KeyboardInterrupt:
        pass
