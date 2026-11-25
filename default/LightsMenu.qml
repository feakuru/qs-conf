import QtQuick
import QtQuick.Layouts
import Quickshell

// The RGB lighting (see Lights): global power and brightness, then pages.
// The "Zones" page lists every zone, every device with several zones, and
// all zones together; the selected one is edited below the list, and every
// change is applied right away. Hidden on machines without lights.
//
// More pages (e.g. automation) are added to `pages` and get an item in
// menuContent that is visible while `page` is their key; the tab row only
// shows up once there is more than one.
DropdownMenu {
    id: lightsMenu

    readonly property var pages: [
        {
            key: "zones",
            iconName: "sliders",
            text: "Zones"
        }
    ]
    property string page: pages[0].key

    // Seconds lights.identify blinks a zone for.
    readonly property int identifySeconds: 5

    // What the Zones page can set, in list order: {key, kind ("all",
    // "device" or "zone"), name, detail, iconName, indent, zones (IDs),
    // zone (the zone's ID, for "zone")}. Keys are unique: "all",
    // "device:<id>", "zone:<id>".
    readonly property var targets: {
        let targets = [
            {
                key: "all",
                kind: "all",
                name: "All zones",
                detail: "",
                iconName: "lightbulb",
                indent: 0,
                zones: Lights.zoneIds
            }
        ];
        for (let device of Lights.devices) {
            let deviceIcon = Lights.deviceIcon(device.kind);
            // A device with one zone is a single row, named after the device.
            if (device.zones.length === 1) {
                let zone = device.zones[0];
                targets.push({
                    key: `zone:${zone.id}`,
                    kind: "zone",
                    name: device.name,
                    detail: zone.name,
                    iconName: deviceIcon,
                    indent: 0,
                    zones: [zone.id],
                    zone: zone.id
                });
                continue;
            }
            targets.push({
                key: `device:${device.id}`,
                kind: "device",
                name: device.name,
                detail: `${device.zones.length} zones`,
                iconName: deviceIcon,
                indent: 0,
                zones: device.zones.map(zone => zone.id)
            });
            for (let zone of device.zones) {
                targets.push({
                    key: `zone:${zone.id}`,
                    kind: "zone",
                    name: zone.name,
                    detail: zone.leds ? `${zone.leds} LEDs` : "",
                    iconName: "circle-dot",
                    indent: 24,
                    zones: [zone.id],
                    zone: zone.id
                });
            }
        }
        return targets;
    }
    readonly property var targetsByKey: {
        let byKey = {};
        for (let target of targets) {
            byKey[target.key] = target;
        }
        return byKey;
    }

    property string selectedKey: "all"
    // Falls back to every zone if the selected one went away (unplugged).
    readonly property var selectedTarget: targetsByKey[selectedKey] ?? targetsByKey["all"]

    // What a target shows: its zone's setting, or the one all its zones
    // share (null if they differ).
    function settingOf(target) {
        if (!target) {
            return null;
        }
        return target.kind === "zone" ? Lights.zone(target.zone)?.setting ?? null : Lights.commonSetting(target.zones);
    }

    function apply(target, setting) {
        Lights.set(target.kind === "all" ? null : target.zones, setting);
    }

    visible: Lights.available
    onVisibleChanged: {
        if (!visible && menuVisible) {
            closeMenu();
        }
    }
    opensUpward: true
    menuWidth: 480

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/lightbulb.svg")
    toggleIconColor: Lights.power && Lights.blockedBy === "" ? AppConstants.indicatorOnColor : AppConstants.indicatorOffColor
    toggleIconOutlineColor: Lights.power ? AppConstants.iconOutlineColor : "transparent"
    toggleIconOutlineWidth: AppConstants.iconOutlineWidth

    menuContent: [
        // Calls still work while blocked: the daemon keeps the settings and
        // applies them once OpenRGB has exited.
        DropdownMenuItem {
            visible: Lights.blockedBy !== ""
            implicitHeight: blockedText.implicitHeight + 16

            StyledText {
                id: blockedText
                anchors.centerIn: undefined
                anchors.fill: parent
                anchors.margins: 8
                font.pixelSize: 14
                color: AppConstants.dangerColor
                wrapMode: Text.WordWrap
                text: Lights.blockedBy === "openrgb" ? "OpenRGB is running, so nothing reaches the lights. Changes are kept and applied once it exits." : `Blocked by ${Lights.blockedBy}: changes are kept and applied later.`
            }
        },
        DropdownMenuItem {
            visible: Lights.lastError !== ""
            implicitHeight: errorText.implicitHeight + 16
            action: () => Lights.lastError = ""

            StyledText {
                id: errorText
                anchors.centerIn: undefined
                anchors.fill: parent
                anchors.margins: 8
                font.pixelSize: 14
                color: AppConstants.dangerColor
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
                text: `${Lights.lastError} (click to dismiss)`
            }
        },
        ToggleMenuItem {
            text: Lights.power ? "Lights on" : "Lights off"
            checked: Lights.power
            toggle: () => Lights.setPower(!Lights.power)
        },
        SliderMenuItem {
            iconName: "sun"
            value: Lights.brightness
            onMoved: value => Lights.setBrightness(value)
        },
        RowLayout {
            Layout.fillWidth: true
            visible: lightsMenu.pages.length > 1
            spacing: 0

            Repeater {
                model: lightsMenu.pages
                delegate: TabMenuItem {
                    required property var modelData
                    iconName: modelData.iconName
                    text: modelData.text
                    selected: lightsMenu.page === modelData.key
                    action: () => lightsMenu.page = modelData.key
                }
            }
        },
        ColumnLayout {
            Layout.fillWidth: true
            visible: lightsMenu.page === "zones"
            spacing: 0
            // Changes still apply while blocked, they just don't show yet.
            opacity: Lights.blockedBy !== "" ? 0.6 : 1

            DropdownMenuHeader {
                text: "Zones"
            }

            ScrollingMenuList {
                rowCount: targetsRepeater.count
                maxVisibleRows: 10

                Repeater {
                    id: targetsRepeater
                    // Keys, so that rows are only recreated when the list
                    // of zones changes, not on every update.
                    model: ScriptModel {
                        values: lightsMenu.targets.map(target => target.key)
                    }
                    delegate: LightsTargetMenuItem {
                        id: targetRow
                        required property string modelData
                        readonly property var target: lightsMenu.targetsByKey[modelData] ?? null
                        showSeparator: true
                        iconName: target?.iconName ?? "lightbulb"
                        text: target?.name ?? ""
                        detailText: target?.detail ?? ""
                        indent: target?.indent ?? 0
                        selected: lightsMenu.selectedTarget?.key === modelData
                        setting: lightsMenu.settingOf(target)
                        emptyText: target?.kind === "zone" ? "not set" : "mixed"
                        canIdentify: target?.kind === "zone" && Lights.canIdentify(target.zone)
                        identifying: target?.kind === "zone" && Lights.identifying === target.zone
                        identifyAction: () => Lights.identify(targetRow.target.zone, lightsMenu.identifySeconds)
                        action: () => lightsMenu.selectedKey = targetRow.modelData
                    }
                }
            }

            LightsSettingEditor {
                title: lightsMenu.selectedTarget?.name ?? ""
                subject: lightsMenu.selectedTarget?.key ?? ""
                effects: Lights.effectsFor(lightsMenu.selectedTarget?.zones ?? [])
                setting: lightsMenu.settingOf(lightsMenu.selectedTarget)
                onEdited: setting => lightsMenu.apply(lightsMenu.selectedTarget, setting)
            }
        }
    ]
}
