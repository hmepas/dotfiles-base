# Working with Excel (XLSX/XLSM) in Python — field-tested practices

> Distilled from a real project that lived and died by Excel: dozens of structurally different
> timesheets, invoices, AD exports and budget files from external parties, plus heavy report
> generation. Project-agnostic; written to be turned into an agent skill.
> Covers four capabilities: **explore**, **read**, **generate**, **edit**.

## 0. Mental model

Excel files from external sources are **not data — they are semi-structured text**:

- the same field is named differently across files ("ФИО", "Полное имя", "Исполнитель", "Full Name");
- the sheet you need has a different name in every file and is not always first;
- the header is not always row 1 (meta rows / totals above it);
- numbers arrive as strings with thousands separators, non-breaking spaces (`\xa0`), comma decimals;
- dates arrive as `datetime`, `Timestamp`, string, or Excel serial number;
- hours/durations may be a number **or** a `timedelta` (`0 days 01:30:00`);
- values carry garbage: `[X]` markers, URLs instead of IDs, duplicate columns under one header.

Never rely on fixed column indexes or row numbers without a fallback. Build a tolerant parsing
layer that converts input into a **strict internal contract**, and only then do business logic.

## 1. Library choice (as of 2026)

| Library | Role |
|---|---|
| `pandas` (2.x) | tabular parsing of sheets, vectorized cleanup, aggregation |
| `openpyxl` (3.1+) | cell-level access to `.xlsx` / `.xlsm`: header hunting, `iter_rows`, **all writing and editing** |

Rules of thumb:

- **`pd.read_excel` / `pd.ExcelFile`** — when the sheet has a sane header and tabular data.
- **`openpyxl.load_workbook(path, data_only=True)`** — when you must hunt for the header row,
  read irregular layouts ("total in row 2, data from row 3"), or inspect formatting.
  `data_only=True` returns **computed formula values** instead of formula strings.
- **`openpyxl` is the only writer/editor** in this stack. `read_only=True` streams huge files;
  `write_only=True` streams huge outputs.
- Make `openpyxl` import optional in CLI tools where Excel output is optional:

```python
try:
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    from openpyxl.utils import get_column_letter
    EXCEL_AVAILABLE = True
except ImportError:
    EXCEL_AVAILABLE = False
# ...and fail with a clear "pip install openpyxl" message only when xlsx is requested.
```

## 2. Exploring an unknown workbook (do this FIRST)

Before writing any parser, look at the file. A 20-line probe saves hours of blind parsing:

```python
import openpyxl

wb = openpyxl.load_workbook(path, data_only=True, read_only=True)
for name in wb.sheetnames:
    ws = wb[name]
    print(f"=== {name!r}: {ws.max_row} rows x {ws.max_column} cols")
    for i, row in enumerate(ws.iter_rows(max_row=15, values_only=True), 1):
        print(i, [f"{v!r}:{type(v).__name__}" for v in row][:12])
```

What to look for:

- **which sheet** holds the data, and whether extra sheets hold complementary data
  (e.g. a second "Табель" sheet supplementing the main worklog);
- **where the header row is** and whether headers are duplicated/ambiguous;
- **value types per column**: `str` where you expected `float` means dirty numbers;
  `datetime` vs `str` dates; `timedelta` hours;
- merged cells, total rows, `[X]`-style markers, URLs in ID columns.

Print `repr` + type, not just the value — `'1 234,5'` and `1234.5` look identical printed plainly.
For quick pandas-level probing: `pd.read_excel(path, sheet_name=None, header=None, nrows=15)`
returns a `{sheet_name: DataFrame}` dict of raw top rows for every sheet at once.

## 3. Reading dirty files: contract + swappable loaders

Separate "how to read this particular format" from "what to do with the data":

```
File ──► Loader (format-specific) ──► Domain model (strict contract) ──► validation / DB / report
```

- **Contract** — one schema per record (Pydantic / dataclass / TypedDict) with guaranteed types
  (e.g. `name: str, date: date, hours: Decimal, ...`) plus a container. Everything a loader
  returns is the contract; downstream code never knows the source format.
- **Base loader class** defines the interface: `load(path, **context) -> Contract`,
  `get_supported_extensions()`, and a `description` string for a self-documenting registry.
- **Loader registry** keyed by name, selected via CLI `--loader`; `--list-loaders` prints
  descriptions. A `default` loader uses the widest synonym sets; specialized loaders inherit or
  **delegate**: try their own parse first, fall back to `default`, then enrich (e.g. merge a
  second sheet).

Why: a new source format = one new small loader, open/closed. A loader is a pure function
"file path → contract" — trivially testable without DB or network.

### 3.1 Finding the right sheet

Priority names → keyword search → fallback to first sheet (log that fallback fired):

```python
def find_main_sheet(xls: pd.ExcelFile) -> str:
    priority = ["Записи о работе", "Таймшит", "тш", "табель"]      # exact, per-domain
    for name in priority:
        if name in xls.sheet_names:
            return name
    keywords = ["записи", "табель", "отчет", "timesheet", "report"]  # fuzzy
    for name in xls.sheet_names:
        if any(k in name.lower() for k in keywords):
            return name
    return xls.sheet_names[0]                                        # last resort — log it!
```

### 3.2 Finding the header row (when it's not row 1)

Scan the first ~10 rows; the header is the row containing an expected keyword:

```python
for row_idx, row in enumerate(ws.iter_rows(min_row=1, max_row=10, values_only=True), start=1):
    vals = [str(c).strip().lower() if c else "" for c in row]
    if any("актив" in v or "status" in v for v in vals):
        header_row, headers = row_idx, vals
        break
# data starts at header_row + 1
```

pandas equivalent: read with `header=None`, locate the header row, re-read with
`skiprows=header_row - 1`.

### 3.3 Detecting columns (the most important part)

**By header synonyms.** Map semantic fields to synonym sets (all languages you encounter),
lowercase substring match. Fill each field **only once** (`if 'employee' not in mapping`) so the
first match isn't overwritten by a later column:

```python
SYNONYMS = {
    "employee": ["полное имя", "фио", "исполнитель", "full name", "фамилия имя"],
    "hours":    ["час", "hours", "затрачен", "продолжитель", "time spent", "отработано"],
    "ticket":   ["ключ задачи", "issue key", "ticket", "ключ"],
    "date":     ["дата работы", "work date", "started", "дата"],
    "comment":  ["описание работы", "комментар", "comment", "description"],
}
```

Order synonyms from specific to generic ("дата работы" before "дата"), and order the
`elif` chain so generic patterns can't shadow specific fields.

**Positional fallback.** If the minimally required set wasn't found by name and the column count
matches a known format, apply known positions:

```python
need = {"employee", "hours", "ticket", "date"}
if len(need & set(mapping)) < len(need) and len(df.columns) >= 8:
    mapping = {"employee": 0, "ticket": 2, "comment": 3, "date": 6, "hours": 7}
```

**Content heuristics for ambiguity.** Real case: two columns both headed "Имя пользователя" —
one holds logins (`aa.ilin`), the other full names. Decide by sampling data:

```python
def score_fullname(df, col_idx, sample=50):
    cnt = 0
    for v in df.iloc[:sample, col_idx]:
        s = str(v or "")
        if any("а" <= ch.lower() <= "я" for ch in s) and (" " in s or "\xa0" in s):
            cnt += 1
    return cnt   # pick the candidate column with the max score
```

**Principle: when headers are ambiguous, decide by sampled content, not by header text.**

### 3.4 Normalizing values

Most "wrong numbers" bugs are dirty values, not parsing logic. Clean centrally.

Numbers (thousands separators, `\xa0`, comma decimal):

```python
def parse_number(value) -> float:
    if value is None:
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    s = str(value).strip().replace(" ", "").replace("\xa0", "")
    if s.count(",") > 0 and s.count(".") == 0:       # "1234,56" -> "1234.56"
        s = s.replace(",", ".")
    try:
        return float(s)
    except Exception:
        return 0.0
```

Vectorized for a pandas column:

```python
def to_num(s: pd.Series) -> pd.Series:
    return pd.to_numeric(
        s.astype(str).str.replace(" ", "").str.replace("\u00A0", "").str.replace(",", "."),
        errors="coerce",       # broken -> NaN, never raise
    )
```

For money, finalize as `Decimal(str(float(x)))` — don't carry float error into sums/rates.

Dates (multiple input types):

```python
if isinstance(v, (pd.Timestamp, datetime)):
    d = v.date()
elif isinstance(v, str):
    try:
        d = pd.to_datetime(v).date()
    except Exception:
        return None            # not a date — skip the row
else:
    return None
```

Hours as duration (`timedelta` / `Timedelta` / string `'0 days 01:30:00'`):

```python
def to_hours(v) -> float:
    if pd.isna(v):
        return 0.0
    if isinstance(v, (pd.Timedelta, datetime.timedelta)):
        return v.total_seconds() / 3600.0
    try:
        return pd.to_timedelta(str(v)).total_seconds() / 3600.0
    except Exception:
        return 0.0
```

Text (nbsp, markers, extracting IDs from garbage):

```python
name = re.sub(r"\s*\[X\]\s*", "", name)      # "[X]" = terminated-employee marker
name = name.replace("\xa0", " ")
name = re.sub(r"\s+", " ", name).strip()

m = re.search(r"[A-Z]+[A-Z0-9]*-\d+", ticket)  # first PROJECT-123 out of a URL / free text
ticket = m.group() if m else ticket
```

### 3.5 Skipping rows and isolating failures

Recognize empty/service rows — `NaN`, string `"nan"`/`"null"`/`""`, non-positive quantities,
"Итого"/"Total" rows:

```python
if (pd.isna(name) or str(name).lower() in {"nan", "", "null"}
        or pd.isna(hours) or hours <= 0
        or pd.isna(date)):
    return None
```

A broken row must never kill the whole file:

```python
for idx, row in df.iterrows():
    try:
        entry = parse_row(row, mapping)
        if entry:
            entries.append(entry)
    except Exception as e:
        print(f"Row {idx}: {e}")   # log with the ROW NUMBER, continue
        continue
```

**Principle: parsing a row may fail; parsing a file may not.**

### 3.6 Provenance and operator visibility

- Keep the **source row number** and the **raw source values** alongside each parsed record —
  every downstream "why is this number wrong?" question ends with looking at the source row.
- Map external names to canonical ones via an explicit dict (`EXCEL_TO_DB_*`). **Collect
  unmatched names and print them as a list at the end** — never drop them silently; the list is
  exactly what the operator must add to the mapping.
- When importing to a DB, store provenance columns (`source_name`, `sheet_name`) and make the
  import idempotent (upsert on a natural key) so re-running a corrected file is safe.

### 3.7 Multi-file aggregation

Several files, each possibly in its own sub-format: detect the format per file
(`detect_format(df)` returning a column mapping or `None`), normalize each into a common
DataFrame shape, `pd.concat`, then aggregate. Derive missing measures when possible
(no amount but rate×hours present → compute it, and vice versa).

## 4. Generating Excel

Write via `openpyxl.Workbook()`. The recurring skeleton:

```python
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Report"                     # sheet names: max 31 chars, no []:*?/\

header_font = Font(bold=True, color="FFFFFF")
header_fill = PatternFill(start_color="244062", end_color="244062", fill_type="solid")
right = Alignment(horizontal="right")

for col, text in enumerate(headers, 1):
    c = ws.cell(row=1, column=col, value=text)
    c.font, c.fill = header_font, header_fill
    c.alignment = Alignment(horizontal="center")

for r, rec in enumerate(records, start=2):
    ws.cell(row=r, column=1, value=rec.name)                 # text as str
    c = ws.cell(row=r, column=2, value=float(rec.amount))    # numbers as float…
    c.number_format = "#,##0.00"                             # …formatted via number_format
    c.alignment = right

out_path.parent.mkdir(parents=True, exist_ok=True)
wb.save(out_path)
```

Key rules:

- **Numbers go in as `float` (or `int`), never as pre-formatted strings.** Presentation is
  `cell.number_format` (`"#,##0.00"` for money/hours). Cast `Decimal` to `float` at the cell
  boundary — openpyxl accepts only str/int/float/bool/datetime/None.
- **Totals rows**: bold font + light fill (`PatternFill("solid", start_color="D9E1F2")`),
  computed in Python (values), or as formulas if the user will edit the file.
- **Auto column width** (openpyxl has none built in):

```python
for column in ws.columns:
    letter = get_column_letter(column[0].column)
    max_len = max((len(str(c.value)) for c in column if c.value is not None), default=0)
    ws.column_dimensions[letter].width = min(max_len + 2, 60)   # always cap the width
```

- **Group headers spanning the table**: write the title cell, style it, then
  `ws.merge_cells(f"A{r}:H{r}")`.
- **Collapsible detail rows** (master row + expandable children — great for
  "employee → their events" layouts):

```python
ws.sheet_properties.outlinePr.summaryBelow = False   # master row above the group
# for each detail row:
ws.row_dimensions[r].outlineLevel = 1                # up to 7 levels
ws.row_dimensions[r].hidden = True                   # collapsed by default
```

- **Freeze the header**: `ws.freeze_panes = "A2"`. Add `ws.auto_filter.ref = ws.dimensions`
  for filterable tables.
- **One sheet per period/category from DataFrames** — `pd.ExcelWriter` is the shortest path:

```python
with pd.ExcelWriter(out_path, engine="openpyxl") as writer:
    for key in sorted(month_to_df):
        month_to_df[key].to_excel(writer, index=False, sheet_name=key)
```

- After saving, **print a sanity preview**: row count, first N records as text, key totals.
  Cheap, and catches "empty report" / "wrong period" bugs immediately.

## 5. Editing existing files

`openpyxl.load_workbook(path)` → modify → `wb.save(path)`. Hard-won specifics:

- **Idempotent sheet replacement** — scripts get re-run; delete-then-recreate beats appending:

```python
wb = openpyxl.load_workbook(xlsx_path)
if sheet_name in wb.sheetnames:
    del wb[sheet_name]
ws = wb.create_sheet(sheet_name, index=1)   # index controls tab position
```

- **Remove the default sheet** when building a file sheet-by-sheet:
  `if "Sheet" in wb.sheetnames and len(wb.sheetnames) == 1: del wb["Sheet"]`.
- **Create-if-missing** so "append a sheet" works on the first run too:
  `if not path.exists(): openpyxl.Workbook().save(path)`.
- **The `data_only=True` trap**: a workbook loaded with `data_only=True` has formulas replaced
  by cached values — **saving it writes the values and loses the formulas permanently**.
  For editing, load with default `data_only=False`; if you need both computed values and to
  preserve formulas, load the file twice (once each way) and write only to the formula copy.
- openpyxl preserves most formatting/charts it doesn't touch, but not everything (some charts,
  images, and VBA need special handling. For `.xlsm`, load with `keep_vba=True` to preserve
  the VBA project. When editing a precious human-made file, work on a copy and diff the result.

## 6. Robust CLI conventions

- `--dry-run` (or making `--apply` opt-in): parse and print the full summary **without writing**
  anywhere. The operator verifies the parse first.
- `--list-loaders` printing each registered loader's description — self-documenting.
- Default input/output paths under `input_data/` and `output/`; timestamped default filenames
  (`report_2026-07-12.xlsx`); `output_dir.mkdir(parents=True, exist_ok=True)` before saving.
- Exit codes: `0` clean, `1` when discrepancies were found (so shell pipelines can react).
- Emoji-prefixed progress prints (`📂 reading…`, `✅ done`, `⚠️ unmatched:`) — scan-friendly logs.

## 7. Testing

- A loader is a pure function "file path → contract": test it without DB/network.
- **Generate fixture files in tests** with pandas/openpyxl into `tempfile` — no binary blobs in
  the repo, and the fixture code documents the expected format:

```python
df = pd.DataFrame({"Полное имя": ["Иванов Иван"], "Часов": [8], ...})
df.to_excel(tmp_path, index=False, sheet_name="Записи о работе")
```

- Keep small "evil" fixtures per known quirk: nbsp numbers, comma decimals, shifted header,
  duplicate columns, `timedelta` hours, `[X]` markers.
- Edge cases must yield an empty/partial result **without raising**: empty sheet, missing
  required column, broken dates.

## 8. Checklist for a new source format

1. **Probe the file** (§2): sheets, header location, value types, garbage.
2. Which sheets matter? Add names to priorities/keywords.
3. Header not in row 1? Auto-detect it (§3.2).
4. Column names? Extend synonyms; ambiguous headers → content heuristic.
5. Number/date/duration shapes? Run through the normalizers (§3.4).
6. Value garbage? Extend cleanup (regex/replace).
7. External names to map? Dict + collect-and-report unmatched.
8. Write the loader (inherit/delegate to `default` if close) + evil fixtures.
9. Run with `--dry-run`, eyeball the summary, then apply.

## 9. Anti-patterns

- ❌ Hardcoding column/row indexes with no name-based detection or fallback.
- ❌ Letting one broken row abort the whole file.
- ❌ `float(str(x))` without stripping `\xa0`/spaces/comma-decimal first.
- ❌ Assuming the needed sheet is the first one.
- ❌ Silently dropping unmatched external names — always report them.
- ❌ `load_workbook` without `data_only=True` when you need values, not formulas —
  and conversely, **saving** a `data_only=True` workbook (kills formulas).
- ❌ Writing numbers as formatted strings instead of float + `number_format`.
- ❌ Carrying float error into money — finalize in `Decimal`.
- ❌ Writing a parser before looking inside the file.
