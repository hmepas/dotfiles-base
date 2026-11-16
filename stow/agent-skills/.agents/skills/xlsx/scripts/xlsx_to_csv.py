#!/usr/bin/env python3
"""Export a sheet (or a range of it) to CSV.

Handles the "header is not row 1" reality: --range lets you cut off meta rows,
totals above the header, or export just the block you need. Writes to stdout
by default so output can be piped, previewed, or redirected.

Usage:
    poetry run python scripts/xlsx_to_csv.py file.xlsx                          # first sheet, all data
    poetry run python scripts/xlsx_to_csv.py file.xlsx --sheet "Табель"
    poetry run python scripts/xlsx_to_csv.py file.xlsx --sheet 2 --range A3:H200
    poetry run python scripts/xlsx_to_csv.py file.xlsx --range B4 --out data.csv  # from B4 to the end
"""

import argparse
import csv
import datetime
import sys
from pathlib import Path

try:
    import openpyxl
    from openpyxl.utils.cell import coordinate_from_string, column_index_from_string, range_boundaries
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


def parse_range(spec: str, ws) -> tuple[int, int, int, int]:
    """'A3:H200' -> bounds; 'B4' -> from B4 to the sheet's end."""
    if ":" in spec:
        min_col, min_row, max_col, max_row = range_boundaries(spec)
        return min_row, max_row, min_col, max_col
    col_letter, row = coordinate_from_string(spec)
    return row, ws.max_row, column_index_from_string(col_letter), ws.max_column


def format_cell(v) -> str:
    if v is None:
        return ""
    if isinstance(v, datetime.datetime):
        # a date cell comes back as datetime with midnight time — print it as a date
        return v.date().isoformat() if v.time() == datetime.time.min else v.isoformat(sep=" ")
    if isinstance(v, datetime.date):
        return v.isoformat()
    return str(v)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("path", type=Path, help=".xlsx or .xlsm file to export")
    ap.add_argument("--sheet", help="sheet name, 0-based index, or name substring (default: first sheet)")
    ap.add_argument("--range", dest="range_spec",
                    help="A1-range 'A3:H200', or a single start cell 'B4' (to the end of the sheet)")
    ap.add_argument("--out", type=Path, help="output CSV path (default: stdout)")
    ap.add_argument("--delimiter", default=",", help="CSV delimiter (default ',')")
    args = ap.parse_args()

    if not args.path.exists():
        sys.exit(f"File not found: {args.path}")

    wb = openpyxl.load_workbook(args.path, data_only=True, read_only=True)
    name = resolve_sheet(wb.sheetnames, args.sheet) if args.sheet else wb.sheetnames[0]
    ws = wb[name]

    if args.range_spec:
        min_row, max_row, min_col, max_col = parse_range(args.range_spec, ws)
    else:
        min_row, max_row, min_col, max_col = 1, ws.max_row, 1, ws.max_column

    out = open(args.out, "w", newline="", encoding="utf-8") if args.out else sys.stdout
    writer = csv.writer(out, delimiter=args.delimiter)
    n = 0
    for row in ws.iter_rows(min_row=min_row, max_row=max_row,
                            min_col=min_col, max_col=max_col, values_only=True):
        writer.writerow([format_cell(v) for v in row])
        n += 1
    if args.out:
        out.close()
        print(f"✅ {name!r}: {n} rows -> {args.out}", file=sys.stderr)
    else:
        print(f"✅ {name!r}: {n} rows", file=sys.stderr)
    wb.close()


if __name__ == "__main__":
    main()
