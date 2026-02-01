## Purpose
This document orients automated/agentic contributors (and humans) to build this quickshell config.

## Environment
- Quickshell config (used with latest release of quickshell)
- Python runtime: requires Python >= 3.12 (see `pyproject.toml`).
- Primary languages/artifacts: Python (`*.py`) and QML (`*.qml`).
- Dependency groups: `dev` group contains `mypy` (see `pyproject.toml`).

## Guidance
1) Build / Run / Install / Test / Lint / Type-check / Formatting - NO STEPS
There are no steps of the above type that you would need to take after changing the code - since this is a Quickshell config, the only way to check anything is for a human to actually press the buttons.

2) Code style & conventions
Use your best judgement and keep in mind that:
  - qmlls will be used for formatting by the human after you work on any QML code
  - Ruff will be used for formatting by the human after you work on any Python code

3) QML / UI conventions
- File organization
  - Keep QML components in logically-named files (current pattern: `default/*.qml`).
  - Name QML types in PascalCase.
- Styling & properties
  - Prefer reusable components and small property sets per component.
  - Heavy logic belongs in Python helper modules, not in QML handlers.
- Assets
  - Store icons/assets under `default/assets/` and reference via relative paths.
- Testing & preview
  - Do not use any tools for previewing or testing QML - the human operator will do that themself.

4) Project structure guidance
- Keep Python helpers in `default/scripts/` (current pattern).

5) Git & commits
- Do not commit anything ever. In this repo, that is the human's job.

