---
name: conductor-newTrack
description: Plans a new track, generates spec and plan files, and registers it in the tracks registry
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

CRITICAL: Conductor artifacts are **local-only**.

- You MUST NOT modify anything outside the repository root.
- Ensure `.gitignore` includes `conductor/`. If missing, add it.
- You MUST NOT `git add`/`git commit` Conductor artifacts unless explicitly creating track artifacts.

---

## 1.0 SYSTEM DIRECTIVE

You are an autonomous AI agent creating a new Conductor track. Operate with minimal user interaction: if `$ARGUMENTS` provides a description, use it directly. Only ask one clarifying question if the description is missing. Auto-generate the spec and plan from available context.

If any file operation fails, halt and report the error.

---

## 1.1 SETUP CHECK

Verify using the **Universal File Resolution Protocol**:

**Universal File Resolution Protocol:** For each required path, check `conductor/<file>` first; if missing, read `conductor/index.md` to find the canonical path.

Required files:
- `conductor/product.md`
- `conductor/tech-stack.md`
- `conductor/workflow.md`

If any are missing: report which are absent, announce "Conductor is not set up. Run `/conductor-setup` first.", and halt.

---

## 2.0 GET TRACK DESCRIPTION

1. **If `$ARGUMENTS` is provided and non-empty:** use it as the track description. Announce: "Creating track: '<description>'"
2. **If `$ARGUMENTS` is empty:** output exactly one question to the user:
   > "What is the track description? (e.g., 'Implement user authentication', 'Fix login redirect bug', 'Refactor database layer')"
   
   Wait for the user's response. Use that as the description.

3. **Infer track type** from the description:
   - Contains "fix", "bug", "error", "crash" → type: `bug`
   - Contains "refactor", "cleanup", "migrate", "rename" → type: `chore`
   - Anything else → type: `feature`
   Do NOT ask the user to classify it.

---

## 2.1 DUPLICATE NAME CHECK

Before generating any files:

1. Resolve the **Tracks Directory** (`conductor/tracks/`).
2. List all existing subdirectories in `conductor/tracks/`.
3. Extract the short name portion of each track ID (e.g., `auth_20250106` → `auth`).
4. Derive the proposed short name from the description (take the first 2-3 significant words, lowercase, underscores, max 20 chars).
5. If the proposed short name matches an existing track's short name: announce "A track named '<short_name>' already exists. Choose a different description or resume the existing track with `/conductor-implement`." and halt.

---

## 2.2 GENERATE SPEC

Load project context by reading `conductor/product.md` and `conductor/tech-stack.md`.

Auto-generate `spec.md` content including these sections:

```markdown
# Track Spec: <Description>

## Overview
<One paragraph describing what this track accomplishes and why>

## Functional Requirements
<Numbered list of concrete deliverables>

## Non-Functional Requirements
<Performance, security, or quality constraints, if applicable>

## Acceptance Criteria
<Checkable conditions that define done — be specific and testable>

## Out of Scope
<What this track explicitly does NOT do>
```

Use the project context (product.md, tech-stack.md) to make the spec accurate and concrete. Do not use placeholder text — generate real content based on the description.

Output the spec as text so the user can see it, then continue immediately without waiting for approval.

---

## 2.3 GENERATE PLAN

Read `conductor/workflow.md` to understand the project's task methodology (TDD, commit frequency, testing requirements, etc.).

Auto-generate `plan.md` with hierarchical Phases and Tasks:

```markdown
# Implementation Plan: <Description>

## Phase 1: <Phase Name>
- [ ] Task: <task description>
    - [ ] <sub-task>
    - [ ] <sub-task>
- [ ] Task: <task description>
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: <Phase Name>
...
```

Rules:
- Every task and sub-task gets `[ ]` marker.
- If the workflow defines a "Phase Completion Verification and Checkpointing Protocol", append a verification meta-task to each phase (format shown above).
- Follow TDD if the workflow specifies it: each implementation task should have a "Write tests" sub-task before "Implement".
- Generate realistic, concrete task names — not generic placeholders.

Output the plan as text so the user can see it, then continue immediately without waiting for approval.

---

## 2.4 CREATE TRACK ARTIFACTS

1. **Generate Track ID:** `<shortname>_<YYYYMMDD>` using today's date.
   - Short name: first 2-3 significant words from description, lowercase, underscores, max 20 chars.
   - Example: "Implement user authentication" → `user_auth_20250510`

2. **Create directory:** `conductor/tracks/<track_id>/`

3. **Write `metadata.json`:**
   ```json
   {
     "track_id": "<track_id>",
     "type": "<feature|bug|chore>",
     "status": "new",
     "created_at": "<ISO8601 timestamp>",
     "updated_at": "<ISO8601 timestamp>",
     "description": "<track description>"
   }
   ```

4. **Write `spec.md`:** the generated spec content from Section 2.2.

5. **Write `plan.md`:** the generated plan content from Section 2.3.

6. **Write `index.md`:**
   ```markdown
   # Track <track_id> Context

   - [Specification](./spec.md)
   - [Implementation Plan](./plan.md)
   - [Metadata](./metadata.json)
   ```

---

## 2.5 UPDATE TRACKS REGISTRY

1. Resolve `conductor/tracks.md` via Universal File Resolution Protocol.
2. Append a new section to the end of the file:

```markdown

---

- [ ] **Track: <Track Description>**
  *Link: [./tracks/<track_id>/](./tracks/<track_id>/)*
```

3. Commit the Tracks Registry change: `chore(conductor): Add new track '<track_description>'`

---

## 2.6 ANNOUNCE COMPLETION

Output:
> "Track '<track_id>' created.
> - Spec: conductor/tracks/<track_id>/spec.md
> - Plan: conductor/tracks/<track_id>/plan.md
> - Registry: updated in conductor/tracks.md
>
> Run `/conductor-implement` to begin implementation."
