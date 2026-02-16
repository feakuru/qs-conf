#!/usr/bin/env python3
"""One-shot client for sending OSK events to the pyzmq daemon.

Usage example:
    python3 osk_zmq_client.py --event short_press --code 123

This script connects a PUSH socket to the ipc address and sends a JSON
message then exits immediately. It uses LINGER=0 so it doesn't block on
exit if the daemon is not available.
"""

import logging
import os
import sys
import time
import json
import argparse
from pathlib import Path

import zmq

logging.basicConfig(
    level=logging.INFO, format="osk-client | %(levelname)s: %(message)s"
)

WAV_CHUNK_SIZE = 1024


def default_log_path():
    env = os.environ.get("OSK_LOG_FILE")
    if env:
        return Path(env)
    return Path("/tmp") / "quickshell-osk.log"


def default_socket_addr():
    return f"ipc://{Path('/tmp') / 'quickshell-osk.ipc'}"


def setup_logging():
    log_path = default_log_path()
    try:
        fh = logging.FileHandler(log_path, encoding="utf-8")
        fh.setLevel(logging.INFO)
        fh.setFormatter(
            logging.Formatter("%(asctime)s | osk-client | %(levelname)s: %(message)s")
        )
        logging.getLogger().addHandler(fh)
        logging.info("logging to %s", log_path)
    except Exception:
        logging.exception("failed to set up file logging")


def send_event(
    event: str, codes: list[int] | None = None, socket_addr: str | None = None
) -> None:
    setup_logging()
    addr = socket_addr or default_socket_addr()
    ctx = zmq.Context()
    sock = ctx.socket(zmq.PUSH)
    # Do not block on close if daemon is gone
    sock.setsockopt(zmq.LINGER, 0)
    # connect can raise; surface the address in logs for debugging
    logging.info(f"connecting to {addr}")
    sock.connect(addr)

    payload = {"event": event, "ts": time.time()}
    if codes is not None:
        payload["codes"] = codes

    try:
        logging.info(f"sending: {payload}")
        sock.send_string(json.dumps(payload))
        # give the socket a short moment to send when run in fast-exit contexts
        time.sleep(0.01)
    except Exception:
        logging.exception('Could not send event')
    finally:
        sock.close(0)
        ctx.term()


def parse_args(argv):
    p = argparse.ArgumentParser()
    p.add_argument(
        "--socket",
        help="override ipc socket address, e.g. ipc:///tmp/quickshell-osk.ipc",
    )
    p.add_argument(
        "--event",
        required=True,
        choices=["short_press", "long_start", "long_end", "cancel", "reset"],
    )  # required
    p.add_argument("--codes", type=str, help="keycodes for the event")
    result = p.parse_args(argv)
    result.codes = [int(code) for code in result.codes.split(",")]
    return result


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])
    send_event(args.event, args.codes, args.socket)


if __name__ == "__main__":
    main()
