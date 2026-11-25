pragma Singleton
import QtQuick
import Quickshell

// The machine's RGB lighting (ARGB fans, RAM), driven by qs-conf-daemon: its
// `lights` topic and `lights.*` methods. Everything in the shell that reads
// or changes the lights goes through here (LightsMenu now, automation later),
// so the daemon's contract is only spelled out once.
//
// The daemon stores what the zones show and re-applies it, so nothing is
// kept here besides the last payload.
Singleton {
    id: lights

    // The `lights` payload; null while the daemon is unreachable.
    readonly property var payload: Daemon.connected ? lightsTopic.latest : null
    // False on machines without lights: the UI isn't shown at all then.
    readonly property bool available: payload !== null && payload.available
    // "openrgb" while OpenRGB runs: settings are kept, but nothing reaches
    // the devices until it exits.
    readonly property string blockedBy: payload?.blocked_by ?? ""
    // The zone lights.identify is blinking, if any.
    readonly property string identifying: payload?.identifying ?? ""
    readonly property bool power: payload?.power ?? false
    readonly property int brightness: payload?.brightness ?? 0
    // [{id, kind, name, effects: [{name, colors}], zones: [{id, name, leds, setting}]}]
    readonly property var devices: available ? payload.devices : []
    readonly property var zoneIds: devices.flatMap(device => device.zones.map(zone => zone.id))
    // The last failed call's error, cleared by the next successful one.
    property string lastError: ""

    // Effects whose `speed` matters; the payload doesn't say.
    readonly property var animatedEffects: ["breathing", "rainbow"]

    readonly property var effectIcons: ({
            off: "ban",
            static: "circle",
            breathing: "lungs",
            gradient: "circle-half-stroke",
            rainbow: "rainbow"
        })
    readonly property var deviceIcons: ({
            nollie8: "fan",
            fury_ddr4: "memory"
        })

    function effectIcon(effect: string): string {
        return lights.effectIcons[effect] ?? "lightbulb";
    }

    function deviceIcon(kind: string): string {
        return lights.deviceIcons[kind] ?? "lightbulb";
    }

    function isAnimated(effect: string): bool {
        return lights.animatedEffects.includes(effect);
    }

    function device(deviceId: string) {
        return lights.devices.find(device => device.id === deviceId) ?? null;
    }

    function deviceOf(zoneId: string) {
        return lights.devices.find(device => device.zones.some(zone => zone.id === zoneId)) ?? null;
    }

    function zone(zoneId: string) {
        for (let device of lights.devices) {
            let zone = device.zones.find(zone => zone.id === zoneId);
            if (zone) {
                return zone;
            }
        }
        return null;
    }

    // lights.identify only works on the Nollie's channels.
    function canIdentify(zoneId: string): bool {
        return lights.deviceOf(zoneId)?.kind === "nollie8";
    }

    // The effects every device of `zoneIds` supports, in the first one's
    // order: [{name, colors}].
    function effectsFor(zoneIds) {
        let devices = lights.devices.filter(device => device.zones.some(zone => zoneIds.includes(zone.id)));
        if (devices.length === 0) {
            return [];
        }
        return devices[0].effects.filter(effect => devices.every(device => device.effects.some(other => other.name === effect.name && other.colors === effect.colors)));
    }

    // What `zoneIds` show if it's the same for all of them, else null (also
    // when none has a setting).
    function commonSetting(zoneIds) {
        let settings = zoneIds.map(zoneId => lights.zone(zoneId)?.setting ?? null);
        if (settings.length === 0 || settings[0] === null) {
            return null;
        }
        let first = JSON.stringify(settings[0]);
        return settings.every(setting => JSON.stringify(setting) === first) ? settings[0] : null;
    }

    // Sets what `zoneIds` show (every zone if null), from a setting
    // {effect, colors, speed}; `colors` must have as many colours as the
    // effect takes.
    function set(zoneIds, setting): void {
        let params = {
            effect: setting.effect,
            speed: setting.speed ?? 50
        };
        if (setting.colors && setting.colors.length > 0) {
            params.colors = setting.colors;
        }
        if (zoneIds !== null) {
            params.zones = zoneIds;
        }
        lights.throttledCall(`set:${zoneIds === null ? "*" : zoneIds.join(",")}`, "lights.set", params);
    }

    function setPower(on: bool): void {
        lights.throttledCall("power", "lights.power", {
            on: on
        });
    }

    function setBrightness(percent: int): void {
        lights.throttledCall("brightness", "lights.brightness", {
            percent: Math.round(Math.min(Math.max(percent, 0), 100))
        });
    }

    // Blinks a zone white, to find out which fan it is.
    function identify(zoneId: string, seconds: int): void {
        Daemon.call("lights.identify", {
            zone: zoneId,
            seconds: seconds
        }, lights.report("lights.identify"));
    }

    function report(method: string) {
        return (result, error) => {
            if (error !== undefined) {
                console.warn(`Lights: ${method} failed:`, error);
                lights.lastError = `${error}`;
            } else {
                lights.lastError = "";
            }
        };
    }

    // Calls waiting for throttleTimer, by key (the latest call per key
    // wins), in the order they were last made.
    property var pendingCalls: ({})

    // Dragging a slider or a colour makes many calls a second; only the
    // latest of each kind is sent, at most every throttleTimer.interval.
    function throttledCall(key: string, method: string, params): void {
        delete lights.pendingCalls[key];
        lights.pendingCalls[key] = {
            method: method,
            params: params
        };
        if (!throttleTimer.running) {
            throttleTimer.start();
        }
    }

    function flushCalls(): void {
        let calls = lights.pendingCalls;
        lights.pendingCalls = {};
        for (let key in calls) {
            Daemon.call(calls[key].method, calls[key].params, lights.report(calls[key].method));
        }
    }

    Timer {
        id: throttleTimer
        interval: 60
        onTriggered: lights.flushCalls()
    }

    // Cheap (pushed on change only), and the bar needs `available` anyway.
    DaemonTopic {
        id: lightsTopic
        topic: "lights"
    }
}
