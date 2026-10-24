"""Lock the session, for the lock button in PowerIndicator.qml.

Prefers `loginctl lock-session`, which asks logind to signal the session's lock
handler (hypridle's `lock_cmd`, swayidle's `lock` event, xss-lock, ...), so it
works with whichever locker that handler starts. When none of those daemons is
running, nothing would react to that signal, so the locker is started
directly instead.
"""

import subprocess

import psutil

LOCK_HANDLERS = {"hypridle", "swayidle", "xss-lock"}
# Same as hypridle's lock_cmd: skipped if already locked, and the keyboard
# layout is reset so the password is typed in the first layout.
FALLBACK_LOCK_COMMAND = "pidof hyprlock || (hyprctl switchxkblayout all 0 && hyprlock)"


def lock_handler_running() -> bool:
    return any(proc.info["name"] in LOCK_HANDLERS for proc in psutil.process_iter(["name"]))


def main() -> None:
    if lock_handler_running():
        subprocess.run(["loginctl", "lock-session"], check=False)
        return
    # Detached, so the locker outlives this script and a Quickshell reload.
    subprocess.Popen(
        ["sh", "-c", FALLBACK_LOCK_COMMAND],
        start_new_session=True,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


if __name__ == "__main__":
    main()
