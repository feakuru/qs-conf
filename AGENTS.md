## Purpose
This project provides a UI for a user of a hyprland Linux environment.
This document is intended to orient automated/agentic contributors to build this project.

## Environment
- Quickshell config (used with latest release of quickshell): manages the UI
  - Check the installed version (`qs --version`) and use the matching docs, e.g. https://quickshell.org/docs/v0.3.2/types/ - APIs change between releases.
  - The config hot-reloads when files are saved, so the human sees changes immediately.
- Python runtime: used as a backend for various features, requires Python >= 3.12 (see `pyproject.toml`), uses `uv`.
- Primary languages/artifacts: Python (`*.py`) and QML (`*.qml`).
- Dependency groups: `dev` group contains `mypy` (see `pyproject.toml`).

## General code guidance

1. Codestyle
Use your best judgement and keep in mind that:
  - qmlls will be used for formatting by the human after you work on any QML code
  - ruff will be used for formatting by the human after you work on any Python code
  - you must not run any of those unless the user explicitly requests it

2. Project structure
  - Keep Python helpers in `default/scripts/` (current pattern).
  - The project is built using `uv`, so always use
    - `uv run` if you need to execute anything in the Python virtual environment
    - `uv sync` and `uv add {dependency_name}` for dependencies
  - Store icons/assets under `default/assets/` and reference via `Qt.resolvedUrl` or relative paths.
  - Python helpers are run from QML via `ScriptProcess` (`default/ScriptProcess.qml`):
    - one-shot scripts print a single result (usually JSON) and are re-run by a `Timer`;
    - helpers that need state between samples (e.g. per-process CPU usage) stream one JSON line per sample using `default/scripts/json_stream.py`, read with a `SplitParser`, and only run while needed (e.g. `running: someIndicator.menuVisible`).

3. Safety
  - Do not `git commit` anything ever. In this repo, that is the human's job.
  - Only run any scripts or Python or Bash commands if a user explicitly requested or approved them.

## Guidance for UI code

1. Build / Run / Install / Test / Lint / Type-check / Formatting - NO STEPS
There are no steps of the above type that you would need to take after changing the UI code (qml/js) - since this is a Quickshell config, the only way to check anything is for a human to actually press the buttons.
Also, do not use any tools for previewing or testing QML - the human operator will do that themself.

Debugging: when behaviour can't be worked out from the code, add temporary `console.log` calls (with a common, greppable prefix), ask the human to reproduce the issue, then read the output with `qs log` (e.g. `qs log --no-color -t 300`; `qs log --help` for more). Remove the logging once the issue is understood. Reading Qt/Quickshell/Hyprland sources (matching the installed versions) has also been effective for input/focus issues.

2. File organization
  - Keep QML components in logically-named files (current pattern: `default/*.qml`).
  - Name QML types in PascalCase.

3. Codestyle
  - Prefer reusable components and small property sets per component.
  - Heavy logic belongs in Python helper modules, not in QML handlers.

4. Layout and sizing
  - Components report their natural size via `implicitWidth`/`implicitHeight`; layouts pick that up automatically. Do not add `preferredWidth`-style properties or compute sizes from `childrenRect`.
  - Bar widgets set `Layout.fillHeight: true` themselves, so `shell.qml` stays a plain list of widgets inside two `Bar`s. Exactly one item per bar should have `Layout.fillWidth: true` to take up the remaining space.
  - Widgets with changing text (percentages etc.) reserve room for their widest value (`BarButton.toggleTextWidest`) so they don't resize on every update.
  - Use `Separator` between bar widgets and between menu rows instead of borders.
  - Shared sizes and colours live in `AppConstants` (e.g. `barHeight`, `loadBarAlpha`); don't hard-code them.

5. Shared building blocks
  - `Bar`: a top or bottom panel; children are laid out left to right.
  - `BarButton`: clickable bar widget with an optional icon and text, sized to fit them.
  - `DropdownMenu`: a `BarButton` that opens a `PopupWindow` anchored to it (`opensUpward: true` on the bottom bar). Menu rows go in `menuContent`.
  - Menu rows: `DropdownMenuItem` (base row with hover, click `action` and separator), `IconMenuItem` (centred icons and/or label), `UsageMenuItem` (label, value and a usage bar), `DropdownMenuHeader` (section header).
  - `ScrollingMenuList`: shows at most `maxVisibleRows` of the rows inside it and scrolls the rest (Wi-Fi networks, Bluetooth devices).
  - Singletons: `AppConstants` (theme), `Dropdowns` (only one dropdown/launcher open at a time), `WindowActions` (Hyprland window move/float/close/focus).
  - `ProgramPicker`, `WifiPasswordPrompt` and `SessionActionDialog` use their own keyboard-focusable `PanelWindow` instead of a popup, because popups can't reliably get keyboard focus.

6. Known pitfalls
  - Hover inside dropdown menus: a `MouseArea` with `hoverEnabled: true` (or a hover-enabled Control such as a `ScrollBar`) accepts hover events, and Qt then stops delivering hover to its ancestors. This breaks the menu-level `HoverHandler` that closes menus when the mouse leaves. Inside menus, track hover with `HoverHandler` and use `MouseArea` only for clicks.
  - Touch produces hover too: Qt Quick (6.12, `QQuickDeliveryAgent`) treats the first touch point as the mouse position and delivers synthetic hover events from the core pointer device (on this machine Qt Wayland's gesture device, named "touchpad", type `TouchPad`), so `HoverHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad }` does not filter touch out, and a real touchpad can't be told apart from touch by device. To detect touch, use `HoverHandler { acceptedDevices: PointerDevice.TouchScreen }`: it is `hovered` while a finger is down, even if a child `MouseArea` grabbed the touch. `PointHandler`/`TapHandler` on an ancestor never see such touches, because single-point handlers skip points that are already exclusively grabbed (see `DropdownMenu.touchUsed`).
  - Reading logs from a sandboxed shell: `qs` needs `WAYLAND_DISPLAY` (e.g. `WAYLAND_DISPLAY=wayland-1 qs log -i <id>`, find the id with `qs list --all`), otherwise it may read a stale instance's log. Qt's internal input logging only appears if the shell was started with e.g. `QT_LOGGING_RULES='qt.quick.pointer*.debug=true;qt.quick.touch*.debug=true;qt.quick.handler*.debug=true'`.
  - Do not use `HyprlandFocusGrab` for the dropdown popups: with a grab active the popup got no pointer input at all (no hover; clicks inside counted as outside), even when the grab was started only after the popup's window was shown. As a result, dropdowns don't close on clicks outside of them.
  - Repeaters whose model is a JS array recreate every delegate whenever the array is reassigned. For data that updates periodically, use a fixed-count model (e.g. `model: 5`) with delegates that read `someArray[index]`, or only reassign the array when the data actually changed. Otherwise rows flicker and lose hover.

