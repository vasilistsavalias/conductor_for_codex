# Conductor for Codex — Full Rebuild Plan (Codex-Native, Autonomous-First)

## Objective
Rebuild `conductor_for_codex` from a clean baseline so all Conductor commands are explicitly adapted for Codex execution semantics, maximize autonomous agent behavior, remove non-Codex/legacy interaction patterns, and ship a consistent install + propagation system with clean docs. right now its out of date or wrongly put. we have to find the real gemini conductor and see what we are missing and how we going to adapt it for our causes

This plan assumes a fresh pass from zero and is written for direct execution by an implementation agent.

---

## Guiding Principles
1. Codex-native first: command/skill behavior must align with Codex capabilities and constraints, not Gemini CLI internals.
2. Autonomous-by-default: commands should proceed independently whenever safe; only ask user questions when high-impact ambiguity truly blocks progress. change every file of conductor that says otherwise
3. Deterministic workflows: each command should have strict state transitions and explicit success/failure conditions.
4. Local artifact safety: `conductor/` artifacts stay local-only unless explicitly requested otherwise.
5. Single source of truth: one canonical skill source in repo; all generated/distributed copies derive from it.
6. Idempotent installation and sync: repeat runs should converge safely without manual cleanup.

---

## Scope
- In scope:
  - All Conductor command skills (`setup`, `status`, `newTrack`, `implement`, `review`, `revert`, `update` naming decision).
  - Installer scripts (Windows + Linux) and repo init flow.
  - README and related docs correctness.
  - Prompt mirror files (if kept) and parity rules.
  - Global and repo-local propagation strategy.
  - Verification and acceptance criteria.
- Out of scope:
  - Changing upstream Gemini repository itself.
  - Introducing platform-specific runtime dependencies unless required.

---

## Phase 1 — Baseline and Inventory

### 1.1 Repository and Upstream Baseline
- Pin upstream reference:
  - Record exact upstream commit SHA and latest tagged release.
  - Capture command inventory from upstream (`setup`, `status`, `newTrack`, `implement`, `review`, `revert`).
- Record local baseline:
  - Current branch/HEAD, remote tracking, uncommitted changes.
  - Current skill folders in canonical source.
  - Installer behavior and current skill list.

### 1.2 Canonical Source Decision
- Choose one canonical source directory in `conductor_for_codex`:
  - Recommended: `skills/<skill>/SKILL.md` only.
- Define mirror policy:
  - `.codex/skills/*` in this repo is either:
    - generated and validated from canonical source, or
    - removed from versioned source if unnecessary.
- Enforce “no dual-manual-edit” policy.

### 1.3 Gap Matrix (Required Deliverable)
Produce a table for each command:
- Upstream behavior summary.
- Current local behavior summary.
- Codex-specific required behavior.
- Delta category:
  - Missing capability
  - Wrong interaction pattern
  - Non-autonomous blocker
  - Format/parser mismatch
  - Safety/policy mismatch

---

## Phase 2 — Codex Command Spec Redesign

Define a strict command contract for each skill before editing files.

### 2.1 Global Command Contract (applies to all)
- Must use Codex-style autonomous flow:
  - Explore first, ask only when needed.
  - Prefer direct execution over conversational branching where safe.
- Must remove/replace legacy wording that causes over-halting behavior.
- Must include explicit:
  - Preconditions
  - Inputs
  - Main execution path
  - Failure handling path
  - Completion output contract

### 2.2 `conductor-setup`
- THIS IS the only exception to autnomous behaviour as in the setup the user is reuqestted to give information,this wont happen again in the rest.
- Ensure outputs are deterministic:
  - `conductor/product.md`
  - `conductor/product-guidelines.md`
  - `conductor/tech-stack.md`
  - `conductor/workflow.md`
  - tracks registry + first track scaffolding (if setup mode requires it)

### 2.3 `conductor-status`
- Pure read/report command.
- Support both track registry formats if needed, but choose one canonical format for write paths.
- Report should include machine-checkable summary fields.

### 2.4 `conductor-newTrack`
- Must generate spec/plan with minimal blocking.
- Ensure canonical tracks format and metadata schema are consistent with `implement/review/revert` parsers.
- Add explicit duplicate track-name prevention behavior.

### 2.5 `conductor-implement`
- Autonomous execution engine for plan tasks.
- Must define exact track lifecycle transitions.
- Must remove ambiguous “manual stop” phrasing unless real blocker.
- Must not mark track complete without meeting completion criteria.

### 2.6 `conductor-review`
- Define its role as explicit quality gate command.
- Decide policy:
  - Manual invocation only, or
  - Required pre-close gate integrated into `implement` lifecycle.
- If integrated, codify how `implement` triggers/depends on review outcome. the point of review is to review if the task that was done metthe criteria if it didnt -> we delete this track and recreate it with new stuff.otherwise we archieve it because its finished 

### 2.7 `conductor-revert`
- Keep git-aware revert scope.
- Simplify user interaction and make target selection deterministic.
- Ensure no destructive behavior without explicit confirmation.

### 2.8 `conductor-update` (name finalization)
- Final canonical name: `conductor-update`.
- Define exact responsibilities:
  - fetch upstream changelog/release info,
  - compare versions,
  - produce update plan catered to conductor_for_codex,not in general
- Remove stale path references and ensure correct prompt/skill path naming conventions.

---

## Phase 3 — Lifecycle and State Machine Normalization

### 3.1 Canonical Track States
Define exact states and transitions, e.g.:
- `new` -> `in_progress` -> `implemented` -> `review_passed` -> `closed`
- Optional terminal: `cancelled`

### 3.2 Command-to-State Mapping
- `newTrack`: creates `new`
- `implement`: moves through `in_progress` and `implemented`
- `review`: produces `review_passed` or `review_failed` decision
- close/archive/delete operations require `review_passed`

### 3.3 Registry and Plan Format Consistency
- Standardize one track entry format (no parser ambiguity).
- Standardize task markers in `plan.md`.
- Update all command parsers to the same canonical schema.

---

## Phase 4 — File Updates (Implementation Work Plan)

### 4.1 Skills
- Rebuild all command skills from approved command contracts.
- Ensure frontmatter correctness:
  - `name`, `description`, markdown integrity.
- Remove malformed escapes/newline artifacts.

### 4.2 Prompt Mirrors (if retained)
- If `.codex/prompts` is kept, define one-way generation from canonical skills or upstream-mapped command source.
- Enforce naming convention consistency (underscore vs dot) and document it.

### 4.3 Installers
- Update Windows and Linux installers to include exact canonical skill set:
  - `conductor-setup`
  - `conductor-status`
  - `conductor-newTrack`
  - `conductor-implement`
  - `conductor-review`
  - `conductor-revert`
  - `conductor-update`
- Keep non-destructive default behavior for general init.
- Add explicit “force refresh conductor skills” option for controlled overwrite.

### 4.4 Repo Init Command
- Ensure repo init can:
  - install missing conductor skills,
  - optionally refresh existing conductor skills when requested,
  - enforce `AGENTS.md` and `.gitignore` rules.

### 4.5 Docs and README
- Full doc audit and rewrite for consistency:
  - skill list names,
  - command names,
  - folder layout counts,
  - examples,
  - update workflow,
  - propagation workflow.
- Remove contradictory or stale references.

---

## Phase 5 — Propagation Architecture

### 5.1 Distribution Rules
- Canonical source: `conductor_for_codex/skills/*`
- Distribution targets:
  - Global: `%USERPROFILE%\.codex\skills`
  - Repo-local: `.../github_repos/*/.codex/skills`
  - Current workspace `.codex/skills` if requested

### 5.2 Replace-in-Place Strategy
- For conductor skills only:
  - remove old folder,
  - copy canonical folder,
  - leave non-conductor skills untouched.
- Remove deprecated alias folder names (`update-conductor`) after rename.

### 5.3 Verification by Hash
- Compare hashes for key skills across all targets:
  - `conductor-implement`
  - `conductor-review`
  - `conductor-update`
- Assert no deprecated folder remains.

---

## Phase 6 — Quality Gates and Testing

### 6.1 Static Validation
- Validate every `SKILL.md`:
  - frontmatter parseable,
  - required sections present,
  - no malformed markdown fences,
  - no literal escape artifacts.

### 6.2 Behavioral Validation (Dry Runs)
Run command simulations in a test repo:
- Setup flow (greenfield + brownfield)
- New track creation
- Implement progression
- Review pass/fail path
- Revert selection and plan
- Status report correctness

### 6.3 Lifecycle Gate Validation
- Ensure close/archive/delete cannot occur before review pass if that policy is selected.
- Confirm state transitions and registry updates are consistent.

### 6.4 Installer Validation
- Fresh machine/profile simulation (or isolated test path):
  - installer run,
  - init run,
  - command availability check.

---

## Phase 7 — Release and Change Control

### 7.1 Branch and Commit Discipline
- Use focused commits by subsystem:
  - skills redesign,
  - installer updates,
  - docs rewrite,
  - propagation tooling.
- Avoid mixed unrelated changes.

### 7.2 Versioning
- Bump internal conductor-for-codex version marker and changelog.
- Record upstream source version and commit used for sync.

### 7.3 Rollout Order
1. Merge canonical skill redesign.
2. Merge installer/init updates.
3. Merge docs updates.
4. Run propagation script to global + repo-local targets.
5. Run post-propagation hash verification.

---

## Acceptance Criteria (Must All Pass)
1. All seven canonical skills exist and are valid (`setup/status/newTrack/implement/review/revert/update`).
2. Command behavior is Codex-native and autonomous-first; no unnecessary hard-stop flow text remains.
3. Track lifecycle is explicit and enforced across commands.
4. README and installation docs are fully consistent with actual behavior and names.
5. Installer/init include `conductor-review` and `conductor-update` consistently.
6. Global + repo-local + current workspace skill folders are synchronized from canonical source.
7. Deprecated naming (`update-conductor`) is fully removed from active targets.
8. Verification report (hash + behavior checks) is produced and clean.

---

## Implementation Checklist (Execution Order)
1. Build gap matrix.
2. Approve command contracts.
3. Rebuild canonical skills.
4. Normalize lifecycle and parser formats.
5. Update installers/init.
6. Rewrite README/docs.
7. Run static validation.
8. Run behavior validation.
9. Commit/push cleanly.
10. Propagate to global/repo-local/current workspace.
11. Run hash verification + final report.

---

## Notes for Claude (Execution Constraints)
- Do not assume prior local state is correct.
- Treat malformed markdown/escaping as blocking defects.
- Prefer deterministic edits over broad regex rewrites where possible.
- Do not leave dual naming (`update-conductor` + `conductor-update`) in active paths.
- If conflicts appear during rebase/pull, resolve by preserving the approved canonical skill contracts and rerun validations.




## IN THE END 
make sure to put these updated skills templates whatsmacallit into the global .codex of my pc,and every subrepo/folder of githubrepos folder so each one of my different projects have the updated skills/review 