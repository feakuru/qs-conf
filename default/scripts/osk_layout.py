import dataclasses
import json
import argparse
import evdev


class EnhancedJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if dataclasses.is_dataclass(o) and not isinstance(o, type):
            return dataclasses.asdict(o)
        return super().default(o)


@dataclasses.dataclass
class K:
    label: str
    key_pressed: str | None = None
    key_held: str | None = None
    layer_toggle: int | None = None
    layer_switch: str | None = None
    keycode_pressed: int | None = dataclasses.field(init=False)
    keycode_held: int | None = dataclasses.field(init=False)

    def __post_init__(self):
        if self.label and not self.key_pressed:
            self.key_pressed = self.label.upper()

        def lookup_key(name: str | None):
            if not name:
                return None
            return evdev.ecodes.ecodes[f"KEY_{name}"]

        if not self.key_held and self.key_pressed:
            self.key_held = self.key_pressed

        self.keycode_pressed = lookup_key(self.key_pressed)
        self.keycode_held = lookup_key(self.key_held)


@dataclasses.dataclass
class Layer:
    left: list[list[K | None] | None]
    right: list[list[K | None] | None]


LAYOUT = {
    "main": Layer(
        left=[
            [K("Esc"), K("1"), K("2"), K("3"), K("4"), K("5")],
            [K(""), K("q"), K("w"), K("e"), K("r"), K("t")],
            [
                K("Esc"),
                K("a"),
                K("s", key_held="LEFTALT"),
                K("d", key_held="LEFTCTRL"),
                K("f", key_held="LEFTSHIFT"),
                K("g"),
            ],
            [K(""), K("z"), K("x"), K("c"), K("v"), K("b")],
            [
                None,
                None,
                None,
                None,
                K("↵", "ENTER", layer_switch="symnum"),
                K("⌘", "LEFTMETA"),
            ],
        ],
        right=[
            [K("6"), K("7"), K("8"), K("9"), K("0"), K("")],
            [K("y"), K("u"), K("i"), K("o"), K("p"), K("⌫", "BACKSPACE")],
            [
                K("h"),
                K("j", key_held="RIGHTSHIFT"),
                K("k", key_held="RIGHTCTRL"),
                K("l", key_held="RIGHTALT"),
                K(";", "SEMICOLON"),
                K(""),
            ],
            [K("n"), K("m"), K(",", "COMMA"), K(".", "DOT"), K("/", "SLASH"), K("")],
            [
                K("⌫", "BACKSPACE"),
                K("␣", "SPACE", layer_switch="sysnav"),
                None,
                None,
                None,
                None,
            ],
        ],
    ),
    "symnum": Layer(
        left=[
            [
                None,
                K("F1", "F1"),
                K("F2", "F2"),
                K("F3", "F3"),
                K("F4", "F4"),
                K("F5", "F5"),
            ],
            [
                None,
                None,
                K("`", "GRAVE"),
                K("'", "APOSTROPHE"),
                K("[", "LEFTBRACE"),
                K("]", "RIGHTBRACE"),
            ],
            [
                None,
                None,
                K("-", "MINUS", key_held="LEFTALT"),
                K("=", "EQUAL", key_held="LEFTCTRL"),
                K(";", "SEMICOLON", key_held="LEFTSHIFT"),
                K(":", "SEMICOLON"),
            ],
            [
                None,
                None,
                K("_", "MINUS"),
                K("+", "EQUAL"),
                K("\\", "BACKSLASH"),
                K("/", "SLASH"),
            ],
            [
                None,
                None,
                None,
                None,
                K("↵", "ENTER", layer_switch="main"),
                K("⌘", "LEFTMETA"),
            ],
        ],
        right=[
            [
                K("F6", "F6"),
                K("F7", "F7"),
                K("F8", "F8"),
                K("F9", "F9"),
                K("F10", "F10"),
                None,
            ],
            [
                K("7", "7"),
                K("8", "8"),
                K("9", "9"),
                K("F11", "F11"),
                K("F12", "F12"),
                None,
            ],
            [
                K("4", "4"),
                K("5", "5", key_held="RIGHTSHIFT"),
                K("6", "6", key_held="RIGHTCTRL"),
                K(",", "COMMA", key_held="RIGHTALT"),
                None,
                None,
            ],
            [
                K("1", "1"),
                K("2", "2"),
                K("3", "3"),
                K(".", "DOT"),
                None,
                None,
            ],
            [
                K("⌫", "BACKSPACE"),
                K("␣", "SPACE", layer_switch="sysnav"),
                None,
                None,
                None,
                None,
            ],
        ],
    ),
    "sysnav": Layer(
        left=[
            [None, None, None, None, None, K("BRI+", "BRIGHTNESSUP")],
            [
                None,
                None,
                K("MUTE", "MUTE"),
                K("VOL-", "VOLUMEDOWN"),
                K("VOL+", "VOLUMEUP"),
                K("BRI-", "BRIGHTNESSDOWN"),
            ],
            [
                None,
                None,
                K("", "LEFTALT", key_held="LEFTALT"),
                K("", "LEFTCTRL", key_held="LEFTCTRL"),
                K("", "LEFTSHIFT", key_held="LEFTSHIFT"),
                None,
            ],
            [None, None, None, None, None, K("CapsL", "CAPSLOCK")],
            [
                None,
                None,
                None,
                None,
                K("↵", "ENTER", layer_switch="symnum"),
                K("⌘", "LEFTMETA"),
            ],
        ],
        right=[
            None,
            [
                K("PgUp", "PAGEUP"),
                K("PgDn", "PAGEDOWN"),
                K("Home", "HOME"),
                K("End", "END"),
                K("PrtSc", "PRINT"),
                None,
            ],
            [
                K("Left", "LEFT"),
                K("Down", "DOWN"),
                K("Up", "UP"),
                K("Right", "RIGHT"),
                None,
                None,
            ],
            [
                K("Tab", "TAB"),
                K("Bspc", "BACKSPACE"),
                K("Del", "DELETE"),
                None,
                None,
                None,
            ],
            [
                K("⌫", "BACKSPACE"),
                K("␣", "SPACE", layer_switch="main"),
                None,
                None,
                None,
                None,
            ],
        ],
    ),
}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("layer", nargs="?", default="main", help="layer name to output")
    args = parser.parse_args()
    layer_name = args.layer

    def _merge_side(selected_side, main_side):
        if len(main_side) != len(selected_side):
            raise ValueError("Incompatible layer heights")
        merged = []
        for i in range(len(main_side)):
            s = selected_side[i] if selected_side and i < len(selected_side) else None
            m = main_side[i] if main_side and i < len(main_side) else None
            if s is None:
                merged.append(m)
            else:
                merged.append(
                    [
                        s[idx]
                        if s[idx] is not None
                        else (m[idx] if m is not None and idx < len(m) else None)
                        for idx in range(len(s))
                    ]
                )
        return merged

    merged_layer = Layer(
        left=_merge_side(LAYOUT[layer_name].left, LAYOUT["main"].left),
        right=_merge_side(LAYOUT[layer_name].right, LAYOUT["main"].right),
    )

    print(json.dumps(merged_layer, cls=EnhancedJSONEncoder))
