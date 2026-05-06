---
name: conductor-setup
description: Scaffolds the project and sets up the Conductor environment interactively
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

CRITICAL: Conductor artifacts are **local-only**.

- You MUST NOT modify anything outside the repository root.
- Ensure `.gitignore` includes `conductor/`. If missing, add it.
- You MUST NOT `git add`/`git commit` Conductor artifacts unless the final commit step below.

---

## 1.0 SYSTEM DIRECTIVE

You are an AI agent setting up the Conductor framework for a software project. This is the **one interactive command** — you are permitted and expected to ask the user questions at each step. Wait for user responses before proceeding.

Validate every file operation. If a file write fails, report the error and halt.

**Path resolution by OS:**
- Detect OS: run `uname -s 2>/dev/null || echo Windows`
- Windows: base Conductor home = `%USERPROFILE%\.codex` (PowerShell: `$env:USERPROFILE\.codex`)
- Linux/Mac: base Conductor home = `$HOME/.codex`

All template references use this Conductor home path.

---

## 1.1 PRE-INITIALIZATION OVERVIEW

Present this overview to the user before starting:

> "Welcome to Conductor. I will guide you through the following steps:
> 1. **Project Discovery:** Determine if this is a new or existing project.
> 2. **Product Definition:** Define the product's vision, guidelines, and technology stack.
> 3. **Configuration:** Select code style guides and customize the workflow.
> 4. **Track Generation:** Define the initial track and generate a detailed plan.
>
> Let's get started!"

---

## 1.2 PROJECT AUDIT

Check for existing Conductor artifacts and determine where to resume.

1. Announce: "Auditing project for existing Conductor configuration..."

2. Check for the existence of these paths:
   - `conductor/product.md`
   - `conductor/product-guidelines.md`
   - `conductor/tech-stack.md`
   - `conductor/code_styleguides/`
   - `conductor/workflow.md`
   - `conductor/index.md`
   - `conductor/tracks/` (look for any `plan.md` and `index.md` inside)

3. **Determine resume target** (highest match wins):

| Existing Artifacts | Target |
|---|---|
| Complete track in `conductor/tracks/` (spec + plan + metadata + index) | HALT: "Already initialized. Use `/conductor-newTrack` or `/conductor-implement`." |
| `conductor/index.md` | Jump to Section 3.0 |
| `conductor/workflow.md` | Jump to Section 2.5 |
| `conductor/code_styleguides/` | Jump to Section 2.4 |
| `conductor/tech-stack.md` | Jump to Section 2.3 |
| `conductor/product-guidelines.md` | Jump to Section 2.2 |
| `conductor/product.md` | Jump to Section 2.1 |
| Nothing | Continue to Section 2.0 |

4. Proceed to Section 2.0 first to establish Greenfield/Brownfield context before jumping.

---

## 2.0 PROJECT INCEPTION

### Detect Project Maturity

**Brownfield indicators** (check for these):
- Dependency manifests: `package.json`, `pom.xml`, `requirements.txt`, `go.mod`, `Cargo.toml`
- Source directories containing code: `src/`, `app/`, `lib/`, `bin/`

**Greenfield:** none of the above exist (ignoring `conductor/`, `.git/`, `README.md`).

Announce: "Detected: [Greenfield/Brownfield] project — [reason]."

**If the resume target from 1.2 is not Section 2.0:** announce the maturity briefly, then jump directly to the target section. Do not execute the rest of Section 2.0.

### Brownfield Protocol

If Brownfield and starting fresh (resume target is Section 2.0):

1. Ask the user: "A brownfield (existing) project was detected. May I perform a read-only scan to analyze it? (yes/no)"
2. If no: halt and await instructions.
3. If yes: scan the project respecting `.gitignore` patterns:
   - Run: `git ls-files --exclude-standard -co` to list relevant files.
   - Prioritize manifest files and root-level config files.
   - For files over 1MB: read only the first and last 20 lines.
4. Extract: programming language, frameworks, database drivers, architecture type, project goal.
5. If uncommitted changes exist (`git status --porcelain` shows changes outside `conductor/`): warn "WARNING: Uncommitted changes detected. Consider committing or stashing before proceeding."
6. Proceed to Section 2.1 with the gathered context.

### Greenfield Protocol

If Greenfield and starting fresh:

1. If `.git/` does not exist: run `git init` and announce "Git repository initialized."
2. Ask: "What do you want to build? (e.g., 'A mobile app for tracking expenses')"
3. Create `conductor/` directory.
4. Write the user's response to `conductor/product.md` under `# Initial Concept`.
5. Proceed to Section 2.1.

---

## 2.1 GENERATE PRODUCT GUIDE

1. Ask: "How would you like to define the product details?
   - **Interactive** — I'll ask questions to refine your vision.
   - **Autogenerate** — I'll draft a guide from your initial project goal."

2. **If Interactive:** ask (up to 4 questions, wait for responses):
   - Who are the target users?
   - What are the top 2-3 core features?
   - What problem does this solve?
   - Any key constraints or non-goals?
   
   (For Brownfield: frame these relative to the analyzed codebase.)

3. **If Autogenerate:** draft from the initial concept alone.

4. Draft `product.md` content with sections: Overview, Target Users, Core Features, Goals, Non-Goals.

5. Show the draft to the user and ask: "Does this look correct? (approve / suggest changes)"

6. Revise if needed. Once approved: write to `conductor/product.md` (append to existing `# Initial Concept` if present).

---

## 2.2 GENERATE PRODUCT GUIDELINES

1. Ask: "How would you like to define product guidelines?
   - **Interactive** — I'll ask about prose style, branding, and UX principles.
   - **Autogenerate** — I'll draft standard guidelines based on best practices."

2. **If Interactive:** ask (up to 4 questions, wait for responses):
   - What is the desired tone/voice? (formal, friendly, technical, etc.)
   - Any branding constraints? (colors, naming conventions, etc.)
   - UX principles? (e.g., mobile-first, accessibility standards)
   - Any communication anti-patterns to avoid?

3. **If Autogenerate:** draft from project type and product.md context.

4. Show the draft and ask: "Does this look correct? (approve / suggest changes)"

5. Once approved: write to `conductor/product-guidelines.md`.

---

## 2.3 DEFINE TECH STACK

**If Greenfield:**

1. Ask: "How would you like to define the tech stack?
   - **Interactive** — I'll guide you through language, frameworks, and database.
   - **Autogenerate** — I'll recommend a stack based on your project goal."

2. **If Interactive:** ask (up to 4 questions, wait for responses):
   - Primary programming language(s)?
   - Backend framework? (if applicable)
   - Frontend framework? (if applicable)
   - Database? (if applicable)

3. **If Autogenerate:** recommend a modern, suitable stack based on the project goal.

**If Brownfield:**
1. State the inferred tech stack based on the code analysis.
2. Ask: "Is this tech stack correct? (yes / no — if no, describe the correct stack)"
3. If no: ask for the correct stack description and use that.

4. Show the draft `tech-stack.md` and ask: "Does this look correct? (approve / suggest changes)"
5. Once approved: write to `conductor/tech-stack.md`.

---

## 2.4 SELECT CODE STYLE GUIDES

1. Determine the templates directory:
   - Windows: `%USERPROFILE%\.codex\conductor\templates\code_styleguides\`
   - Linux/Mac: `$HOME/.codex/conductor/templates/code_styleguides/`
2. List available style guide files in that directory.
3. If the directory does not exist: announce "Style guide templates not found at <path>. Skipping style guide selection — re-run the global installer to add templates." and jump to Section 2.5.

4. **If Greenfield:** recommend guides based on the tech stack. Ask:
   - "I recommend: <list>. Use recommended / select from library?"
   
5. **If Brownfield:** announce the inferred guides. Ask:
   - "I identified these guides for your project: <list>. Proceed / add more?"

6. Once selection confirmed: create `conductor/code_styleguides/` and copy chosen files from the templates directory.

---

## 2.5 SELECT WORKFLOW

1. Determine templates directory (same OS logic as 2.4): `<conductor_home>/conductor/templates/workflow.md`
2. Copy `workflow.md` to `conductor/workflow.md`. If the template is not found: create a minimal `workflow.md` with TDD and per-task commit defaults, announce "Using default workflow (template not found)."
3. Ask: "Do you want to use the default workflow or customize it?
   - **Default** — standard Conductor workflow (>80% test coverage, per-task commits).
   - **Customize** — adjust coverage, commit frequency, summary storage."

4. **If Customize:** ask (wait for responses before continuing):
   - "Required test coverage percentage? (default: 80)"
   - "Commit frequency? (per-task / per-phase)"
   - "Task summary storage? (git notes / commit messages)"
   - "Anything else to add to the workflow? (leave blank to finish)"

5. Update `conductor/workflow.md` with the user's choices.

---

## 2.6 FINALIZATION

1. Create `conductor/index.md`:
   ```markdown
   # Project Context

   ## Definition
   - [Product Definition](./product.md)
   - [Product Guidelines](./product-guidelines.md)
   - [Tech Stack](./tech-stack.md)

   ## Workflow
   - [Workflow](./workflow.md)
   - [Code Style Guides](./code_styleguides/)

   ## Management
   - [Tracks Registry](./tracks.md)
   - [Tracks Directory](./tracks/)
   ```

2. Summarize completed actions to the user.
3. Announce: "Setup complete. Now defining the initial track."
4. Proceed immediately to Section 3.0.

---

## 3.0 INITIAL TRACK GENERATION

### 3.1 Gather Requirements (Greenfield Only)

For Greenfield projects, ask about product requirements:

1. Ask: "How would you like to define the initial requirements?
   - **Interactive** — I'll guide you through user stories and features.
   - **Autogenerate** — I'll draft requirements from the Product Guide."

2. **If Interactive:** ask (up to 4 questions):
   - Key user stories? (e.g., "As a user, I want to...")
   - Core features for the first version?
   - Any constraints or non-functional requirements?
   - Success metrics?

3. **If Autogenerate:** draft from `conductor/product.md` context.
4. Show draft requirements and ask: "Does this look correct? (approve / suggest changes)"
5. Once approved: retain in context for track proposal.

### 3.2 Propose Initial Track

1. Analyze the project context and requirements to propose a single initial track title.
   - Greenfield: focus on MVP core (e.g., "Build core authentication system").
   - Brownfield: focus on the most impactful next improvement.

2. Ask: "I suggest this initial track: '<Track Title>'. Proceed with this / suggest a different one?"

3. If user suggests changes: ask "What should the initial track be?" and use their answer.

### 3.3 Create Track Artifacts (Automated)

Using the confirmed track description, create all artifacts automatically:

1. Initialize `conductor/tracks.md`:
   ```markdown
   # Project Tracks

   This file tracks all major tracks for the project.

   ---

   - [ ] **Track: <Track Description>**
     *Link: [./tracks/<track_id>/](./tracks/<track_id>/)*
   ```

2. Generate Track ID: `<shortname>_<YYYYMMDD>`

3. Create `conductor/tracks/<track_id>/` directory.

4. Auto-generate `spec.md` for the track (same format as conductor-newTrack Section 2.2).

5. Auto-generate `plan.md` for the track following `conductor/workflow.md` methodology.

6. Write `metadata.json`:
   ```json
   {
     "track_id": "<track_id>",
     "type": "feature",
     "status": "new",
     "created_at": "<ISO8601>",
     "updated_at": "<ISO8601>",
     "description": "<Track Description>"
   }
   ```

7. Write `index.md`:
   ```markdown
   # Track <track_id> Context

   - [Specification](./spec.md)
   - [Implementation Plan](./plan.md)
   - [Metadata](./metadata.json)
   ```

### 3.4 Commit and Announce

1. Stage all `conductor/` files and commit: `conductor(setup): Add conductor setup files`
2. Ensure `conductor/` is in `.gitignore` (add if missing; note: the `conductor/` entry prevents the artifacts from being committed normally — the setup commit is the one-time exception).
3. Announce:
   > "Conductor setup complete.
   > - Project: <product name>
   > - First track: '<track_description>' (ID: <track_id>)
   >
   > Run `/conductor-implement` to start building."
