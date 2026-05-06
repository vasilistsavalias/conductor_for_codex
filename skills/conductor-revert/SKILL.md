---
name: conductor-revert
description: Reverts a track, phase, or task using git-aware reversion with one final confirmation
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

CRITICAL: Conductor artifacts are **local-only**.

- You MUST NOT modify anything outside the repository root.
- Ensure `.gitignore` includes `conductor/`. If missing, add it.

---

## 1.0 SYSTEM DIRECTIVE

You are an autonomous AI agent performing a git-aware revert for the Conductor framework. Identify the target, analyze the git history, present a clear revert plan, then execute after one explicit user confirmation. Do not ask confirmation at any other point.

If a shell command fails, halt and report the error.

---

## 1.1 SETUP CHECK

Verify using the **Universal File Resolution Protocol**:

**Universal File Resolution Protocol:** Check `conductor/<file>` first; if missing, read `conductor/index.md` for canonical paths.

Required:
- `conductor/tracks.md` — must exist and be non-empty.

If missing or empty: announce "The tracks registry is missing or empty. Run `/conductor-setup` or restore `conductor/tracks.md`." and halt.

---

## 2.0 TARGET IDENTIFICATION (Autonomous)

### 2.1 Resolve Target from Arguments

**If `$ARGUMENTS` is provided:**
1. Parse the argument. Examples: `track auth_20250510`, `phase "Phase 2"`, `task "Add user model"`.
2. Read `conductor/tracks.md` and each track's `plan.md` to find the matching track, phase, or task.
3. If exactly one match: set it as the `target_intent`. Announce: "Target identified: [Track/Phase/Task] '<description>'"
4. If no match: list all available tracks with their IDs, announce "No match for '$ARGUMENTS'.", and halt.
5. If ambiguous (multiple matches): list the matches, announce "Multiple matches found for '$ARGUMENTS'. Re-run with a more specific target (e.g., include the track ID).", and halt.

**If `$ARGUMENTS` is empty:**
1. Read `conductor/tracks.md`.
2. Find the first track marked `[~]` (in-progress) — prefer this as the revert target.
3. If no `[~]` track: find the first track marked `[x]` (implemented).
4. If neither: announce "No in-progress or implemented tracks found to revert." and halt.
5. Set the found track as `target_intent`. Announce: "Auto-selected track for revert: '<description>' (ID: <track_id>)"

---

## 3.0 GIT RECONCILIATION

Analyze the git history to find all commits associated with the target.

### 3.1 Identify Implementation Commits

1. Read the target's `plan.md` (or the relevant phase/task section).
2. Extract all git SHAs recorded in `[x]` task lines (format: `[x] Task: <desc> <sha>`).
3. For each SHA: run `git log --oneline <sha> -1` to verify it exists. If a SHA is not found in git history (rewritten history): search `git log --oneline` for a commit with a highly similar message and announce the substitution.

### 3.2 Identify Plan-Update Commits

For each validated implementation SHA, find the corresponding plan-update commit:
- Run `git log --oneline --follow -- conductor/tracks/<track_id>/plan.md` and find the commit that updated `plan.md` immediately after the implementation commit.
- Add each plan-update SHA to the list.

### 3.3 Track Creation Commit (Track-level Revert Only)

If the target is an entire track:
- Run `git log --oneline -- conductor/tracks.md` and find the commit that first added this track's entry.
- Add this SHA to the list.

### 3.4 Compile Final Commit List

1. Compile all SHAs in chronological order (newest first for revert sequence).
2. Check for merge commits (`git cat-file -t <sha>` shows `merge`). Warn if any are present — they require `git revert -m 1`.
3. Announce the complete list:

```
Commits to revert (in order):
  <sha1> — <commit message>
  <sha2> — <commit message>
  ...
```

---

## 4.0 FINAL CONFIRMATION

Present the revert plan clearly:

> "REVERT PLAN
> Target: [Track/Phase/Task] '<description>'
> Action: git revert <N> commits in reverse chronological order
> Commits:
>   <sha1> (<message>)
>   <sha2> (<message>)
>
> Type **yes** to proceed or **no** to cancel."

**Wait for the user's response.** This is the only confirmation gate.

- If user responds `yes` (or `y`): proceed to Section 5.0.
- If user responds `no` (or `n`): announce "Revert cancelled. No changes made." and halt.
- Any other response: repeat the prompt once. If still unclear: cancel and halt.

---

## 5.0 EXECUTION

Execute the revert in reverse order (most recent SHA first):

1. For each SHA:
   - Run `git revert --no-edit <sha>` (or `git revert -m 1 --no-edit <sha>` for merge commits).
   - If the revert fails due to a merge conflict: halt immediately. Announce the conflicting files and instruct: "Resolve conflicts manually, then run `git revert --continue`."

2. After all reverts succeed, read the affected `plan.md` file(s) again.
3. Verify the reverted items show `[ ]` status (reset). If not: fix the `plan.md` file manually to reset the reverted tasks to `[ ]`, and commit: `conductor(plan): Reset reverted tasks in '<track_id>'`

4. Announce: "Revert complete. <N> commits reverted. Plan state verified."
