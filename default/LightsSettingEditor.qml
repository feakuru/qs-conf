import QtQuick
import QtQuick.Layouts
import Quickshell

// Edits one lights setting, {effect, colors, speed}: the effect, its colours
// (presets or a hue bar; the slot tabs pick which colour of a two-colour
// effect is changed) and, for animated effects, the speed. It doesn't apply
// anything itself, it only reports every change through `edited`, so it can
// edit what zones show now (LightsMenu) as well as, later, what an automation
// rule would set.
ColumnLayout {
    id: editor

    // Shown in the header, e.g. what is being edited.
    property string title: ""
    // Identifies what is being edited; when it changes, `setting` is shown
    // again even if it didn't change (e.g. two zones without a setting).
    property string subject: ""
    // [{name, colors}]: the effects to offer and how many colours each takes.
    property var effects: []
    // The setting to show, or null (nothing set, or several differing ones).
    property var setting: null
    // A bar is being dragged: `setting` isn't shown until it changes again,
    // so a late update from the owner doesn't make the colour jump back.
    readonly property bool interacting: hueMouseArea.pressed || speedSlider.dragging

    signal edited(var setting)

    readonly property var presetColors: ["#ffffff", "#ffb46b", "#ff0000", "#ff6a00", "#ffd500", "#00ff2a", "#00e5ff", "#0040ff", "#8a00ff", "#ff0090"]
    // For effects that take more colours than the setting had so far.
    readonly property var defaultColors: ["#3388ff", "#ff3388"]

    // What the editor shows: {effect, colors, speed}; effect is "" while
    // nothing is chosen.
    property var current: normalized(setting)
    // The last colours of each slot, so going e.g. static → rainbow → static
    // brings the colour back.
    property var rememberedColors: defaultColors.slice()
    // Which colour of a multi-colour effect the palette changes.
    property int colorSlot: 0

    readonly property var currentEffect: effects.find(effect => effect.name === current.effect) ?? null
    readonly property int colorCount: currentEffect ? currentEffect.colors : 0
    readonly property int activeSlot: Math.min(colorSlot, Math.max(colorCount - 1, 0))
    readonly property string activeColor: (current.colors[activeSlot] ?? "").toLowerCase()

    function normalized(setting) {
        if (!setting) {
            return {
                effect: "",
                colors: [],
                speed: 50
            };
        }
        return {
            effect: setting.effect,
            colors: (setting.colors ?? []).slice(),
            speed: setting.speed ?? 50
        };
    }

    function show(setting) {
        editor.current = editor.normalized(setting);
        editor.remember();
    }

    function remember() {
        let remembered = editor.rememberedColors.slice();
        editor.current.colors.forEach((color, slot) => remembered[slot] = color);
        editor.rememberedColors = remembered;
    }

    function apply(changes) {
        editor.current = Object.assign({}, editor.current, changes);
        editor.remember();
        editor.edited(editor.current);
    }

    function colorsFor(effectName) {
        let count = editor.effects.find(effect => effect.name === effectName)?.colors ?? 0;
        let colors = [];
        for (let slot = 0; slot < count; slot++) {
            colors.push(editor.current.colors[slot] ?? editor.rememberedColors[slot] ?? editor.defaultColors[slot % editor.defaultColors.length]);
        }
        return colors;
    }

    function chooseEffect(effectName) {
        editor.apply({
            effect: effectName,
            colors: editor.colorsFor(effectName)
        });
    }

    // Picking a colour while the effect takes none switches to the first
    // one-colour effect (static).
    function chooseColor(color) {
        if (editor.colorCount === 0) {
            let effect = editor.effects.find(effect => effect.colors === 1);
            if (effect) {
                editor.apply({
                    effect: effect.name,
                    colors: [color]
                });
            }
            return;
        }
        let colors = editor.current.colors.slice();
        colors[editor.activeSlot] = color;
        editor.apply({
            colors: colors
        });
    }

    function hex(color) {
        let channel = value => Math.round(value * 255).toString(16).padStart(2, "0");
        return `#${channel(color.r)}${channel(color.g)}${channel(color.b)}`;
    }

    onSettingChanged: {
        if (!editor.interacting) {
            editor.show(editor.setting);
        }
    }
    onSubjectChanged: {
        editor.colorSlot = 0;
        editor.show(editor.setting);
    }

    Layout.fillWidth: true
    spacing: 0

    DropdownMenuHeader {
        text: editor.current.effect === "" ? editor.title : `${editor.title} · ${editor.current.effect}`
    }

    // Effects, as icon tabs (the header names the chosen one).
    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            // Names, so that a new but equal list keeps the tabs.
            model: ScriptModel {
                values: editor.effects.map(effect => effect.name)
            }
            delegate: TabMenuItem {
                required property var modelData
                iconName: Lights.effectIcon(modelData)
                selected: editor.current.effect === modelData
                action: () => editor.chooseEffect(modelData)
            }
        }
    }

    // Which colour of a multi-colour effect is being changed.
    RowLayout {
        Layout.fillWidth: true
        visible: editor.colorCount > 1
        spacing: 0

        Repeater {
            model: editor.colorCount
            delegate: DropdownMenuItem {
                id: slotItem
                required property int index
                readonly property bool selected: index === editor.activeSlot
                showSeparator: false
                action: () => editor.colorSlot = slotItem.index

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: editor.current.colors[slotItem.index] ?? "transparent"
                        border.width: 1
                        border.color: AppConstants.indicatorBorderColor
                    }

                    StyledText {
                        anchors.centerIn: undefined
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 15
                        color: slotItem.selected ? AppConstants.styledTextColor : AppConstants.mutedIconColor
                        text: `colour ${slotItem.index + 1}`
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    height: 3
                    radius: 1.5
                    visible: slotItem.selected
                    color: AppConstants.indicatorOnColor
                }
            }
        }
    }

    // Preset colours.
    Item {
        Layout.fillWidth: true
        implicitHeight: 42

        Row {
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: editor.presetColors
                delegate: Rectangle {
                    id: swatch
                    required property string modelData
                    readonly property bool chosen: editor.colorCount > 0 && editor.activeColor === modelData
                    width: 28
                    height: 28
                    radius: 14
                    color: modelData
                    border.width: chosen ? 3 : swatchHover.hovered ? 2 : 1
                    border.color: chosen ? AppConstants.indicatorOnColor : swatchHover.hovered ? AppConstants.styledTextColor : AppConstants.indicatorBorderColor

                    HoverHandler {
                        id: swatchHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: editor.chooseColor(swatch.modelData)
                    }
                }
            }
        }
    }

    // Any fully saturated colour: click or drag along the hues.
    Item {
        Layout.fillWidth: true
        implicitHeight: 34

        Rectangle {
            id: hueBar
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 4
            anchors.bottomMargin: 8
            radius: 6
            border.width: 1
            border.color: AppConstants.indicatorBorderColor
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "#ff0000"
                }
                GradientStop {
                    position: 1 / 6
                    color: "#ffff00"
                }
                GradientStop {
                    position: 2 / 6
                    color: "#00ff00"
                }
                GradientStop {
                    position: 3 / 6
                    color: "#00ffff"
                }
                GradientStop {
                    position: 4 / 6
                    color: "#0000ff"
                }
                GradientStop {
                    position: 5 / 6
                    color: "#ff00ff"
                }
                GradientStop {
                    position: 1
                    color: "#ff0000"
                }
            }

            // The chosen colour's hue, unless it's grey or white.
            Rectangle {
                readonly property color chosenColor: editor.activeColor === "" ? "transparent" : editor.activeColor
                visible: editor.colorCount > 0 && editor.activeColor !== "" && chosenColor.hsvSaturation > 0.2
                x: Math.max(0, chosenColor.hsvHue) * (hueBar.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: parent.height + 6
                radius: 3
                color: "white"
                border.width: 1
                border.color: "black"
            }

            MouseArea {
                id: hueMouseArea
                anchors.fill: parent
                preventStealing: true
                function pick(x) {
                    let hue = Math.min(Math.max(x / width, 0), 0.999);
                    editor.chooseColor(editor.hex(Qt.hsva(hue, 1, 1, 1)));
                }
                onPressed: mouse => pick(mouse.x)
                onPositionChanged: mouse => pick(mouse.x)
            }
        }
    }

    SliderMenuItem {
        id: speedSlider
        visible: Lights.isAnimated(editor.current.effect)
        iconName: "gauge-high"
        from: 1
        to: 100
        value: editor.current.speed
        text: `speed ${speedSlider.shownValue}`
        onMoved: value => editor.apply({
                speed: value
            })
    }
}
