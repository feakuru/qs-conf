## Purpose
This project provides a UI for a user of a hyprland Linux environment.
This document is intended to orient automated/agentic contributors to build this project.

## Environment
- Quickshell config (used with latest release of quickshell): manages the UI
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

3. Safety
  - Do not `git commit` anything ever. In this repo, that is the human's job.
  - Only run any scripts or Python or Bash commands if a user explicitly requested or approved them.

## Guidance for UI code

1. Build / Run / Install / Test / Lint / Type-check / Formatting - NO STEPS
There are no steps of the above type that you would need to take after changing the UI code (qml/js) - since this is a Quickshell config, the only way to check anything is for a human to actually press the buttons.
Also, do not use any tools for previewing or testing QML - the human operator will do that themself.

2. File organization
  - Keep QML components in logically-named files (current pattern: `default/*.qml`).
  - Name QML types in PascalCase.

3. Codestyle
  - Prefer reusable components and small property sets per component.
  - Heavy logic belongs in Python helper modules, not in QML handlers.

