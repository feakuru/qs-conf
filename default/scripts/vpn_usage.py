"""Stream the throughput of active VPN connections as JSON lines for VpnIndicator.qml.

Runs until killed; VpnIndicator only keeps it alive while a VPN is active.

Each line: {
    "connections": {uuid: {"percent": float, "value": str}, ...},
    "sent": str,      total over all VPNs, formatted like the network indicator
    "received": str,  same
}
A connection's percentage is its share of all VPN traffic (sent and received
combined). Rates are measured on each connection's IP interface: the
WireGuard interface, or e.g. tun0 for VPN plugins such as OpenVPN.
"""

import subprocess
import time

import psutil

from json_stream import stream_json_lines
from net_details import format_rate

INTERVAL_S = 1.0
FIRST_INTERVAL_S = 0.3
INTERFACE_REFRESH_S = 2.0
VPN_TYPES = {"vpn", "wireguard"}


def nmcli(*args: str) -> str:
    try:
        return subprocess.run(
            ["nmcli", *args], capture_output=True, text=True, timeout=5
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def active_vpn_interfaces() -> dict[str, str]:
    """Map the UUIDs of active VPN connections to their IP interface."""
    interfaces: dict[str, str] = {}
    for line in nmcli("-t", "-f", "UUID,TYPE", "connection", "show", "--active").splitlines():
        uuid, _, conn_type = line.partition(":")
        if conn_type not in VPN_TYPES:
            continue
        # Empty while the connection is still being activated.
        interface = nmcli(
            "-g", "GENERAL.IP-IFACE", "connection", "show", "--active", "uuid", uuid
        ).strip()
        if interface:
            interfaces[uuid] = interface
    return interfaces


def format_bar_rate(rate: float) -> str:
    """Formatted like NetworkIndicator's bar text, which shows sar's kB/s (1024 B)."""
    kilobytes = rate / 1024
    if kilobytes > 1000:
        return f"{kilobytes / 1000:.2f} MB/s"
    return f"{kilobytes:.2f} kB/s"


class VpnSampler:
    def __init__(self) -> None:
        self.interfaces: dict[str, str] = {}
        self.interfaces_updated = 0.0
        # interface -> (bytes sent, bytes received, timestamp)
        self.previous: dict[str, tuple[int, int, float]] = {}

    def rates(self) -> dict[str, tuple[float, float]]:
        """Bytes per second (sent, received) of each active VPN, by UUID."""
        now = time.monotonic()
        if now - self.interfaces_updated >= INTERFACE_REFRESH_S:
            self.interfaces = active_vpn_interfaces()
            self.interfaces_updated = now

        counters = psutil.net_io_counters(pernic=True)
        current: dict[str, tuple[int, int, float]] = {}
        rates: dict[str, tuple[float, float]] = {}
        for uuid, interface in self.interfaces.items():
            if interface not in counters:
                continue
            sent, received = counters[interface].bytes_sent, counters[interface].bytes_recv
            current[interface] = (sent, received, now)
            if previous := self.previous.get(interface):
                elapsed = now - previous[2]
                if elapsed > 0:
                    rates[uuid] = (
                        max(sent - previous[0], 0) / elapsed,
                        max(received - previous[1], 0) / elapsed,
                    )
        self.previous = current
        return rates

    def sample(self) -> dict[str, object]:
        rates = self.rates()
        total_sent = sum(sent for sent, _ in rates.values())
        total_received = sum(received for _, received in rates.values())
        total = total_sent + total_received
        return {
            "connections": {
                uuid: {
                    "percent": round((sent + received) / total * 100, 1) if total else 0,
                    "value": f"↑ {format_rate(sent)} · ↓ {format_rate(received)}",
                }
                for uuid, (sent, received) in rates.items()
            },
            "sent": format_bar_rate(total_sent),
            "received": format_bar_rate(total_received),
        }


if __name__ == "__main__":
    sampler = VpnSampler()
    # Prime the counters; rates are measured between two samples.
    sampler.rates()
    stream_json_lines(sampler.sample, INTERVAL_S, FIRST_INTERVAL_S)
