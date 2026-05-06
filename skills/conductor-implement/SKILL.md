---
name: conductor-implement
description: Executes the tasks defined in the specified track's plan, then automatically runs the review gate
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

CRITICAL: Conductor artifacts are **local-only**.

- You MUST NOT modify anything outside the repository root.
- Ensure `.gitignore` includes `conductor/`. If missing, add it.
- You MUST NOT `git add`/`git commit` Conductor artifacts unless implementing tasks that explicitly require it.

---

## 1.0 SYSTEM DIRECTIVE

You are an autonomous AI agent executing tracks in the Conductor spec-driven development framework. Operate independently. Do not stop to ask for confirmation unless you encounter an unrecoverable error or a genuine high-impact ambiguity that cannot be resolved from available context. Announce your decisions as you make them.

If any file operation or shell command fails, halt immediately, report the specific failure, and wait for instructions.

---

## 1.1 SETUP CHECK

Verify the Conductor environment before proceeding.

1. Check for the existence of these files using the **Universal File Resolution Protocol** (see below):
   - Product Definition (`conductor/product.md`)
   - Tech Stack (`conductor/tech-stack.md`)
   - Workflow (`conductor/workflow.md`)
   - Tracks Registry (`conductor/tracks.md`)

2. **Universal File Resolution Protocol:** Resolve each file by checking in this order:
   - `conductor/<file>` (default location)
   - `conductor/index.md` → read it to find the canonical path

3. If any required file is missing: report which file is missing, announce "Conductor is not set up. Please run `/conductor-setup` first.", and halt.

---

## 2.0 TRACK SELECTION

Identify the track to implement without requiring user confirmation.

1. **Resolve Tracks Registry** using the Universal File Resolution Protocol.

2. **Parse the registry:** Split on `---` separators. For each section extract:
   - Status: `[ ]` (new), `[~]` (in_progress), `[x]` (implemented)
   - Track description (from `**Track: ...**` line)
   - Link to track folder

3. **Select track:**
   - If `$ARGUMENTS` is provided: find the first track whose description contains the argument text (case-insensitive). If no match found, report "No track matching '$ARGUMENTS' found." and list available tracks, then halt.
   - If `$ARGUMENTS` is empty: select the first track with status `[ ]` or `[~]` (resume in-progress first, then start the next new one).
   - If no eligible track found: announce "No incomplete tracks found. All tracks are implemented or the registry is empty." and halt.

4. **Announce selection:** "Implementing track: '<track_description>' (ID: <track_id>)"

5. If a `[~]` track is being resumed: announce "Resuming in-progress track." and skip the status update in step 3.1 below.

---

## 3.0 TRACK IMPLEMENTATION

### 3.1 Mark Track In Progress

Update the track's status in the Tracks Registry from `[ ]` to `[~]`:

- Find the line `- [ ] **Track: <description>**` and replace `[ ]` with `[~]`.
- Also update `metadata.json` in the track folder: set `"status": "in_progress"` and update `"updated_at"`.

### 3.2 Load Track Context

Read the following files for the selected track (use Universal File Resolution Protocol via the track's `index.md`):

- `conductor/tracks/<track_id>/spec.md` — the specification
- `conductor/tracks/<track_id>/plan.md` — the implementation plan
- `conductor/workflow.md` — the project workflow

If any of these files cannot be read, halt and report the error.

### 3.3 Activate Relevant Skills

Check `.codex/skills/` in the repository root for installed skills. List available subdirectories. Based on the track spec and plan, determine if any installed skills are relevant (e.g., a security skill for auth work). For each relevant skill, read its `SKILL.md` and apply its guidelines during implementation.

### 3.4 Execute Tasks

Iterate through every task in `plan.md` sequentially:

1. **Parse tasks:** Identify all items matching `- [ ] Task: ...` (and nested `    - [ ] ...` sub-tasks).

2. **For each task:**
   a. Announce: "Executing: <task description>"
   b. Follow the procedures in `conductor/workflow.md` precisely (TDD, commit frequency, testing requirements, etc.).
   c. After completing the task's work:
      - Run any tests specified or inferable from the codebase.
      - If tests fail: attempt to fix before marking complete. If fix is not possible within one retry, halt and report the specific failure.
   d. Update the task in `plan.md`: change `- [ ] Task: <desc>` to `- [x] Task: <desc> <git-short-sha>` using the commit SHA of the work commit.
   e. Stage `plan.md` and commit: `conductor(plan): Mark task '<task>' as complete`

3. **Workflow compliance:** The workflow file is the single source of truth for implementation, testing, and commit procedures. Follow it exactly.

4. **Halt conditions:** Only halt mid-task if:
   - A shell command fails with a non-recoverable error
   - A required file cannot be found or read
   - A test failure cannot be resolved after one retry

### 3.5 Finalize Track

After all tasks in `plan.md` are marked `[x]`:

1. Update the Tracks Registry: change `[~]` to `[x]` for this track.
2. Update `metadata.json`: set `"status": "implemented"` and update `"updated_at"`.
3. Commit: `chore(conductor): Mark track '<track_description>' as implemented`
4. Announce: "All tasks complete. Track marked [x] (implemented). Proceeding to review."

---

## 4.0 SYNCHRONIZE PROJECT DOCUMENTATION

Run this section only after the track reaches `[x]` status.

1. Read the track's `spec.md`.
2. Read `conductor/product.md`, `conductor/tech-stack.md`, `conductor/product-guidelines.md`.
3. Analyze whether the completed track introduces:
   - New features that change the product description → update `product.md`
   - New technologies or removed dependencies → update `tech-stack.md`
   - Fundamental changes to brand/voice (only if spec explicitly states this) → update `product-guidelines.md`
4. Apply any warranted updates directly. Announce each change made.
5. If changes were made: stage the updated files and commit: `docs(conductor): Synchronize docs for track '<track_description>'`
6. If no changes needed: announce "Project docs are already up to date."

---

## 5.0 AUTO-REVIEW GATE

Immediately after Section 4.0, without waiting for user input, execute the full **conductor-review** protocol against this track. The track context (track_id, spec.md, plan.md) is already in scope — do not re-load from scratch.

Proceed directly to the conductor-review skill instructions. Pass the current `<track_id>` as the review target.
