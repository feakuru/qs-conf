"""Print installed memory modules as JSON for RamIndicator.qml.

Reads the SMBIOS memory device info that systemd's udev rules (dmi_memory_id)
attach to the DMI device. Unlike dmidecode, this needs no root.

Output: {
    "slots_total": int | null,
    "modules": [{"slot": str, "summary": str, "details": str}, ...]
}
e.g. {"slot": "DIMM_A1", "summary": "16 GiB DDR5 DIMM @ 5600 MT/s",
      "details": "Kingston · KF556C40-16 · rank 1 · 1.25 V"}
"""

import json
import re
import subprocess
from collections import defaultdict

DMI_DEVICE = "/sys/devices/virtual/dmi/id"
DEVICE_PROPERTY_RE = re.compile(r"MEMORY_DEVICE_(\d+)_(\w+)")
GIB = 1024**3
# Values firmware uses to say "no information".
PLACEHOLDERS = {"", "unknown", "not specified", "not provided", "none", "other", "0000", "00000000"}
# SMBIOS calls memory soldered onto the board a "Row Of Chips".
FORM_FACTOR_NAMES = {"Row Of Chips": "soldered"}

type Module = dict[str, str]


def read_udev_properties() -> dict[str, str]:
    try:
        out = subprocess.run(
            ["udevadm", "info", "--query=property", f"--path={DMI_DEVICE}"],
            capture_output=True,
            text=True,
            timeout=2,
            check=True,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return {}
    properties = {}
    for line in out.splitlines():
        key, _, value = line.partition("=")
        properties[key] = value.strip()
    return properties


def meaningful(value: str | None) -> str:
    if value is None or value.lower() in PLACEHOLDERS:
        return ""
    return value


def parse_int(value: str | None) -> int | None:
    try:
        return int(value) if value else None
    except ValueError:
        return None


def describe_module(index: int, device: dict[str, str]) -> Module | None:
    size = parse_int(device.get("SIZE"))
    if device.get("PRESENT") == "0" or not size:
        return None

    size_text = f"{size / GIB:g} GiB" if size >= GIB else f"{size // 1024**2} MiB"
    summary = " ".join(
        part
        for part in (
            size_text,
            meaningful(device.get("TYPE")),
            FORM_FACTOR_NAMES.get(meaningful(device.get("FORM_FACTOR")), meaningful(device.get("FORM_FACTOR"))),
        )
        if part
    )

    rated = parse_int(device.get("SPEED_MTS"))
    configured = parse_int(device.get("CONFIGURED_SPEED_MTS"))
    if configured and rated and configured != rated:
        summary += f" @ {configured} MT/s (rated {rated})"
    elif configured or rated:
        summary += f" @ {configured or rated} MT/s"

    details = [
        meaningful(device.get("MANUFACTURER")),
        meaningful(device.get("PART_NUMBER")),
    ]
    rank = parse_int(device.get("RANK"))
    if rank:
        details.append(f"rank {rank}")
    # dmi_memory_id reports voltages in millivolts.
    voltage = parse_int(device.get("CONFIGURED_VOLTAGE"))
    if voltage:
        details.append(f"{voltage / 1000:g} V")

    slot = meaningful(device.get("LOCATOR")) or meaningful(device.get("BANK_LOCATOR")) or f"Slot {index}"
    return {"slot": slot, "summary": summary, "details": " · ".join(d for d in details if d)}


def main() -> None:
    properties = read_udev_properties()
    devices: dict[int, dict[str, str]] = defaultdict(dict)
    for key, value in properties.items():
        match = DEVICE_PROPERTY_RE.fullmatch(key)
        if match:
            devices[int(match[1])][match[2]] = value

    modules = [m for i in sorted(devices) if (m := describe_module(i, devices[i])) is not None]
    print(
        json.dumps(
            {
                "slots_total": parse_int(properties.get("MEMORY_ARRAY_NUM_DEVICES")),
                "modules": modules,
            }
        )
    )


if __name__ == "__main__":
    main()
