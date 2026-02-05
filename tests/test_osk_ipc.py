import os
import sys
import time
import signal
import subprocess
from pathlib import Path
import tempfile


def _start_daemon(xdg_runtime_dir: str):
    env = os.environ.copy()
    env["XDG_RUNTIME_DIR"] = xdg_runtime_dir
    daemon_path = (
        Path(__file__).parents[1] / "default" / "scripts" / "osk_zmq_daemon.py"
    )
    proc = subprocess.Popen(
        [sys.executable, str(daemon_path)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        text=True,
    )
    return proc, env


def _wait_for_ipc(xdg_runtime_dir: str, timeout: float = 2.0) -> Path:
    p = Path(xdg_runtime_dir) / "quickshell-osk.ipc"
    deadline = time.time() + timeout
    while time.time() < deadline:
        if p.exists():
            return p
        time.sleep(0.01)
    raise TimeoutError("ipc socket file did not appear")


def _run_client(env, event: str, code: int | None = None):
    client_path = (
        Path(__file__).parents[1] / "default" / "scripts" / "osk_zmq_client.py"
    )
    cmd = [sys.executable, str(client_path), "--event", event]
    if code is not None:
        cmd += ["--code", str(code)]
    subprocess.run(cmd, env=env, check=True)


def test_short_and_long_flow():
    # Start daemon with isolated XDG_RUNTIME_DIR
    with tempfile.TemporaryDirectory() as td:
        proc, env = _start_daemon(td)
        try:
            _wait_for_ipc(td)

            # short press: should produce a single simulated keydown+keyup
            _run_client(env, "short_press", 30)
            time.sleep(0.05)

            # long hold: start then end
            _run_client(env, "long_start", 40)
            time.sleep(0.05)
            _run_client(env, "long_end", 40)
            time.sleep(0.05)

            # ask daemon to reset
            _run_client(env, "reset")
            time.sleep(0.05)

            # terminate daemon and capture output
            proc.terminate()
            try:
                out, err = proc.communicate(timeout=2.0)
            except subprocess.TimeoutExpired:
                proc.kill()
                out, err = proc.communicate(timeout=2.0)

            combined = (out or "") + "\n" + (err or "")

            assert "[ydotool-sim] ydotool key 30:1 30:0" in combined
            assert "[ydotool-sim] ydotool key 40:1" in combined
            assert "[ydotool-sim] ydotool key 40:0" in combined

        finally:
            if proc.poll() is None:
                proc.kill()
