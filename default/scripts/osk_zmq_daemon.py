#!/usr/bin/env python3
"""OSK daemon using pyzmq PUSH/PULL to serialize ydotool calls.

Listens on an ipc:// socket under $XDG_RUNTIME_DIR and processes JSON
messages describing key events. Maintains held-key state so held keys
are pressed/released exactly once across the layout.
"""

import os
import subprocess
import sys
import json
import signal
import logging
from pathlib import Path

import zmq

logging.basicConfig(
    level=logging.INFO, format="osk-daemon | %(levelname)s: %(message)s"
)


def default_log_path():
    env = os.environ.get("OSK_LOG_FILE")
    if env:
        return Path(env)
    xdg = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    return Path(xdg) / "quickshell-osk.log"


def default_ipc_path():
    xdg = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    p = Path(xdg) / "quickshell-osk.ipc"
    return f"ipc://{p}", p


class OSKDaemon:
    def __init__(self, bind_addr, ipc_path):
        self.bind_addr = bind_addr
        self.ipc_path = ipc_path
        self.ctx = zmq.Context()
        self.sock = self.ctx.socket(zmq.PULL)
        self.held = {}  # code -> count
        # set up file logging so the server's activity can be tailed
        self.log_path = default_log_path()
        try:
            fh = logging.FileHandler(self.log_path, encoding="utf-8")
            fh.setLevel(logging.INFO)
            fh.setFormatter(
                logging.Formatter(
                    "%(asctime)s | osk-daemon | %(levelname)s: %(message)s"
                )
            )
            logging.getLogger().addHandler(fh)
            logging.info("logging to %s", self.log_path)
        except Exception:
            logging.exception("failed to set up file logging")

    def _emit_ydotool(self, args: list[str]):
        cmd = ["ydotool", *args]
        logging.info(f"[executing] {" ".join(cmd)}")
        subprocess.run(cmd)

    def bind(self):
        # Remove stale ipc file if present
        try:
            if self.ipc_path.exists():
                self.ipc_path.unlink()
        except Exception:
            logging.exception("failed to unlink existing ipc file")
        logging.info("binding to %s", self.bind_addr)
        self.sock.bind(self.bind_addr)

    def _log_raw(self, msg: str):
        try:
            logging.debug("raw: %s", msg)
        except Exception:
            logging.exception("failed to log raw message")

    def cleanup(self):
        logging.info("cleanup: releasing held keys and shutting down")
        try:
            for code, cnt in list(self.held.items()):
                if cnt > 0:
                    try:
                        self._emit_ydotool(["key", f"{code}:0"])
                    except Exception:
                        logging.exception("failed to release %s", code)
        finally:
            try:
                self.sock.close(0)
            except Exception:
                pass
            try:
                self.ctx.term()
            except Exception:
                pass
            try:
                if self.ipc_path.exists():
                    self.ipc_path.unlink()
            except Exception:
                pass

    def run(self):
        self.bind()

        def _handle_sig(signum, frame):
            self.cleanup()
            sys.exit(0)

        signal.signal(signal.SIGINT, _handle_sig)
        signal.signal(signal.SIGTERM, _handle_sig)

        while True:
            try:
                logging.debug("stepping")
                msg = self.sock.recv_string()
                self._log_raw(msg)
                try:
                    data = json.loads(msg)
                except Exception:
                    logging.exception("malformed json: %r", msg)
                    continue

                logging.info("received event: %s", data)

                evt = data.get("event")
                code = data.get("code")

                if evt == "long_start" and code is not None:
                    cnt = self.held.get(code, 0)
                    if cnt == 0:
                        logging.info("long_start press %s", code)
                        self._emit_ydotool(["key", f"{code}:1"])
                    self.held[code] = cnt + 1

                elif evt in ("long_end", "cancel") and code is not None:
                    cnt = self.held.get(code, 0)
                    if cnt > 0:
                        cnt -= 1
                        self.held[code] = cnt
                        if cnt == 0:
                            logging.info("long_end release %s", code)
                            self._emit_ydotool(["key", f"{code}:0"])

                elif evt == "short_press" and code is not None:
                    logging.info("short_press %s", code)
                    self._emit_ydotool(["key", f"{code}:1", f"{code}:0"])

                elif evt == "reset":
                    logging.info("reset: releasing all held keys")
                    for c, cnt in list(self.held.items()):
                        if cnt > 0:
                            self._emit_ydotool(["key", f"{c}:0"])
                    self.held.clear()

                else:
                    logging.warning("unknown or incomplete message: %r", data)

            except Exception:
                logging.exception("error in main loop")


def main():
    bind_addr, ipc_path = default_ipc_path()
    daemon = OSKDaemon(bind_addr, ipc_path)
    daemon.run()


if __name__ == "__main__":
    main()
