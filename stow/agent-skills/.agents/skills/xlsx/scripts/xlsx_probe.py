#!/usr/bin/env python3
"""Probe an unknown workbook BEFORE writing any parser.

Prints, for every sheet (or one via --sheet): dimensions and the first N rows
as ``repr:type`` pairs — so '1 234,5' (str) and 1234.5 (float) are
distinguishable, header rows and garbage rows are visible.

Usage:
    poetry run python scripts/xlsx_probe.py file.xlsx
    poetry run python scripts/xlsx_probe.py file.xlsx --sheet "Табель" --rows 30
"""

import argparse
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    sys.exit("openpyxl is required: run `poetry install` in the skill directory")


def resolve_sheet(sheetnames: list[str], selector: str) -> str:
    """Resolve --sheet given as exact name, 0-based index, or name substring."""
    if selector in sheetnames:
        return selector
    if selector.isdigit() and int(selector) < len(sheetnames):
        return sheetnames[int(selector)]
    matches = [n for n in sheetnames if selector.lower() in n.lower()]
    if len(matches) == 1:
        return matches[0]
    sys.exit(f"Sheet {selector!r} not found (or ambiguous). Sheets: {sheetnames}")


def probe_sheet(ws, rows: int, cols: int) -> None:
    print(f"=== {ws.title!r}: {ws.max_row} rows x {ws.max_column} cols")
    for i, row in enumerate(ws.iter_rows(max_row=rows, values_only=True), 1):
        cells = [f"{v!r}:{type(v).__name__}" for v in row[:cols]]
        truncated = " …" if len(row) > cols else ""
        print(f"{i:>3} {cells}{truncated}")
    print()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("path", type=Path, help=".xlsx or .xlsm file to probe")
    ap.add_argument("--sheet", help="sheet name, 0-based index, or name substring (default: all sheets)")
    ap.add_argument("--rows", type=int, default=15, help="rows to show per sheet (default 15)")
    ap.add_argument("--cols", type=int, default=12, help="max columns to show per row (default 12)")
    args = ap.parse_args()

    if not args.path.exists():
        sys.exit(f"File not found: {args.path}")

    # data_only=True: computed formula values, not formula strings; read_only streams big files
    wb = openpyxl.load_workbook(args.path, data_only=True, read_only=True)
    print(f"Workbook: {args.path.name} | sheets: {wb.sheetnames}\n")

    if args.sheet is not None:
        names = [resolve_sheet(wb.sheetnames, args.sheet)]
    else:
        names = wb.sheetnames
    for name in names:
        probe_sheet(wb[name], args.rows, args.cols)
    wb.close()


if __name__ == "__main__":
    main()
