import dataclasses
import json
import argparse

import evdev
import xkbcommon.xkb as xkb

_xkb_context = xkb.Context()
_xkb_keymap_cache: dict[str, xkb.Keymap] = {}


def _get_keymap(layout: str):
    if layout not in _xkb_keymap_cache:
        try:
            _xkb_keymap_cache[layout] = _xkb_context.keymap_new_from_names(
                rules="evdev",
                model="pc105",
                layout=layout,
                variant=None,
                options=None,
            )
        except Exception as e:
            raise Exception(layout) from e
    return _xkb_keymap_cache[layout]


def _find_keycode_for_symbol(symbol: str, layout: str):
    keymap = _get_keymap(layout)

    target_keysym = xkb.keysym_from_name(symbol, case_insensitive=True)

    for keycode in keymap:
        syms = keymap.key_get_syms_by_level(keycode, 0, 0)
        if syms and syms[0] == target_keysym:
            return keycode

    return None


def get_layout_label(key_label: str, layout: str, shift: bool) -> str:
    keymap = _get_keymap(layout)
    state = keymap.state_new()

    if shift:
        shift_index = keymap.mod_get_index("Shift")
        state.update_mask(
            depressed_mods=1 << shift_index,
            latched_mods=0,
            locked_mods=0,
            depressed_layout=0,
            latched_layout=0,
            locked_layout=0,
        )

    try:
        keycode = _find_keycode_for_symbol(key_label, "us")
        if keycode:
            keysym = state.key_get_one_sym(keycode)
            s = xkb.keysym_to_string(keysym)
            if s:
                return s
    except (UnicodeEncodeError, xkb.XKBKeyDoesNotExist):
        pass
    return key_label


class EnhancedJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if dataclasses.is_dataclass(o) and not isinstance(o, type):
            return dataclasses.asdict(o)
        return super().default(o)


@dataclasses.dataclass
class K:
    label: str
    keys_pressed: list[str] | None = None
    keys_held: list[str] | None = None
    layer_toggle: int | None = None
    layer_switch: str | None = None
    localize: bool = False
    keycodes_pressed: list[int] | None = dataclasses.field(init=False)
    keycodes_held: list[int] | None = dataclasses.field(init=False)

    def __post_init__(self):
        if self.label and not self.keys_pressed:
            self.keys_pressed = [self.label.upper()]

        def lookup_keys(names: list[str] | None):
            if not names:
                return None
            return [evdev.ecodes.ecodes[f"KEY_{name}"] for name in names]

        if not self.keys_held and self.keys_pressed:
            self.keys_held = self.keys_pressed

        self.keycodes_pressed = lookup_keys(self.keys_pressed)
        self.keycodes_held = lookup_keys(self.keys_held)


LayerSide = list[list[K | None] | None]


@dataclasses.dataclass
class Layer:
    left: LayerSide
    right: LayerSide


LAYOUT = {
    "main": Layer(
        left=[
            [K("Esc"), K("1"), K("2"), K("3"), K("4"), K("5")],
            [K("", layer_switch="sysnav"), K("q"), K("w"), K("e"), K("r"), K("t")],
            [
                K("Esc"),
                K("a"),
                K("s", keys_held=["LEFTALT"]),
                K("d", keys_held=["LEFTCTRL"]),
                K("f", keys_held=["LEFTSHIFT"]),
                K("g"),
            ],
            [K(""), K("z"), K("x"), K("c"), K("v"), K("b")],
            [
                None,
                None,
                None,
                None,
                K("↵", ["ENTER"], layer_switch="symnum"),
                K("⌘", ["LEFTMETA"]),
            ],
        ],
        right=[
            [K("6"), K("7"), K("8"), K("9"), K("0"), K("⌫", ["BACKSPACE"])],
            [K("y"), K("u"), K("i"), K("o"), K("p"), K("", layer_switch="symnum")],
            [
                K("h"),
                K("j", keys_held=["RIGHTSHIFT"]),
                K("k", keys_held=["RIGHTCTRL"]),
                K("l", keys_held=["RIGHTALT"]),
                K(";", ["SEMICOLON"], localize=True),
                K("Esc"),
            ],
            [
                K("n"),
                K("m"),
                K(",", ["COMMA"], localize=True),
                K(".", ["DOT"], localize=True),
                K("/", ["SLASH"], localize=True),
                K(""),
            ],
            [
                K("⌫", ["BACKSPACE"]),
                K("␣", ["SPACE"], layer_switch="sysnav"),
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
                K("F1", ["F1"]),
                K("F2", ["F2"]),
                K("F3", ["F3"]),
                K("F4", ["F4"]),
                K("F5", ["F5"]),
            ],
            [
                None,
                None,
                K("`", ["GRAVE"], localize=True),
                K("'", ["APOSTROPHE"], localize=True),
                K("[", ["LEFTBRACE"], localize=True),
                K("]", ["RIGHTBRACE"], localize=True),
            ],
            [
                None,
                None,
                K("-", ["MINUS"], keys_held=["LEFTALT"], localize=True),
                K("=", ["EQUAL"], keys_held=["LEFTCTRL"], localize=True),
                K(";", ["SEMICOLON"], keys_held=["LEFTSHIFT"], localize=True),
                K(":", ["LEFTSHIFT", "SEMICOLON"], localize=True),
            ],
            [
                None,
                None,
                K("_", ["LEFTSHIFT", "MINUS"], localize=True),
                K("+", ["LEFTSHIFT", "EQUAL"], localize=True),
                K("\\", ["BACKSLASH"], localize=True),
                K("/", ["SLASH"], localize=True),
            ],
            [
                None,
                None,
                None,
                None,
                K("↵", ["ENTER"], layer_switch="main"),
                K("⌘", ["LEFTMETA"]),
            ],
        ],
        right=[
            [
                K("F6", ["F6"]),
                K("F7", ["F7"]),
                K("F8", ["F8"]),
                K("F9", ["F9"]),
                K("F10", ["F10"]),
                None,
            ],
            [
                K("7", ["7"]),
                K("8", ["8"]),
                K("9", ["9"]),
                K("F11", ["F11"]),
                K("F12", ["F12"]),
                None,
            ],
            [
                K("4", ["4"]),
                K("5", ["5"], keys_held=["RIGHTSHIFT"]),
                K("6", ["6"], keys_held=["RIGHTCTRL"]),
                K(",", ["COMMA"], keys_held=["RIGHTALT"], localize=True),
                None,
                None,
            ],
            [
                K("1", ["1"]),
                K("2", ["2"]),
                K("3", ["3"]),
                K(".", ["DOT"], localize=True),
                None,
                None,
            ],
            [
                K("⌫", ["BACKSPACE"]),
                K("␣", ["SPACE"], layer_switch="sysnav"),
                None,
                None,
                None,
                None,
            ],
        ],
    ),
    "sysnav": Layer(
        left=[
            [None, None, None, None, None, K("BRI+", ["BRIGHTNESSUP"])],
            [
                None,
                None,
                K("MUTE", ["MUTE"]),
                K("VOL-", ["VOLUMEDOWN"]),
                K("VOL+", ["VOLUMEUP"]),
                K("BRI-", ["BRIGHTNESSDOWN"]),
            ],
            [
                None,
                None,
                K("ALT", ["LEFTALT"], keys_held=["LEFTALT"]),
                K("CTRL", ["LEFTCTRL"], keys_held=["LEFTCTRL"]),
                K("SHIFT", ["LEFTSHIFT"], keys_held=["LEFTSHIFT"]),
                None,
            ],
            [
                None,
                K("←W", ["LEFTMETA", "LEFTSHIFT", "PAGEUP"]),
                K("W→", ["LEFTMETA", "LEFTSHIFT", "PAGEDOWN"]),
                K("Copy", keys_pressed=["LEFTCTRL", "C"]),
                K("Paste", keys_pressed=["LEFTCTRL", "V"]),
                K("CapsL", ["CAPSLOCK"]),
            ],
            [
                None,
                None,
                None,
                None,
                K("↵", ["ENTER"], layer_switch="symnum"),
                K("⌘", ["LEFTMETA"]),
            ],
        ],
        right=[
            None,
            [
                K("PgUp", ["PAGEUP"]),
                K("PgDn", ["PAGEDOWN"]),
                K("Home", ["HOME"]),
                K("End", ["END"]),
                K("PrtSc", ["PRINT"]),
                None,
            ],
            [
                K("←", ["LEFT"]),
                K("↓", ["DOWN"]),
                K("↑", ["UP"]),
                K("→", ["RIGHT"]),
                K("모", ["LEFTALT", "LEFTCTRL", "T"]),
                None,
            ],
            [
                K("Tab", ["TAB"]),
                K("⌫", ["BACKSPACE"]),
                K("⌦", ["DELETE"]),
                K("←W", ["LEFTALT", "LEFTCTRL", "LEFT"]),
                K("W→", ["LEFTALT", "LEFTCTRL", "RIGHT"]),
                None,
            ],
            [
                K("⌫", ["BACKSPACE"]),
                K("␣", ["SPACE"], layer_switch="main"),
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
    parser.add_argument(
        "layout",
        nargs="?",
        default="us",
        help="current kb layout name",
    )
    parser.add_argument(
        "shift",
        nargs="?",
        default="off",
        help="current shift state",
    )
    args = parser.parse_args()
    layer_name = args.layer

    def _merge_side(selected_side: LayerSide, main_side: LayerSide) -> LayerSide:
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

    def _localize_side(side: LayerSide) -> LayerSide:
        def _process_key(key: K | None) -> K | None:
            if key is None:
                return key

            should_localize = key.localize or (
                key.keys_pressed is not None
                and len(key.keys_pressed) == 1
                and key.keys_pressed[0] == key.label.upper()
            )

            if should_localize:
                lookup_symbol = key.label
                if (
                    key.keys_pressed
                    and len(key.keys_pressed) == 1
                    and key.keys_pressed[0] != key.label.upper()
                ):
                    lookup_symbol = key.keys_pressed[0]

                res = get_layout_label(
                    lookup_symbol,
                    args.layout,
                    args.shift == "on",
                )

                if res == lookup_symbol and lookup_symbol.isupper():
                    evdev_to_xkb_keysym = {
                        "LEFTBRACE": "bracketleft",
                        "RIGHTBRACE": "bracketright",
                        "BACKSLASH": "backslash",
                        "SLASH": "slash",
                        "GRAVE": "grave",
                        "APOSTROPHE": "apostrophe",
                        "SEMICOLON": "semicolon",
                        "COMMA": "comma",
                        "DOT": "period",
                        "MINUS": "minus",
                        "EQUAL": "equal",
                        "SPACE": "space",
                    }
                    mapped_name = evdev_to_xkb_keysym.get(lookup_symbol)
                    if mapped_name:
                        res2 = get_layout_label(
                            mapped_name, args.layout, args.shift == "on"
                        )
                        if res2 and res2 != mapped_name:
                            res = res2

                key.label = res
            return key

        return [[_process_key(key) for key in row] if row else row for row in side]

    merged_layer = Layer(
        left=_localize_side(_merge_side(LAYOUT[layer_name].left, LAYOUT["main"].left)),
        right=_localize_side(
            _merge_side(LAYOUT[layer_name].right, LAYOUT["main"].right)
        ),
    )

    print(json.dumps(merged_layer, cls=EnhancedJSONEncoder))
