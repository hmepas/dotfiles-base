#!/usr/bin/env python3
"""Live Hyprland keybinding cheatsheet.

The source of truth is the description attached to each hl.bind() call.  This
script reads the active configuration through `hyprctl binds -j`, so loops,
submaps and conditionally loaded plugin bindings are represented correctly.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import signal
import subprocess
import sys
import time
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

DESCRIPTION_RE = re.compile(r"^\[([^]]+)]\s*(.+)$")

# XKB modifier masks used by Hyprland.
MODIFIERS = (
    (64, "Super", "Su"),
    (32, "Hyper", "Hy"),
    (4, "Ctrl", "C"),
    (8, "Alt", "A"),
    (1, "Shift", "Sh"),
    (2, "Caps", "Caps"),
    (16, "Mod2", "M2"),
    (128, "Mod5", "M5"),
)

CATEGORY_ORDER = (
    "Справка",
    "Приложения",
    "Терминал",
    "Навигация",
    "Окна",
    "Мониторы",
    "Рабочие столы",
    "Группы",
    "Обзор",
    "Буфер обмена",
    "Снимки экрана",
    "Медиа",
    "Система",
)

# These letters work as immediate category selectors in the English layout.
CATEGORY_KEYS = {
    "Окна": "W",
    "Навигация": "N",
    "Рабочие столы": "D",
    "Мониторы": "M",
    "Приложения": "A",
    "Терминал": "T",
    "Буфер обмена": "C",
    "Снимки экрана": "S",
    "Медиа": "V",
    "Группы": "G",
    "Обзор": "E",
    "Система": "X",
    "Справка": "H",
}

KEY_LABELS = {
    "space": "Space",
    "tab": "Tab",
    "return": "Enter",
    "escape": "Esc",
    "comma": ",",
    "period": ".",
    "slash": "/",
    "semicolon": ";",
    "apostrophe": "'",
    "bracketleft": "[",
    "bracketright": "]",
    "backslash": "\\",
    "minus": "-",
    "equal": "=",
    "grave": "`",
    "left": "←",
    "right": "→",
    "up": "↑",
    "down": "↓",
    "mouse_down": "Wheel↓",
    "mouse_up": "Wheel↑",
    "mouse:272": "LMB",
    "mouse:273": "RMB",
    "xf86audioraisevolume": "Volume+",
    "xf86audiolowervolume": "Volume−",
    "xf86audiomute": "Mute",
    "xf86audiomicmute": "Mic mute",
    "xf86audionext": "Next track",
    "xf86audiopause": "Pause",
    "xf86audioplay": "Play",
    "xf86audioprev": "Prev track",
}

CATEGORY_COLORS = {
    "Справка": "#e0af68",
    "Приложения": "#7aa2f7",
    "Терминал": "#73daca",
    "Навигация": "#9ece6a",
    "Окна": "#bb9af7",
    "Мониторы": "#2ac3de",
    "Рабочие столы": "#7dcfff",
    "Группы": "#c0caf5",
    "Обзор": "#b4f9f8",
    "Буфер обмена": "#ff9e64",
    "Снимки экрана": "#f7768e",
    "Медиа": "#e0af68",
    "Система": "#db4b4b",
}


@dataclass(frozen=True)
class Binding:
    category: str
    description: str
    modmask: int
    key: str
    submap: str

    @property
    def normalized_key(self) -> str:
        return self.key.lower()

    @property
    def key_label(self) -> str:
        normalized = self.normalized_key
        if normalized in KEY_LABELS:
            return KEY_LABELS[normalized]
        if len(self.key) == 1:
            return self.key.upper()
        if self.key.lower().startswith("xf86"):
            return self.key[4:]
        return self.key

    @property
    def shortcut(self) -> str:
        parts = [label for mask, label, _ in MODIFIERS if self.modmask & mask]
        parts.append(self.key_label)
        shortcut = "+".join(parts)
        if self.submap:
            return f"{self.submap}: {shortcut}"
        return shortcut

    @property
    def compact_modifiers(self) -> str:
        if self.submap:
            return "Expo"
        labels = [short for mask, _, short in MODIFIERS if self.modmask & mask]
        return "+".join(labels) if labels else "—"


def notify_error(message: str) -> None:
    try:
        subprocess.run(
            ["notify-send", "Шпаргалка Hyprland", message],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        pass


def load_bindings() -> list[Binding]:
    try:
        result = subprocess.run(
            ["hyprctl", "binds", "-j"],
            check=True,
            capture_output=True,
            text=True,
        )
        raw_bindings = json.loads(result.stdout)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        raise RuntimeError(f"не удалось прочитать hyprctl binds: {error}") from error

    bindings: list[Binding] = []
    seen: set[tuple[str, str, int, str, str]] = set()
    for raw in raw_bindings:
        description = str(raw.get("description") or "").strip()
        match = DESCRIPTION_RE.match(description)
        if not match:
            continue

        binding = Binding(
            category=match.group(1),
            description=match.group(2),
            modmask=int(raw.get("modmask", 0)),
            key=str(raw.get("key") or ""),
            submap=str(raw.get("submap") or ""),
        )
        identity = (
            binding.category,
            binding.description,
            binding.modmask,
            binding.key,
            binding.submap,
        )
        if binding.key and identity not in seen:
            seen.add(identity)
            bindings.append(binding)

    if not bindings:
        raise RuntimeError("в активной конфигурации нет биндов с описаниями")
    return bindings


def category_rank(category: str) -> tuple[int, str]:
    try:
        return CATEGORY_ORDER.index(category), category
    except ValueError:
        return len(CATEGORY_ORDER), category


def sorted_bindings(bindings: list[Binding]) -> list[Binding]:
    return sorted(
        bindings,
        key=lambda bind: (category_rank(bind.category), bind.shortcut.casefold(), bind.description.casefold()),
    )


def rofi_command(prompt: str, message: str, width: int = 1050, lines: int = 20) -> list[str]:
    return [
        "rofi",
        "-dmenu",
        "-i",
        "-no-custom",
        "-matching",
        "fuzzy",
        "-p",
        prompt,
        "-mesg",
        message,
        "-theme-str",
        (
            f"window {{ width: {width}px; }} "
            f"listview {{ lines: {lines}; }} "
            "element-text { font: \"JetBrainsMono Nerd Font 13\"; } "
            "entry { placeholder: \"Начните печатать для поиска…\"; }"
        ),
    ]


def binding_rows(bindings: list[Binding], include_category: bool = True) -> list[str]:
    ordered = sorted_bindings(bindings)
    category_width = max((len(binding.category) for binding in ordered), default=0)
    shortcut_width = max((len(binding.shortcut) for binding in ordered), default=0)
    shortcut_width = max(18, min(shortcut_width, 30))

    rows = []
    for binding in ordered:
        if include_category:
            rows.append(
                f"{binding.category:<{category_width}}  {binding.shortcut:<{shortcut_width}}  {binding.description}"
            )
        else:
            rows.append(f"{binding.shortcut:<{shortcut_width}}  {binding.description}")
    return rows


def show_bindings_rofi(bindings: list[Binding], category: str | None = None) -> None:
    selected = [binding for binding in bindings if category is None or binding.category == category]
    prompt = category or "Клавиши"
    message = (
        "Esc — закрыть · поиск работает по клавишам, категориям и описаниям"
        if category is None
        else "Esc — закрыть · начните печатать для фильтрации"
    )
    subprocess.run(
        rofi_command(prompt, message) + ["-format", "s"],
        input="\n".join(binding_rows(selected, include_category=category is None)),
        text=True,
        check=False,
    )


def show_categories_rofi(bindings: list[Binding]) -> None:
    counts = Counter(binding.category for binding in bindings)
    categories = sorted(counts, key=category_rank)
    rows: list[str] = []
    for category in categories:
        key = CATEGORY_KEYS.get(category, "·")
        rows.append(f"{key:<2}  {category:<18}  {counts[category]:>2} сочетаний")

    command = rofi_command(
        "Категория",
        "Буква — открыть сразу (в раскладке EN) · Enter — выбрать · Esc — закрыть",
        width=620,
        lines=min(16, len(rows)),
    )
    custom_categories: list[str] = []
    for index, category in enumerate(categories, start=1):
        key = CATEGORY_KEYS.get(category)
        if key and index <= 19:
            command.extend([f"-kb-custom-{index}", key.lower()])
            custom_categories.append(category)
        else:
            custom_categories.append("")

    result = subprocess.run(
        command + ["-format", "s"],
        input="\n".join(rows),
        text=True,
        capture_output=True,
        check=False,
    )

    category: str | None = None
    custom_index = result.returncode - 10
    if 0 <= custom_index < len(custom_categories):
        category = custom_categories[custom_index] or None
    elif result.returncode == 0 and result.stdout.strip():
        selected_row = result.stdout.strip()
        try:
            category = categories[rows.index(selected_row)]
        except ValueError:
            category = None

    if category:
        show_bindings_rofi(bindings, category)


def visual_description(description: str) -> str:
    exact = {
        "Поиск по всем сочетаниям": "Поиск",
        "Справка по категориям": "Категории",
        "Визуальная карта клавиш": "Карта",
        "Переключить псевдотайлинг": "Псевдотайлинг",
        "Предыдущее окно в группе": "Группа назад",
        "Следующее окно в группе": "Группа вперёд",
        "Поменять направление разделения": "Сменить split",
        "Переключиться на следующее окно": "Следующее окно",
        "Показать обзор рабочих столов": "Обзор столов",
        "Начать или остановить запись OBS": "Запись OBS",
    }
    if description in exact:
        return exact[description]

    replacements = (
        ("Переместить окно на рабочий стол ", "Окно → стол "),
        ("Перейти на рабочий стол ", "Стол "),
        ("Переместить окно ", "Окно "),
        ("Поменять с окном ", "Swap "),
        ("Переключить ", ""),
        ("Открыть или сфокусировать ", ""),
        ("Открыть ", ""),
        (" в активном окне", ""),
        (" в обзоре", ""),
        ("рабочих столов", "столов"),
        ("рабочий стол", "стол"),
        ("активное окно", "окно"),
    )
    shortened = description
    for old, new in replacements:
        shortened = shortened.replace(old, new)
    return shortened


def svg_text(x: float, y: float, value: str, css_class: str = "binding", anchor: str = "start") -> str:
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" class="{css_class}" '
        f'text-anchor="{anchor}">{html.escape(value)}</text>'
    )


def render_visual_map(bindings: list[Binding], destination: Path) -> None:
    # (Hyprland key name, displayed label, width in key units); None is a gap.
    rows: list[list[tuple[str | None, str, float]]] = [
        [("escape", "Esc", 1.0)]
        + [(f"f{i}", f"F{i}", 1.0) for i in range(1, 13)]
        + [("print", "Print", 1.35)],
        [("grave", "`", 1.0)]
        + [(str(i), str(i), 1.0) for i in range(1, 10)]
        + [("0", "0", 1.0), ("minus", "-", 1.0), ("equal", "=", 1.0), (None, "Backspace", 1.8)],
        [("tab", "Tab", 1.5)]
        + [(letter.lower(), letter, 1.0) for letter in "QWERTYUIOP"]
        + [("bracketleft", "[", 1.0), ("bracketright", "]", 1.0), ("backslash", "\\", 1.25)],
        [(None, "Caps / Hyper", 1.8)]
        + [(letter.lower(), letter, 1.0) for letter in "ASDFGHJKL"]
        + [("semicolon", ";", 1.0), ("apostrophe", "'", 1.0), ("return", "Enter", 2.0)],
        [(None, "Shift", 2.25)]
        + [(letter.lower(), letter, 1.0) for letter in "ZXCVBNM"]
        + [("comma", ",", 1.0), ("period", ".", 1.0), ("slash", "/", 1.0), (None, "Shift", 2.55)],
        [
            (None, "Ctrl", 1.3),
            (None, "Super", 1.3),
            (None, "Alt", 1.3),
            ("space", "Space", 5.2),
            (None, "Alt", 1.3),
            ("left", "←", 1.0),
            ("down", "↓", 1.0),
            ("up", "↑", 1.0),
            ("right", "→", 1.0),
        ],
    ]

    bindings_by_key: dict[str, list[Binding]] = defaultdict(list)
    for binding in sorted_bindings(bindings):
        bindings_by_key[binding.normalized_key].append(binding)

    used_keys = {key for row in rows for key, _, _ in row if key}
    extra_bindings = [binding for binding in sorted_bindings(bindings) if binding.normalized_key not in used_keys]

    canvas_width = 2040
    canvas_height = 1300
    margin_x = 38
    keyboard_y = 132
    unit_width = 118
    key_height = 126
    gap = 7
    row_gap = 10

    svg: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_width}" height="{canvas_height}" viewBox="0 0 {canvas_width} {canvas_height}">',
        "<style>",
        "text { font-family: 'JetBrains Mono', 'DejaVu Sans Mono', monospace; fill: #c0caf5; }",
        ".title { font-size: 30px; font-weight: 700; fill: #7aa2f7; }",
        ".legend { font-size: 16px; fill: #a9b1d6; }",
        ".key-label { font-size: 16px; font-weight: 700; fill: #c0caf5; }",
        ".binding { font-size: 12px; fill: #c0caf5; }",
        ".section { font-size: 20px; font-weight: 700; fill: #bb9af7; }",
        ".extra { font-size: 15px; fill: #c0caf5; }",
        "</style>",
        f'<rect width="{canvas_width}" height="{canvas_height}" rx="24" fill="#1a1b26"/>',
        svg_text(margin_x, 48, "Hyprland — карта клавиш", "title"),
        svg_text(
            margin_x,
            82,
            "Su = Super   Hy = Hyper/Caps Lock   C = Ctrl   A = Alt   Sh = Shift   Expo = режим обзора",
            "legend",
        ),
        svg_text(
            margin_x,
            108,
            "Hyper+H: поиск   ·   Hyper+Shift+H: категории   ·   Hyper+Ctrl+H: показать/скрыть карту   ·   Esc/Q: закрыть",
            "legend",
        ),
    ]

    for row_index, row in enumerate(rows):
        x = margin_x
        y = keyboard_y + row_index * (key_height + row_gap)
        for key, label, units in row:
            width = units * unit_width + (units - 1) * gap
            key_bindings = bindings_by_key.get(key or "", [])
            accent = CATEGORY_COLORS.get(key_bindings[0].category, "#414868") if key_bindings else "#414868"
            fill = "#24283b" if key_bindings else "#1f2335"
            svg.append(
                f'<rect x="{x:.1f}" y="{y:.1f}" width="{width:.1f}" height="{key_height}" '
                f'rx="9" fill="{fill}" stroke="{accent}" stroke-width="{2 if key_bindings else 1}"/>'
            )
            svg.append(svg_text(x + 9, y + 20, label, "key-label"))

            max_lines = 7
            max_chars = max(8, int((width - 14) / 7.0))
            for line_index, binding in enumerate(key_bindings[:max_lines]):
                prefix = f"{binding.compact_modifiers}: "
                available = max(5, max_chars - len(prefix))
                description = visual_description(binding.description)
                if len(description) > available:
                    description = description[: max(1, available - 1)].rstrip() + "…"
                svg.append(svg_text(x + 9, y + 39 + line_index * 13, prefix + description))
            if len(key_bindings) > max_lines:
                svg.append(svg_text(x + 9, y + 39 + (max_lines - 1) * 13, f"… ещё {len(key_bindings) - max_lines}"))
            x += width + gap

    extras_y = keyboard_y + len(rows) * (key_height + row_gap) + 8
    svg.append(svg_text(margin_x, extras_y, "Мышь и мультимедийные клавиши", "section"))
    extras_y += 30
    columns = 2
    column_width = (canvas_width - 2 * margin_x) / columns
    rows_per_column = max(1, (len(extra_bindings) + columns - 1) // columns)
    for index, binding in enumerate(extra_bindings):
        column = index // rows_per_column
        row = index % rows_per_column
        x = margin_x + column * column_width
        y = extras_y + row * 25
        color = CATEGORY_COLORS.get(binding.category, "#7aa2f7")
        svg.append(f'<circle cx="{x + 5:.1f}" cy="{y - 5:.1f}" r="4" fill="{color}"/>')
        svg.append(svg_text(x + 18, y, f"{binding.shortcut:<24} {binding.description}", "extra"))

    svg.append("</svg>")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(svg), encoding="utf-8")


def is_cheatsheet_process(pid: int) -> bool:
    try:
        command_line = Path(f"/proc/{pid}/cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
    except (OSError, ValueError):
        return False
    return "imv" in command_line and "hyprland-keybindings" in command_line


def stop_visual_process(pid: int) -> None:
    # imv-msg asks imv to quit cleanly. Fall back to SIGTERM if its IPC socket
    # is not ready yet (for example after pressing the toggle twice very fast).
    try:
        result = subprocess.run(
            ["imv-msg", str(pid), "quit"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=1,
        )
    except (OSError, subprocess.TimeoutExpired):
        result = None

    if result is None or result.returncode != 0:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            return

    for _ in range(10):
        if not is_cheatsheet_process(pid):
            return
        time.sleep(0.03)

    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass


def stop_existing_visual(pid_file: Path) -> bool:
    stopped = False

    try:
        pid = int(pid_file.read_text(encoding="ascii").strip())
    except (OSError, ValueError):
        pid = 0

    if pid and is_cheatsheet_process(pid):
        stop_visual_process(pid)
        stopped = True

    # Also clean up windows started before the PID-file toggle was introduced,
    # or duplicate instances left by two nearly simultaneous invocations.
    try:
        result = subprocess.run(
            ["hyprctl", "clients", "-j"],
            check=True,
            capture_output=True,
            text=True,
        )
        clients = json.loads(result.stdout)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        clients = []

    for client in clients:
        window_class = str(client.get("class") or "").lower()
        title = str(client.get("title") or "").lower()
        client_pid = int(client.get("pid") or 0)
        if client_pid and (window_class == "hyprland-keybindings" or title == "hyprland keybindings"):
            if client_pid != pid and is_cheatsheet_process(client_pid):
                stop_visual_process(client_pid)
            stopped = True

    pid_file.unlink(missing_ok=True)
    return stopped


def show_visual_map(bindings: list[Binding]) -> None:
    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    pid_file = runtime_dir / "hyprland-keybindings.pid"

    # The visual-map hotkey and the Waybar right click are true toggles.
    if stop_existing_visual(pid_file):
        return

    destination = runtime_dir / "hyprland-keybindings.svg"
    render_visual_map(bindings, destination)
    try:
        process = subprocess.Popen(
            [
                "imv",
                "-f",
                "-i",
                "hyprland-keybindings",
                "-w",
                "Hyprland keybindings",
                "-c",
                "bind <Escape> quit",
                "-c",
                "bind q quit",
                str(destination),
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        pid_file.write_text(f"{process.pid}\n", encoding="ascii")
    except OSError as error:
        raise RuntimeError(f"не удалось открыть карту через imv: {error}") from error


def find_binding(bindings: list[Binding], modmask: int, key: str) -> Binding | None:
    return next(
        (
            binding
            for binding in bindings
            if binding.modmask == modmask and binding.normalized_key == key.lower() and not binding.submap
        ),
        None,
    )


def waybar_payload(bindings: list[Binding]) -> dict[str, str]:
    tooltip = [
        "󰌌  Шпаргалка Hyprland",
        "ЛКМ: поиск · СКМ: категории · ПКМ: карта",
        "",
    ]
    favorites = (
        (4, "space"),       # Ctrl+Space
        (8, "tab"),         # Alt+Tab
        (64, "q"),          # Super+Q
        (64, "e"),          # Super+E
        (64, "t"),          # Super+T
        (64, "tab"),        # Super+Tab
        (64 + 8, "c"),      # Super+Alt+C
        (0, "print"),       # Print
        (32, "right"),      # Hyper+Right
    )
    for modmask, key in favorites:
        binding = find_binding(bindings, modmask, key)
        if binding:
            tooltip.append(f"{binding.shortcut:<18} {binding.description}")

    return {
        "text": "󰌌",
        "tooltip": "\n".join(tooltip),
        "class": "keybindings",
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--rofi", action="store_true", help="search all described bindings")
    mode.add_argument("--categories", action="store_true", help="open a which-key-style category menu")
    mode.add_argument("--visual", action="store_true", help="generate and open a visual keyboard map")
    mode.add_argument("--waybar", action="store_true", help="print Waybar JSON")
    mode.add_argument("--dump", action="store_true", help="print the normalized binding table")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        bindings = load_bindings()
    except RuntimeError as error:
        if args.waybar:
            print(json.dumps({"text": "󰌌", "tooltip": str(error)}, ensure_ascii=False))
        else:
            notify_error(str(error))
            print(error, file=sys.stderr)
        return 1

    if args.rofi:
        show_bindings_rofi(bindings)
    elif args.categories:
        show_categories_rofi(bindings)
    elif args.visual:
        show_visual_map(bindings)
    elif args.waybar:
        print(json.dumps(waybar_payload(bindings), ensure_ascii=False))
    elif args.dump:
        print("\n".join(binding_rows(bindings)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
