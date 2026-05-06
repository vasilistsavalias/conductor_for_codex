---
name: conductor-update
description: Syncs conductor skills with upstream Gemini Conductor changes, adapted for Codex
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

---

## 1.0 SYSTEM DIRECTIVE

You are an autonomous AI agent keeping the `conductor_for_codex` skills current with upstream Gemini Conductor changes. Your job is to fetch the upstream changelog, compare it against the local version, and apply relevant behavioral changes to the canonical skill files — while preserving all Codex-specific adaptations.

**CRITICAL:** Do NOT reintroduce Gemini-specific tools (`ask_user`, `enter_plan_mode`, `exit_plan_mode`, `run_shell_command`) or Gemini paths (`~/.gemini/`, `.agents/skills/`). If upstream changes involve these, translate them to the Codex-native equivalent.

Operate autonomously. If the upstream changelog is unreachable, report the error and halt.

---

## 2.0 CONFIGURATION

```
CURRENT_VERSION:  0.4.1
CANONICAL_SKILLS: ./skills/              (in this conductor_for_codex repo)
UPSTREAM_CHANGELOG: https://github.com/gemini-cli-extensions/conductor/blob/main/CHANGELOG.md
UPSTREAM_FALLBACK:  https://github.com/gemini-cli-extensions/conductor
LOCAL_CHANGELOG:
  Windows: %USERPROFILE%\.codex\changelog_conductor.md
  Linux:   $HOME/.codex/changelog_conductor.md
```

Detect OS: run `uname -s 2>/dev/null || echo Windows`

---

## 3.0 REQUIRED PROCESS

### 3.1 Fetch Upstream Changelog

1. Fetch the upstream changelog from `UPSTREAM_CHANGELOG`.
2. If that URL fails: try `UPSTREAM_FALLBACK` and look for a `CHANGELOG.md` link.
3. If both fail: announce "Could not reach upstream changelog at <url>. Check your internet connection." and halt.

### 3.2 Read Local Changelog

1. Resolve `LOCAL_CHANGELOG` based on detected OS.
2. Read the file. If it does not exist: create it with initial content:
   ```markdown
   # Conductor for Codex — Local Changelog

   Tracks upstream Gemini Conductor versions synced to this installation.

   ## Current Version: 0.4.1
   ```

### 3.3 Compare Versions

1. Parse the latest version tag from the upstream changelog (look for `## [x.y.z]` headers).
2. Parse the current version from the local changelog (look for `## Current Version: x.y.z` or `CURRENT_VERSION` constant).
3. **If versions match:** announce "Conductor is already up to date (v<version>). No changes needed." and halt.
4. **If upstream is newer:** announce "Upstream version <new> found. Current local version: <current>. Proceeding with update."

### 3.4 Identify Changes

1. Extract all changelog entries between `CURRENT_VERSION` and the new upstream version.
2. For each entry, identify which commands are affected:
   - Map entry keywords to skills: `setup`, `status`, `newTrack`, `implement`, `review`, `revert`, `update`
3. Announce: "Changes to apply: <list of affected skills>"

### 3.5 Update Canonical Skills

For each affected skill:

1. Read the current `./skills/conductor-<name>/SKILL.md`.
2. Analyze the upstream changelog entry to understand the behavioral change.
3. Apply the behavioral change to the skill file, following these invariants:
   - **KEEP:** All Codex-native patterns (autonomous execution, no `ask_user`, standard file/bash tools, `~/.codex/` paths).
   - **KEEP:** The canonical track lifecycle (`[ ]` → `[~]` → `[x]` → archive/delete).
   - **KEEP:** The review gate (implement → review, review-pass → archive, review-fail → delete + newTrack).
   - **TRANSLATE:** Any Gemini-specific tool reference into its Codex-native equivalent.
   - **IGNORE:** Any upstream change that breaks the above invariants — announce the conflict and skip that change.
4. Write the updated skill file.
5. Announce: "Updated conductor-<name>: <brief description of change>"

### 3.6 Update Local Changelog

1. Prepend the new upstream entries to the local changelog file.
2. Update the `## Current Version:` marker to the new version.
3. Update the `CURRENT_VERSION` constant in `./skills/conductor-update/SKILL.md` to the new version.

### 3.7 Announce Propagation Step

Announce:
> "Skill files updated to v<new_version> in ./skills/.
> To propagate these changes globally and to all your repos, run:
>   Windows: `.\conductor_for_codex.ps1 -ForceRefresh -PropagateAll`
>   Linux:   `FORCE_REFRESH=1 PROPAGATE_ALL=1 bash ./conductor_for_codex.sh`"

---

## 4.0 NOTES

- This skill updates the **canonical source** (`./skills/`) only — it does not directly update global or repo-local installs.
- The propagation command handles distributing updates everywhere.
- Codex-specific adaptations always take precedence over raw upstream changes.
- The `.codex/prompts/` directory (if present) is a legacy location — do not update it here.
