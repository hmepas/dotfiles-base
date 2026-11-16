---
name: zk
description: "Drop a record into Pavel's Obsidian vault (zk) from OUTSIDE it — a task to Tasks Inbox, a note to Notes/, a DAR line, a metric reading — or look something up there. Use when the user says «запиши/закинь/откинь в zk», «в vault», «в инбокс», «в заметки», «в DAR», or asks what the vault knows about X while working in another project. NOT for sessions started inside the vault: there its own CLAUDE.md/AGENTS.md and .agents/skills apply."
---

# zk — write to / read from the vault from another project

Vault: `~/zk`, personal knowledge base + daily logs of Pavel (hmepas). Use this directory on Mac and Linux; it may be a symlink to the actual vault. Below `$ZK` = that path. Talk to the user in Russian.

## 0. Guard

If `$PWD` is inside `$ZK` — stop, this skill does not apply. There the vault's `CLAUDE.md`/`AGENTS.md` and `.agents/skills/*` are the source of truth (more precise than this file).

## 1. Orient first (always, ~1s)

```bash
ZK="$HOME/zk"
python3 "$ZK/.agents/skills/zk-index/zk_scan.py" all
```

Writes `$ZK/.zk/`: `index.tsv` (page, mtime, tags, outgoing links), `backlinks.txt` (link/tag usage counts, most used first), `recent.txt` (recently edited pages). Grep these instead of reading files:

- which tags/links already exist for a topic: `grep -i 'x' "$ZK/.zk/backlinks.txt"`
- related notes: `grep -i 'topic' "$ZK/.zk/index.tsv" | cut -f1`

If the record is a task — also `python3 "$ZK/.agents/skills/zk-tasks/zk_tasks.py" open` (open tasks with age; duplicates, context).
Full conventions when something is unclear: `$ZK/AGENTS.md` (its relative paths are relative to `$ZK`).

## 2. Where the record goes

**Task** → `$ZK/Tasks Inbox.md`, insert right after the `---` line (newest on top). Obsidian Tasks format:

```
- [ ] <текст> ➕ YYYY-MM-DD
- [ ] <текст> ➕ YYYY-MM-DD 📅 YYYY-MM-DD                      deadline
- [ ] <текст> ➕ YYYY-MM-DD 🛫 YYYY-MM-DD                      sleeps until that date
- [ ] #делегировал [[кто]]: <что> ➕ YYYY-MM-DD 🛫 YYYY-MM-DD    someone else does it; 🛫 = when to ask
- [ ] #слежу <что, от кого зависит, условие тревоги> ➕ … 🛫 …   watch only; 🛫 = when to check
```

Check duplicates first (`grep -i` the inbox + `zk_tasks.py open`). Monthly recurring duty → a rule line in `$ZK/Recurring.md` (format in its header), not a task.

**Note** → `$ZK/Notes/<Заголовок>.md` (filename = H1, Russian is fine). Header:

```
YYYYMMDDHHMM
Status: #note
Tags: [[lin]] [[тег1]] [[тег2]]

# Заголовок
```

Status: `#note` default; `#insight`, `#idea`, `#meeting`, `#log` also in use. Other tags: reuse existing ones from `backlinks.txt`, don't invent in not crucial. Link related notes and people (`[[Notes/X]]`, `[[people/...]]` - lower case no separators i.e. people/johndoe). Reply with the path of the created note. A thread that keeps coming back (new rounds, new context) → one project note with dated `## YYYY-MM-DD` sections plus a single pointer task in the inbox, not a chain of tasks.

**Addition to an existing note of Pavel's** → never edit in place; append a section `## Дополнение (агент, YYYY-MM-DD)`.

**DAR line** (daily log, `$ZK/SelfTracking/1.Daily Notes/DAR 2026 WB and my own projects.md`) → only when explicitly asked («в DAR», «в лог дня»). Days are `## YYYY-MM-DD` headers, newest right under the H1; create today's if missing. Line = `- [[категория]] текст`. Categories: `работа` (WB Bank), `дело` (own projects/business), `красноглазие` (coding, tinkering), `здоровье`, `быт`, `семья`, `радость`, `финансы`, `мысль дня`. Keep the user's wording, don't touch other lines, ask if the category is unclear.

**Metric reading** (meters, odometer, any number series) → note with one `## <серия>` section per series, entries `- YYYY-MM-DD: value`, newest last. Example: `$ZK/Notes/Показания счётчиков.md`. JFYI only, there is dedicated agent to write there, don't write unless explicitly asked to.

**Lookup** → grep `index.tsv`/`backlinks.txt`, then read the specific page. `Notes/` main notes, `people/` and `company/` cards, `0. Projects/` projects, `Syllabus/` learning, `ZZ. Archive/` old.

## 3. Rules

- One record = one edit. Don't restructure files, don't create templates/frameworks.
- Direct tone, no praise, no emoji except Tasks markers.
- Never write into Yandex.Disk conflict copies (`… (2).md`).
- Dates/timestamps in the host's local time.
- use unslop skill and be consice.
