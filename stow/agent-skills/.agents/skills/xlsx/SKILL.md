---
name: xlsx
description: Work with Excel workbooks (.xlsx and .xlsm) — explore unknown workbooks, read headers/data, export sheets or ranges to CSV, edit cell/column values, and write robust ad hoc parsing/generation scripts. Use whenever the task involves an Excel/xlsx/xlsm file, spreadsheet, workbook, or timesheet/report parsing.
---

# XLSX skill

Ready-made scripts for common Excel operations + a field-tested best-practices
reference for writing ad hoc Excel code.

## Setup (once per machine)

Dependencies are managed exclusively by Poetry. If they are not installed yet, install them from the scripts environment (replace `<skill-dir>` with this skill's absolute path):

```bash
poetry -C <skill-dir>/scripts install
```

Do not substitute `pip`, `uv`, or another package manager.

## Core rule

**Never write a parser before looking inside the file.** Excel files from
external sources are semi-structured text: the header may not be row 1, the
needed sheet may not be first, numbers may be strings with `\xa0` and comma
decimals. Always probe first.

## Scripts

Run from anywhere through Poetry. Set `<skill-dir>` to this skill's absolute path:

```bash
poetry -C <skill-dir>/scripts run python <skill-dir>/scripts/<script> <absolute-path-to-workbook>
```

`poetry -C` executes from the scripts environment; use absolute paths for the
script and target workbook.

### 1. `scripts/xlsx_probe.py` — explore an unknown workbook (ALWAYS do this first)

Prints every sheet's dimensions and first N rows as `repr:type` pairs, so dirty
values ('1 234,5' as str) and header locations are immediately visible.

```bash
... xlsx_probe.py file.xlsx                    # all sheets, 15 rows each
... xlsx_probe.py file.xlsx --sheet "табель" --rows 30 --cols 8
```

`--sheet` accepts an exact name, a 0-based index, or a name substring (all scripts do).

### 2. `scripts/xlsx_to_csv.py` — export a sheet or range to CSV

Stdout by default (pipe/preview friendly); `--range` cuts off meta rows above
the header or extracts just the needed block.

```bash
... xlsx_to_csv.py file.xlsx                          # first sheet, everything
... xlsx_to_csv.py file.xlsx --sheet 2 --range A3:H200 --out data.csv
... xlsx_to_csv.py file.xlsx --range B4               # from B4 to the end of sheet
```

### 3. `scripts/xlsx_set.py` — edit values in place (formulas and VBA in `.xlsm` preserved)

```bash
... xlsx_set.py file.xlsx --cell B5=42 --cell C1="Total"
... xlsx_set.py file.xlsx --col "часов" --where "1 234,5" --set 1234.5 --dry-run
```

Column mode finds the column by header substring in `--header-row` (default 1)
and replaces every cell whose trimmed text equals `--where`. For `.xlsm`, the
script loads with `keep_vba=True` to preserve the VBA project. Always offer
`--dry-run` first when the file is precious.

## Ad hoc scripts

When the task goes beyond these scripts (parsing dirty files into a contract,
multi-file aggregation, generating styled reports, header hunting, column
detection by synonyms/content), **read `references/xlsx_best_practices.md`
before writing code**. It covers library choice, tolerant parsing patterns,
value normalization (nbsp/comma-decimal numbers, timedelta hours, date shapes),
openpyxl generation/editing recipes, CLI conventions, testing with generated
fixtures, and anti-patterns.

Non-negotiables from that reference:

- `data_only=True` to read computed values — but **never save** a workbook
  loaded that way (formulas are lost permanently); edit with `data_only=False`.
- A broken row may fail; a whole file may not — log row numbers, continue.
- Numbers are written as float/int + `number_format`, never pre-formatted strings.
- Don't hardcode column indexes without name-based detection or a logged fallback.
- Silently dropping unmatched names is forbidden — collect and report them.
