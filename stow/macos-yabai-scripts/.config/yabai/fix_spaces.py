#!/usr/bin/env python3

"""Rebalance yabai spaces across displays while preserving layouts and windows."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Iterable, List, Optional, Set


SINGLE_DISPLAY_LABELS: List[str] = [
    "s1",
    "s2",
    "s3",
    "s4",
    "sC",
    "sM",
    "sV",
    "sT",
    "sG",
    "sB",
    "s16",
    "s5",
    "s6",
    "s7",
    "s8",
    "s9",
]

DUAL_DISPLAY_LABELS: List[str] = [
    "s1",
    "s2",
    "s3",
    "s4",
    "sC",
    "sM",
    "sV",
    "sT",
    "sG",
    "sB",
    "s16",
    "s5",
    "s6",
    "s7",
    "s8",
    "s9",
]

SECOND_DISPLAY_SPACES: List[str] = [
        "s5",
        "s6",
        "s7",
        "s8",
        "s9",
]

SPACE_MOVE_DELAY_SECONDS = 0.2

LOG_PATH = os.path.expanduser("~/tmp/fix_spaces.log")


def log_message(message: str) -> None:
    """Write message to log file with timestamp."""
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a") as f:
        f.write(f"[{timestamp}] {message}\n")


def log_spaces_diagnostics() -> None:
    """Log all spaces with display information for diagnostics."""
    try:
        spaces = query_spaces()
        displays = query_displays()

        log_message("=== STARTUP DIAGNOSTICS ===")
        log_message(f"Total displays: {len(displays)}")
        for display in displays:
            log_message(f"Display {display['index']}: {display.get('resolution', 'unknown resolution')}")

        log_message(f"Total spaces: {len(spaces)}")
        for space in spaces:
            display_info = space.get('display', 'unknown')
            label = space.get('label', 'no label')
            log_message(f"Space {space['index']}: label='{label}', display={display_info}")

        # Count spaces per display
        display_counts = {}
        for space in spaces:
            display = space.get('display', 'unknown')
            display_counts[display] = display_counts.get(display, 0) + 1

        for display, count in display_counts.items():
            log_message(f"Display {display}: {count} space(s)")

        log_message("=== END DIAGNOSTICS ===")
    except Exception as e:
        log_message(f"Error during diagnostics: {e}")


def print_and_log(message: str) -> None:
    """Print message to stdout and also log it."""
    print(message)
    log_message(message)


class YabaiError(RuntimeError):
    """Raised when a yabai command fails."""


def run_yabai(*args: str) -> str:
    result = subprocess.run(["yabai", "-m", *args], capture_output=True, text=True)
    stderr = result.stderr.strip()
    stdout = result.stdout.strip()
    command = " ".join(args)
    if "error with the scripting-addition" in stderr.lower() or "error with the scripting-addition" in stdout.lower():
        raise YabaiError(f"yabai {command}: scripting-addition error")
    if (result.returncode != 0
            and "cannot move space to itself" not in stderr.lower()
            and "acting space is already located on the given display" not in stderr.lower()
            and "value '__temp__' is not a valid option for SPACE_SEL" not in stderr.lower()):
        raise YabaiError(f"yabai {command}: {stderr or 'failed'}")
    return stdout


def query_spaces() -> List[dict]:
    output = run_yabai("query", "--spaces")
    spaces = json.loads(output)
    return sorted(spaces, key=lambda space: space["index"])


def arrange_spaces_by_label(spaces: Iterable[dict]) -> Dict[str, dict]:
    return {space["label"]: space for space in spaces}


def query_displays() -> List[dict]:
    output = run_yabai("query", "--displays")
    displays = json.loads(output)
    return sorted(displays, key=lambda display: display["index"])


def get_last_empty_labeled_space_index() -> int:
    spaces = query_spaces()
    last_space = max(spaces, key=lambda space: 0 if space["label"] else int(space["index"]))
    return last_space["index"]


def destroy_space_by_index(index: int) -> None:
    run_yabai("space", str(index), "--destroy")
    time.sleep(SPACE_MOVE_DELAY_SECONDS)


def print_spaces(spaces):
    for space in spaces:
        print(str(space["index"]) + ": " + space["label"])


def trim_extra_spaces(allowed_labels: Set[str]) -> None:
    spaces = query_spaces()
    spaces.sort(key=lambda space: space["index"], reverse=True) # overwise index this shift
    for space in spaces:
        label = space.get("label")
        index = space["index"]
        if not label:
            print_and_log(f"destroying empty labeled space {index}")
            destroy_space_by_index(index)
            continue
        if label not in allowed_labels:
            print_and_log(f"destroying space {label} by index: {index}")
            destroy_space_by_index(index)


def move_space_to_display(label: str, display_index: int) -> None:
    try:
        run_yabai("space", label, "--display", str(display_index))
    except YabaiError as error:
        message = str(error).lower()
        if not "acting space is already located on the given display" in message:
            raise
    time.sleep(SPACE_MOVE_DELAY_SECONDS)


def create_space_and_label(label: str) -> None:
    run_yabai("space", "--create")
    time.sleep(SPACE_MOVE_DELAY_SECONDS)
    new_space = get_last_empty_labeled_space_index()
    print_and_log(f"new space created: {new_space} naming it {label}")
    run_yabai("space", str(new_space), "--label", label, '--display', '1')
    time.sleep(SPACE_MOVE_DELAY_SECONDS)


def creating_missing_spaces(label_order: List[str]) -> None:
    spaces_by_label = arrange_spaces_by_label(query_spaces())

    # creating missed spaces
    for label in label_order:
        if label not in spaces_by_label:
            print_and_log(f"creating missing space {label}")
            create_space_and_label(label)
   

def populate_second_display():
    spaces_by_label = arrange_spaces_by_label(query_spaces())
    for label in SECOND_DISPLAY_SPACES:
        space = spaces_by_label[label]
        index = space["index"]
        if space["display"] != 2:
            print_and_log(f"moving space {index}:{label} to display 2")
            move_space_to_display(label, 2)


def fix_spaces_order(label_order: List[str]) -> None:
    spaces_by_label = arrange_spaces_by_label(query_spaces())

    for ind in range(len(label_order)):
        label = label_order[ind]
        space = spaces_by_label[label]
        space_index = space["index"]
        dest = ind + 1
        if int(space_index) != dest:
            print_and_log(f"fixing {label} from {space_index} to {dest}")
            run_yabai("space", label, "--move", str(dest))

def quick_fix1():
    # if we have space index 12 on the second display with not label, then label it s5
    # which is common case after sleep

    spaces = query_spaces()
    ind_12_space = spaces[11]

    if ind_12_space["display"] == 2 and ind_12_space["label"] == "" and ind_12_space["index"] == 12:
        print_and_log("space ind 12 is already on display 2 but has no labels, might be s5, labelng it")
        run_yabai("space", "12", "--label", "s5")


def main() -> None:
    log_message("=== fix_spaces.py started ===")
    log_spaces_diagnostics()

    quick_fix1()

    displays = query_displays()
    two_displays_layout = len(displays) > 1

    label_order = DUAL_DISPLAY_LABELS if two_displays_layout else SINGLE_DISPLAY_LABELS
    log_message(f"Using {'dual' if two_displays_layout else 'single'} display layout with {len(label_order)} spaces")

    creating_missing_spaces(label_order)
    trim_extra_spaces(set(label_order))

    if two_displays_layout:
        populate_second_display()

    fix_spaces_order(label_order)

    subprocess.run(["osascript", "-e", 'tell application id "tracesOf.Uebersicht" to refresh'])
    log_message("=== fix_spaces.py completed ===")


if __name__ == "__main__":
    try:
        main()
    except YabaiError as error:
        error_msg = str(error)
        print(error_msg, file=sys.stderr)
        log_message(f"YABAI ERROR: {error_msg}")
        sys.exit(1)
    except Exception as error:
        error_msg = str(error)
        print(error_msg, file=sys.stderr)
        log_message(f"UNEXPECTED ERROR: {error_msg}")
        sys.exit(1)

