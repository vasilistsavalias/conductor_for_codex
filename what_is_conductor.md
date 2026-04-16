# What Is Conductor?

Conductor is a workflow style for AI-assisted development where project context is treated as a first-class input, not an afterthought.

Instead of re-explaining your project every session, you keep stable context, use clear planning steps, and start work from shared project state.

## The Core Idea

Context-driven development means you do not rely on one-off prompts alone. You keep project context available over time, then use that context to guide planning and implementation.

In practical terms:

- You define what the project is, what the current goals are, and how work should be done.
- You check status before coding.
- You plan before implementation when needed.
- You keep the same workflow across sessions.

Why this matters in multi-session coding:

- Less repeated setup at the start of each session.
- Fewer mismatches between what you want and what the agent assumes.
- More consistent execution when work spans days or weeks.

## How It Changes Day-to-Day Work

Before:

- Every session starts with re-orienting the agent.
- Project rules can be forgotten between sessions.
- Work style changes from prompt to prompt.

After:

- Session starts with a status check.
- Project rules are applied consistently.
- Planning and implementation follow a repeatable flow.

The result is usually less coordination overhead and steadier output quality.

## Why This Repo Exists

This repo brings a Conductor-style workflow into Codex by installing:

- Conductor-focused skills globally.
- A global repo init command (`codex_conductor_init`) you can run in any project.

That gives you a simple pattern:

1. Install once globally.
2. Run repo init where needed.
3. Start with `$conductor-status` and work from current project state.

## Commands (Codex Skills)

This repo installs these commands/skills into Codex. The exact behavior is defined by the `skills/*/SKILL.md` files.

| Command | What it does | Reads/Writes (typical) |
| --- | --- | --- |
| `$conductor-setup` | Guided project setup: defines product docs, chooses style guides, and configures workflow. | Writes `conductor/product.md`, `conductor/product-guidelines.md`, `conductor/tech-stack.md`, `conductor/workflow.md`, `conductor/code_styleguides/`, `conductor/tracks.md`, `conductor/setup_state.json` |
| `$conductor-status` | Status overview of your current tracks and active work. | Reads `conductor/tracks.md` and linked track plans |
| `$conductor-newTrack` | Create a new track with an interactive `spec.md` and `plan.md`, then register it. | Writes `conductor/tracks/<track_id>/*` and appends to `conductor/tracks.md` |
| `$conductor-implement` | Implement tasks from the selected track plan in order. | Reads `conductor/tracks.md`, `conductor/tracks/<id>/plan.md`, `conductor/workflow.md`; updates plan/tracks statuses as it progresses |
| `$conductor-review` | Review a track, revision range, or current changes against the plan, product guidelines, style guides, tests, and relevant installed skills. | Reads Conductor context and git diffs; optionally applies review fixes with user approval |
| `$conductor-revert` | Revert a track/phase/task by analyzing git history and Conductor artifacts. | Reads tracks/plans; performs git reverts per the selected scope |
| `$update-conductor` | Update Conductor prompts/skills based on upstream changes (if configured). | Updates local skill content (varies by setup) |

## Credit

This project is directly inspired by the original Gemini Conductor approach.

Original source/reference:

- Gemini Conductor extension: <https://github.com/gemini-cli-extensions/conductor>

## Next Step

Go to [`README.md`](README.md) for installation and usage.
