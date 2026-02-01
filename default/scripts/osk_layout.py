import dataclasses
import json
import evdev


class EnhancedJSONEncoder(json.JSONEncoder):
    def default(self, o):
        if dataclasses.is_dataclass(o):
            return dataclasses.asdict(o)
        return super().default(o)


@dataclasses.dataclass
class K:
    label: str
    key_pressed: str | None = None
    key_held: str | None = None
    layer_toggle: int | None = None
    layer_switch: int | None = None
    keycode_pressed: int | None = dataclasses.field(init=False)
    keycode_held: int | None = dataclasses.field(init=False)

    def __post_init__(self):
        if self.label and not self.key_pressed:
            self.key_pressed = self.label.upper()
        if self.key_pressed:
            self.keycode_pressed = evdev.ecodes.ecodes[f"KEY_{self.key_pressed}"]
        else:
            self.keycode_pressed = None
        if self.key_held:
            self.keycode_held = evdev.ecodes.ecodes[f"KEY_{self.key_held}"]
        else:
            self.keycode_held = None


@dataclasses.dataclass
class Layer:
    left: list[list[K | None]]
    right: list[list[K | None]]


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
            [None, None, None, None, K("↵", "ENTER"), K("⌘", "LEFTMETA")],
        ],
        right=[
            [K("6"), K("7"), K("8"), K("9"), K("0"), K("")],
            [K("y"), K("u"), K("i"), K("o"), K("p"), K("")],
            [
                K("h"),
                K("j", key_held="RIGHTSHIFT"),
                K("k", key_held="RIGHTCTRL"),
                K("l", key_held="RIGHTALT"),
                K(";", "SEMICOLON"),
                K(""),
            ],
            [K("n"), K("m"), K(",", "COMMA"), K(".", "DOT"), K("/", "SLASH"), K("")],
            [K("⌫", "BACKSPACE"), K("␣", "SPACE"), None, None, None, None],
        ],
    ),
}

if __name__ == "__main__":
    print(json.dumps(LAYOUT, cls=EnhancedJSONEncoder))
