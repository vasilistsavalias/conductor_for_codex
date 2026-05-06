---
name: conductor-status
description: Displays the current progress of all tracks in the project
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

CRITICAL: Conductor artifacts are **local-only**. This command is read-only — it does not modify any files.

---

## 1.0 SYSTEM DIRECTIVE

You are an autonomous AI agent providing a status overview of the Conductor project. Read the tracks registry and all plan files, then output a structured summary. Do not modify any files. Do not stop for user confirmation.

---

## 1.1 SETUP CHECK

**Universal File Resolution Protocol:** Check `conductor/<file>` first; if missing, read `conductor/index.md` for canonical paths.

Check for:
- `conductor/tracks.md` (Tracks Registry)
- `conductor/product.md`
- `conductor/tech-stack.md`
- `conductor/workflow.md`

If any required file is missing: output a warning listing the missing files and suggest "Run `/conductor-setup` to initialize.", then continue with whatever data is available (do not halt completely — partial status is better than nothing).

---

## 2.0 STATUS OVERVIEW PROTOCOL

### 2.1 Read the Tracks Registry

1. Read `conductor/tracks.md`.
2. Parse all track sections. A track section is delimited by `---`. For each section, extract:
   - Status: `[ ]` (new), `[~]` (in_progress), `[x]` (implemented — pending review)
   - Track description (from `**Track: ...**` line)
   - Track folder link

3. For each track, read its `plan.md` via the track's `index.md`. Parse tasks:
   - Count total tasks: lines matching `- [ ] Task:`, `- [~] Task:`, `- [x] Task:`
   - Count completed tasks: `- [x] Task:`
   - Identify current in-progress task: `- [~] Task:` (if any)
   - Identify next pending task: first `- [ ] Task:` (if any)
   - Identify blockers: tasks or lines explicitly labeled "BLOCKED" or "BLOCKER"

### 2.2 Generate and Output Status Report

Output the following format:

```
═══════════════════════════════════════
  CONDUCTOR STATUS REPORT
  <current date and time>
═══════════════════════════════════════

PROJECT: <product name from conductor/product.md>

TRACKS SUMMARY
  Total tracks:       <N>
  New (not started):  <N>
  In progress:        <N>
  Implemented:        <N>  ← pending review
  Archived:           (not tracked here — check conductor/archive/)

─────────────────────────────────────
<For each track, in registry order:>

[<status icon>] Track: <description>
    ID:       <track_id>
    Progress: <completed>/<total> tasks (<percent>%)
    Current:  <current in-progress task, or "—">
    Next:     <next pending task, or "All done — run /conductor-review">
    Blockers: <blocker text, or "None">

─────────────────────────────────────
OVERALL PROGRESS: <total_completed>/<total_tasks> tasks (<percent>%)
STATUS: <On Track | In Progress | Blocked | All Implemented>
═══════════════════════════════════════
```

Status icons:
- `[ ]` new
- `[~]` in progress
- `[x]` implemented (review pending)

Overall STATUS:
- "Blocked" if any blocker exists
- "All Implemented" if all tracks are `[x]` or archived
- "In Progress" if any track is `[~]`
- "On Track" if all tracks are `[ ]` (not yet started)
