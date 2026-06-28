# PROBLEMS — Active Issue Tracker

> **For all coding agents (Kilo Code, Claude Code, Grok Build):**
> Log any blocker, build error, unresolved design question, or bug here as you encounter it.
> Keep status accurate — do NOT mark something "in-progress" unless you are working on it *right now*.
> Update this file at the START and END of every work session.
> Claude Code uses this file to review issues and plan fixes across sessions.

---

## Status Legend

- `pending` — found but not yet addressed
- `in-progress` — actively being worked on this session
- `solved` — fixed, check it off

---

## Active Problems

*(none logged yet — add entries here as you encounter them)*

<!--
Template for a new entry — copy/paste and fill in:

- [ ] **Short title** — one-line description of the problem
  - **Discovered:** Phase 6B / 2026-06-27
  - **Status:** `pending`
  - **Context:** What triggered this? What was being built when it appeared?
  - **What was tried:** (fill in attempts made)
  - **Suspected fix:** (your best guess at a solution, or "unknown")
-->

---

## Solved Problems

*(move entries here — with checkmark — once resolved)*

<!--
Template for a solved entry:

- [x] **Short title**
  - **Discovered:** Phase X / date
  - **Solved:** date
  - **How:** one-line explanation of what fixed it
-->

---

## Rules for Agents

1. **Log immediately** — the moment you hit a blocker or unexpected behavior, add it here before continuing or abandoning the task.
2. **One entry per distinct problem** — don't bundle multiple issues into one entry.
3. **Status must be honest:**
   - Set `in-progress` only while actively working on that problem.
   - If you stop working on it (session ends, you move to something else), revert to `pending`.
   - If solved, move the entry to "Solved Problems" and check the box.
4. **Don't delete entries** — even if unsolved and abandoned. They may be relevant to future sessions.
5. **Don't modify AlgorithmDatabase.swift** to work around problems — fix the actual issue.
6. **Claude Code checks this file** to provide reasoning or plans for hard problems. Keep notes detailed enough that it can understand the context without reading all your code.
