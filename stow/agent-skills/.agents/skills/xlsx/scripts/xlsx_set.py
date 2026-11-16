#!/usr/bin/env python3
"""Edit cell values in an existing workbook, preserving formulas.

Two modes:
  cell mode:    --cell B5="new value" (repeatable) — set cells by address;
  column mode:  --col "Hours" --where "8,5" --set 8.5 — find the column by
                header (case-insensitive substring match in --header-row),
                replace every matching value below it.

Loads with data_only=False so existing formulas survive the save (a workbook
loaded with data_only=True would lose them permanently on save). Values
starting with '=' are written as formulas. Use --dry-run to preview.

Usage:
    poetry run python scripts/xlsx_set.py file.xlsx --cell B5=42 --cell C1="Total"
    poetry run python scripts/xlsx_set.py file.xlsx --sheet "Табель" \\
        --col "часов" --where "1 234,5" --set 1234.5 --dry-run
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


def coerce(raw: str, forced: str):
    """'auto': int -> float -> str; strings starting with '=' become formulas."""
    if forced == "str":
        return raw
    if forced in ("int", "float"):
        return int(raw) if forced == "int" else float(raw)
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return raw


def find_column(ws, header_row: int, needle: str) -> int:
    matches = []
    for cell in ws[header_row]:
        if cell.value is not None and needle.lower() in str(cell.value).strip().lower():
            matches.append((cell.column, str(cell.value)))
    if not matches:
        headers = [str(c.value) for c in ws[header_row] if c.value is not None]
        sys.exit(f"No header matching {needle!r} in row {header_row}. Headers: {headers}")
    if len(matches) > 1:
        sys.exit(f"Ambiguous header {needle!r}, matches: {matches}. Be more specific.")
    print(f"📌 column {matches[0][0]} ({matches[0][1]!r})", file=sys.stderr)
    return matches[0][0]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("path", type=Path, help=".xlsx or .xlsm file to edit (in place)")
    ap.add_argument("--sheet", help="sheet name, 0-based index, or name substring (default: first sheet)")
    ap.add_argument("--cell", action="append", default=[], metavar="ADDR=VALUE",
                    help="cell assignment like B5=42; repeatable")
    ap.add_argument("--col", help="column mode: header text to locate the column")
    ap.add_argument("--where", help="column mode: current value to match (compared as trimmed text)")
    ap.add_argument("--set", dest="new_value", help="column mode: replacement value")
    ap.add_argument("--header-row", type=int, default=1, help="row with headers for --col (default 1)")
    ap.add_argument("--type", choices=["auto", "str", "int", "float"], default="auto",
                    help="type for written values (default: auto — int, then float, then str)")
    ap.add_argument("--dry-run", action="store_true", help="print planned changes, do not save")
    args = ap.parse_args()

    col_mode = args.col is not None
    if col_mode and (args.where is None or args.new_value is None):
        ap.error("--col requires --where and --set")
    if not col_mode and not args.cell:
        ap.error("nothing to do: pass --cell ADDR=VALUE and/or --col/--where/--set")

    if not args.path.exists():
        sys.exit(f"File not found: {args.path}")

    # data_only=False keeps formulas; keep_vba preserves the VBA project in .xlsm files.
    wb = openpyxl.load_workbook(args.path, keep_vba=args.path.suffix.lower() == ".xlsm")
    name = resolve_sheet(wb.sheetnames, args.sheet) if args.sheet else wb.sheetnames[0]
    ws = wb[name]
    changes = 0
    column_changes = 0

    for spec in args.cell:
        addr, sep, raw = spec.partition("=")
        if not sep:
            sys.exit(f"Bad --cell spec {spec!r}, expected ADDR=VALUE")
        value = coerce(raw, args.type)
        print(f"  {name}!{addr}: {ws[addr].value!r} -> {value!r}", file=sys.stderr)
        ws[addr] = value
        changes += 1

    if col_mode:
        col_idx = find_column(ws, args.header_row, args.col)
        value = coerce(args.new_value, args.type)
        for row in ws.iter_rows(min_row=args.header_row + 1, min_col=col_idx, max_col=col_idx):
            cell = row[0]
            if cell.value is not None and str(cell.value).strip() == args.where.strip():
                print(f"  {name}!{cell.coordinate}: {cell.value!r} -> {value!r}", file=sys.stderr)
                cell.value = value
                changes += 1
                column_changes += 1
        if column_changes == 0:
            print(f"⚠️  no cells matched --where {args.where!r}", file=sys.stderr)

    if args.dry_run:
        print(f"🔍 dry-run: {changes} change(s), file NOT saved", file=sys.stderr)
    elif changes:
        wb.save(args.path)
        print(f"✅ saved {args.path} ({changes} change(s))", file=sys.stderr)
    else:
        print("nothing changed, file not written", file=sys.stderr)
    if wb.vba_archive is not None:
        wb.vba_archive.close()
    wb.close()


if __name__ == "__main__":
    main()
