#!/usr/bin/env python3

"""Rebalance yabai spaces across displays while preserving layouts and windows."""

from __future__ import annotations

import json
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Set


SINGLE_DISPLAY_LABELS: List[str] = [
    "s1",
    "s2",
    "s3",
    "s4",
    "s5",
    "s6",
    "s7",
    "s8",
    "s9",
    "sC",
    "sM",
    "sV",
    "sT",
    "sG",
    "sB",
    "s16",
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

TEMP_LABEL = "__temp__"
MONITOR1_SPACE_COUNT = 11
MONITOR2_SPACE_COUNT = 5
SPACE_MOVE_DELAY_SECONDS = 0.05


class YabaiError(RuntimeError):
    """Raised when a yabai command fails."""


@dataclass(frozen=True)
class SpaceSnapshot:
    layout: Optional[str]
    windows: List[int]


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


def query_displays() -> List[dict]:
    output = run_yabai("query", "--displays")
    displays = json.loads(output)
    return sorted(displays, key=lambda display: display["index"])


def query_window_ids() -> Set[int]:
    output = run_yabai("query", "--windows")
    windows = json.loads(output)
    return {window["id"] for window in windows}


def snapshot_spaces(spaces: Iterable[dict]) -> Dict[str, SpaceSnapshot]:
    snapshot: Dict[str, SpaceSnapshot] = {}
    for space in spaces:
        label = space.get("label") or ""
        if not label:
            continue
        snapshot[label] = SpaceSnapshot(
            layout=space.get("type"),
            windows=list(space.get("windows", [])),
        )
    return snapshot


def temp_space_index(spaces: Iterable[dict]) -> Optional[int]:
    for space in spaces:
        if space.get("label") == TEMP_LABEL:
            return space["index"]
    return None


def get_last_display_index() -> int:
    displays = query_displays()
    last_display = max(displays, key=lambda display: display["index"])
    return last_display["index"]
    
    
def create_temp_space():
    print("creating temp space")
    run_yabai("space", "--create")
    updated_spaces = query_spaces()
    new_space = max(updated_spaces, key=lambda space: space["id"])
    temp_index = new_space["index"]
    last_display_index = get_last_display_index()
    run_yabai("space", str(temp_index),
              "--display", str(last_display_index),
              "--move", str(len(updated_spaces)),
              "--label", TEMP_LABEL,
              "--layout", "float")


def destroy_temp_space() -> None:
    run_yabai("space", "--destroy", TEMP_LABEL)


def destroy_space_by_index(index: int) -> None:
    run_yabai("space", str(index), "--destroy")
    time.sleep(SPACE_MOVE_DELAY_SECONDS)


def ensure_space_count(target_count: int) -> None:
    print("ensure space count started")
    spaces = query_spaces()
    current_count = len(spaces)
    print(f"{current_count} spaces exists needed {target_count}")
    for i in range(target_count - current_count):
        print("creating space")
        run_yabai("space", "--create")
    time.sleep(SPACE_MOVE_DELAY_SECONDS)
    

def trim_extra_spaces(allowed_labels: Set[str]) -> None:
    spaces = query_spaces()
    spaces.sort(key=lambda space: space["index"], reverse=True) # overwise index this shift
    for space in spaces:
        label = space.get("label")
        index = space["index"]
        if not label:
            run_yabai("space", str(index), "--destroy")
            time.sleep(SPACE_MOVE_DELAY_SECONDS)
            continue
        if label not in allowed_labels:
            destroy_space_by_index(index)


def find_space_by_label(label: str) -> Optional[dict]:
    spaces = query_spaces()
    for space in spaces:
        if space.get("label") == label:
            return space
    return None


def move_space_to_display(space_index: int, display_index: int) -> None:
    try:
        run_yabai("space", str(space_index), "--display", str(display_index))
    except YabaiError as error:
        message = str(error).lower()
        if "acting space is already located on the given display" in message:
            return
        raise
    time.sleep(SPACE_MOVE_DELAY_SECONDS)


def move_windows_to_space(window_ids: Iterable[int], target_space_index: int) -> None:
    existing_windows = query_window_ids()
    for window_id in sorted(set(window_ids)):
        if window_id not in existing_windows:
            continue
        try:
            run_yabai("window", str(window_id), "--space", str(target_space_index))
        except YabaiError as error:
            if "could not locate the window to act on" in str(error):
                continue
            raise


def move_all_windows_to_temp(snapshot: Dict[str, SpaceSnapshot], temp_index: int) -> None:
    all_windows = (window for space in snapshot.values() for window in space.windows)
    move_windows_to_space(all_windows, temp_index)


# works based on assumtion what all neccessary amount of spaces are already created
# and the last space is the temp space on the secondary display if ther is two displays
# Also works only for single (does nothing) or dual setup,
# should be refactored to work with more than 2 displays
def assign_spaces_to_displays(temp_index: int, displays: List[dict]) -> None:
    if not displays:
        raise YabaiError("no displays detected")
    if len(displays) > 2:
        raise YabaiError("more than 2 displays detected, should be refactored")

    if len(displays) == 1:
        return
    
    primary = 1 # primary display is always the first one by index
    secondary = 2 # secondary display is always the second one by index

    spaces = query_spaces()
    spaces_on_primary = [space for space in spaces if space["display"] == primary]
    spaces_on_secondary = [space for space in spaces if space["display"] == secondary]
    
    if len(spaces_on_primary) < MONITOR1_SPACE_COUNT:
        amount_to_move = MONITOR1_SPACE_COUNT - len(spaces_on_primary)
        for i in range(amount_to_move):
            space = spaces_on_secondary[i]
            move_space_to_display(space["index"], primary)
    elif len(spaces_on_primary) > MONITOR1_SPACE_COUNT:
        amount_to_move = len(spaces_on_primary) - MONITOR1_SPACE_COUNT
        for i in range(amount_to_move):
            space = spaces_on_primary[-i-1]
            move_space_to_display(space["index"], secondary)
    else:
        # all good nothing to do
        return


# assumtion temp_space should be last one by index
def rename_spaces(labels: List[str]) -> None:
    spaces = query_spaces()
    spaces.sort(key=lambda space: space["index"])
    for i in range(len(labels)):
        label = labels[i]
        space = spaces[i]
        run_yabai("space", str(space["index"]), "--label", label)
    time.sleep(SPACE_MOVE_DELAY_SECONDS)


def restore_layouts(snapshot: Dict[str, SpaceSnapshot]) -> None:
    spaces = query_spaces()
    for space in spaces:
        label = space.get("label") or ""
        if not label or label == TEMP_LABEL:
            continue
        saved = snapshot.get(label)
        if not saved or not saved.layout:
            continue
        if space.get("type") == saved.layout:
            continue
        run_yabai("space", str(space["index"]), "--layout", saved.layout)


# s9 is always unmanaged
def s9_layout_manage_off() -> None:
    run_yabai("space", "s9", "--layout", "float")


def restore_windows(snapshot: Dict[str, SpaceSnapshot]) -> None:
    existing_windows = query_window_ids()
    for label, saved in snapshot.items():
        for window_id in saved.windows:
            if window_id not in existing_windows:
                continue
            try:
                run_yabai("window", str(window_id), "--space", label)
            except YabaiError as error:
                if "could not locate the window to act on" in str(error):
                    continue
                raise


def main() -> None:
    initial_spaces = query_spaces()
    snapshot = snapshot_spaces(initial_spaces)
    
    create_temp_space()

    current_spaces = query_spaces()
    current_temp_index = temp_space_index(current_spaces)
    if current_temp_index is None:
        raise YabaiError("failed to create temporary space")
    move_all_windows_to_temp(snapshot, current_temp_index)

    displays = query_displays()
    if len(displays) == 1:
        ensure_space_count(len(SINGLE_DISPLAY_LABELS) + 1)
    else: 
        ensure_space_count(len(DUAL_DISPLAY_LABELS) + 1)

    assign_spaces_to_displays(current_temp_index, displays)

    label_order = DUAL_DISPLAY_LABELS if len(displays) > 1 else SINGLE_DISPLAY_LABELS
    rename_spaces(label_order)
    
    restore_layouts(snapshot)
    restore_windows(snapshot)
    s9_layout_manage_off()
    
    destroy_temp_space()
    trim_extra_spaces(set(label_order))


if __name__ == "__main__":
    try:
        main()
    except YabaiError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)

