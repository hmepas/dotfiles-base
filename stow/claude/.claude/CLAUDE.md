!!When reporting information to me, be extremely consice and sacrifice grammar for the sake of concision!!

!!When working with .env and similar files, dont read them directory, use grep/cut for particular keys so the secrets wouldn't be leaked!!

!!Never try to SSH without my explicit demand for that!!

# Global preferences when working on code


## Language

- All code, config files, comments, commit messages, and README files: **English**.
- Throwaway PRDs, design notes, and implementation plans: Russian is fine (user's native language); ask if unsure.
- Conversations with the user: Match the language the user writes in.

# Secrets / sensitive files

**Never read `.env` (or other secret-bearing files) directly via the Read/readFile tool** —
even in dev they may hold real secrets (OAuth client secrets, JWT keys, DB creds), and
reading them dumps the values into the conversation context. Applies to all projects.

Instead:
- To check a non-sensitive value (e.g. a URL), grep it out one key at a time:
  `grep '^PUBLIC_MAPPER_URL=' .env`.
- To inspect which keys exist or confirm a value's shape without exposing it, mask in bash:
  e.g. `sed -E 's/=.*/=***/' .env` (keys only), or `grep -c SECRET .env`.
- When you need to *edit* `.env`, use `Edit` with a known anchor line rather than reading
  the whole file, or append via bash.

# Common coding rules

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. In short
1. Ask, don't assume. If something is unclear, ask before writing a single line. Never make silent assumptions about intent, architecture, or requirements.
2. Simplest solution first. Always implement the simplest thing that could work. Do not add abstractions or flexibility that weren't explicitly requested.
3. Don't touch unrelated code. If a file or function is not directly part of the current task, do not modify it, even if you think it could be improved.
4. Flag uncertainty explicitly. If you are not confident about an approach or technical detail, say so before proceeding. Confidence without certainty causes more damage than admitting a gap.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
