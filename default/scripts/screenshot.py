"""Take a screenshot with hyprshot and report the outcome with `hyprctl notify`.

Used by Screenshots.qml. hyprshot's own result reporting can't be relied on:

* Its exit code is not the capture's: it captures in a background subshell and
  exits from a watcher loop whose last command is `pkill hyprpicker`, so a
  normal run exits with 1 (0 only if hyprpicker was running). Only argument
  errors (2) and signals stand out.
* It can exit before the capture is written, so this waits for its whole
  process group (except the wl-copy clipboard server, which stays around).
* It sends "Screenshot saved" even when the region selection was cancelled,
  so it is run with `--silent` and the saved file is checked here instead.
"""

import argparse
import os
import signal
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

import psutil

# See the module docstring: these mean "nothing unusual happened".
NORMAL_EXIT_CODES = {0, 1}
# Region selection waits for the user, the other modes don't.
HYPRSHOT_TIMEOUT = {"window": 30.0, "screen": 30.0, "region": 600.0}
# How long to wait for the background capture once hyprshot itself exited.
CAPTURE_FINISH_TIMEOUT = 10.0
POLL_INTERVAL = 0.05
# Processes allowed to outlive the capture.
LINGERING_PROCESSES = {"wl-copy"}

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
PNG_END = b"IEND\xaeB`\x82"

# `hyprctl notify` icons and how long each kind of notification stays.
ICON_WARNING = 0
ICON_INFO = 1
ICON_ERROR = 3
ICON_OK = 5
NOTIFY_TIMEOUT_MS = 5000
NOTIFY_ERROR_TIMEOUT_MS = 10000

MODE_TITLES = {"window": "Window", "screen": "Screen", "region": "Region"}
MAX_TITLE_LENGTH = 60


def warn(message: str) -> None:
    print(f"screenshot: {message}", file=sys.stderr)


def notify(icon: int, timeout_ms: int, message: str) -> None:
    # Color 0 uses the icon's default colour.
    try:
        subprocess.run(
            ["hyprctl", "notify", str(icon), str(timeout_ms), "0", message],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        warn(f"hyprctl notify failed: {exc}")


def pictures_dir() -> Path:
    """The folder hyprshot saves to by default."""
    if hyprshot_dir := os.environ.get("HYPRSHOT_DIR"):
        return Path(hyprshot_dir).expanduser()
    if xdg_pictures := os.environ.get("XDG_PICTURES_DIR"):
        return Path(xdg_pictures).expanduser()
    try:
        result = subprocess.run(["xdg-user-dir", "PICTURES"], capture_output=True, text=True, check=True)
        if result.stdout.strip():
            return Path(result.stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        pass
    return Path.home()


def unique_path(directory: Path, mode: str) -> Path:
    """A path that doesn't exist yet, so a stale file can't pass as the result."""
    stem = f"{datetime.now():%Y-%m-%d-%H%M%S}_{mode}"
    path = directory / f"{stem}.png"
    counter = 1
    while path.exists():
        path = directory / f"{stem}-{counter}.png"
        counter += 1
    return path


def png_size(path: Path) -> tuple[int, int] | None:
    """Width and height of a completely written PNG, or None."""
    try:
        data = path.read_bytes()
    except OSError:
        return None
    if len(data) < 24 or not data.startswith(PNG_SIGNATURE) or not data.endswith(PNG_END):
        return None
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")


def group_busy(pgid: int) -> bool:
    for proc in psutil.process_iter(["name", "status"]):
        try:
            if os.getpgid(proc.pid) != pgid:
                continue
        except OSError:
            continue
        if proc.info["status"] == psutil.STATUS_ZOMBIE or proc.info["name"] in LINGERING_PROCESSES:
            continue
        return True
    return False


def wait_for_group(pgid: int, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    while group_busy(pgid):
        if time.monotonic() > deadline:
            return False
        time.sleep(POLL_INTERVAL)
    return True


def kill_group(pgid: int) -> None:
    try:
        os.killpg(pgid, signal.SIGTERM)
    except OSError:
        pass


def display_path(path: Path) -> str:
    try:
        return f"~/{path.relative_to(Path.home())}"
    except ValueError:
        return str(path)


def shorten(text: str, max_length: int) -> str:
    return text if len(text) <= max_length else f"{text[:max_length]}…"


def describe_target(args: argparse.Namespace) -> str:
    if args.mode == "window":
        return f'window "{shorten(args.title, MAX_TITLE_LENGTH)}"' if args.title else "the active window"
    if args.mode == "screen":
        return f"screen {args.output}" if args.output else "the active screen"
    return "a region"


def hyprshot_mode_args(args: argparse.Namespace) -> list[str]:
    if args.mode == "window":
        return ["-m", "window", "-m", "active"]
    if args.mode == "screen":
        return ["-m", "output", "-m", args.output or "active"]
    return ["-m", "region"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("mode", choices=MODE_TITLES)
    parser.add_argument("--title", default="", help="title of the window being captured, for the notification")
    parser.add_argument("--output", default="", help="name of the screen to capture (default: the active one)")
    args = parser.parse_args()

    mode_title = MODE_TITLES[args.mode]
    target = describe_target(args)
    path = unique_path(pictures_dir(), args.mode)

    command = ["hyprshot", "--silent", "-o", str(path.parent), "-f", path.name, *hyprshot_mode_args(args)]
    # stderr goes to a file rather than a pipe: background children (wl-copy
    # in particular) keep it open long after hyprshot is done.
    with tempfile.TemporaryFile(mode="w+") as stderr_file:
        try:
            proc = subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=stderr_file,
                start_new_session=True,
            )
        except OSError as exc:
            warn(f"could not start hyprshot: {exc}")
            notify(ICON_ERROR, NOTIFY_ERROR_TIMEOUT_MS, f"{mode_title} screenshot failed: could not start hyprshot ({exc.strerror})")
            return 1

        timed_out = False
        try:
            exit_code = proc.wait(timeout=HYPRSHOT_TIMEOUT[args.mode])
        except subprocess.TimeoutExpired:
            timed_out = True
            kill_group(proc.pid)
            exit_code = proc.wait()

        if not timed_out and not wait_for_group(proc.pid, CAPTURE_FINISH_TIMEOUT):
            timed_out = True
            kill_group(proc.pid)

        stderr_file.seek(0)
        error_lines = [line.strip() for line in stderr_file.read().splitlines() if line.strip()]

    for line in error_lines:
        warn(f"hyprshot: {line}")

    size = png_size(path)
    if size is not None:
        message = f"Screenshot of {target} saved: {display_path(path)} ({size[0]}×{size[1]}), copied to the clipboard"
        if error_lines or exit_code not in NORMAL_EXIT_CODES:
            # Saved, but something (most likely the clipboard copy) complained.
            details = error_lines[-1] if error_lines else f"hyprshot exit code {exit_code}"
            notify(ICON_WARNING, NOTIFY_ERROR_TIMEOUT_MS, f"{message}. Warning: {details}")
        else:
            notify(ICON_OK, NOTIFY_TIMEOUT_MS, message)
        return 0

    if any("selection cancelled" in line for line in error_lines):
        notify(ICON_INFO, NOTIFY_TIMEOUT_MS, f"{mode_title} screenshot cancelled")
        return 0

    if timed_out:
        reason = "timed out"
    elif error_lines:
        reason = error_lines[0]
    else:
        reason = "no image was saved"
    if exit_code not in NORMAL_EXIT_CODES:
        reason = f"{reason} (hyprshot exit code {exit_code})"
    path.unlink(missing_ok=True)
    notify(ICON_ERROR, NOTIFY_ERROR_TIMEOUT_MS, f"Screenshot of {target} failed: {reason}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
