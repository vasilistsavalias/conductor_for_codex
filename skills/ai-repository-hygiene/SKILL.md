---
name: ai-repository-hygiene
description: Enforce company repository-hygiene rules for AI-assisted development. Use when auditing or cleaning Git repositories so private agent instructions, reasoning plans, transcripts, screenshots, logs, caches, and personal workspace files remain outside shared repositories and Docker build contexts; when creating external per-repository sidecars and VS Code workspaces; or when cleaning AI-specific entries from .gitignore, .dockerignore, and .git/info/exclude without moving tracked product code, runtime prompts, secrets, dependencies, or generated runtime data.
---

# AI Repository Hygiene

Keep shared repositories professional while preserving private development material in an external sidecar. Treat this as company compliance, not as a history-concealment mechanism.

## Non-negotiable boundaries

- Never rewrite Git history, force-push, delete branches, or remove worktrees as part of hygiene.
- Never move or delete a tracked path automatically, even when its name contains `agent`, `prompt`, `Gemini`, `Claude`, or `Codex`.
- Never treat product-owned runtime prompts, model code, RAG logic, evaluations, or AI documentation as private workspace debris.
- Never move `.env`, credentials, keys, dependencies, databases, indexes, build outputs required in place, or configuration with a fixed runtime path.
- Never discard dirty worktree changes.
- Never commit or push unless the user explicitly requests it.
- Never print secret contents. Report paths only.
- Compare paths case-insensitively against the complete Git index before moving. Windows can expose `gemini.md` and tracked `GEMINI.md` as the same file.

Read [references/policy.md](references/policy.md) when classification is ambiguous or when producing a compliance report.

## Modes

### Audit

Use audit by default. Make no changes.

```powershell
python "$env:USERPROFILE\.codex\skills\ai-repository-hygiene\scripts\sidecar_hygiene.py" --repo .
```

The audit identifies safe sidecar candidates, tracked blockers, public ignore-file findings, protected paths, the inferred sidecar, and current Git status.

### Apply

Use apply only when the user authorizes migration.

```powershell
python "$env:USERPROFILE\.codex\skills\ai-repository-hygiene\scripts\sidecar_hygiene.py" --repo . --apply
```

Pass `--sidecar-root <path>` when the repository is not under a conventional `github_repos/` directory. Apply mode moves only preflighted untracked root candidates and creates `<repo>.code-workspace` plus `migration-report.json` in the sidecar. It does not edit ignore files.

## Workflow

1. Record the repository root, branch, `git status --short`, worktrees, and remotes.
2. Run the audit script. Do not infer safety from `.gitignore` or `.git/info/exclude`; ignored files can still be tracked or runtime-critical.
3. Inspect candidates using the policy classification:
   - move private human/agent workspace artifacts;
   - retain product-owned and runtime-required files;
   - leave tracked policy violations in place and report them for an ordinary reviewed repository change;
   - route secrets to approved secret storage, not the sidecar.
4. Apply migration only after the candidate list is safe.
5. Inspect remaining ignored/untracked files, including nested artifacts the root-candidate script intentionally does not move automatically.
6. Clean ignore files narrowly:
   - keep `.gitignore` limited to shared project outputs, environments, runtime data, and standard OS/editor files;
   - keep `.dockerignore` limited to files that must not enter the build context;
   - minimize `.git/info/exclude` after sidecar migration, retaining only genuine machine-local runtime paths.
7. Before removing a Docker exclusion, inspect Dockerfiles and Compose build contexts. Git exclusions do not affect Docker.
8. Verify behavior and repository integrity.
9. Report current-tree compliance separately from historical findings. Do not imply that ordinary deletion removes old Git objects.

## Ignore-file cleanup rules

Remove public entries that expose private workflow names only when their files have moved outside the repository. Examples include agent workspaces, personal plans, private screenshots, temporary reports, and tool caches.

Retain generic functional entries such as:

- dependencies and virtual environments;
- build, test, and coverage outputs;
- `.env` patterns;
- runtime databases and generated indexes;
- raw corpora excluded from images;
- standard OS/editor artifacts;
- files deliberately excluded from the Docker build context.

Do not replace many private names with a misleading wildcard that could hide product source. Never add broad patterns such as `prompt.md`, `*.md`, `data/`, or `.*` without proving every affected path is disposable.

## Verification

After migration and cleanup:

1. Compare Git status with the baseline. Unexpected tracked deletions are blockers.
2. Run `git ls-files` searches for prohibited current-tree paths.
3. Scan public ignore files for company-policy terms and personal filenames.
4. Validate every VS Code workspace as JSON and resolve both folder paths.
5. Run `git diff --check` for tracked ignore-file edits.
6. Run `docker compose config --quiet` when Compose exists.
7. Run the narrowest tests needed if a formerly hidden file is discovered to be product source.
8. Confirm the sidecar is outside the Git root and Docker context.
9. Confirm no commits or pushes occurred unless authorized.

## Required report

Report:

- repository and sidecar paths;
- moved private artifacts;
- tracked files retained;
- protected/runtime files retained;
- public ignore entries removed or still requiring review;
- Docker validation result;
- Git status before and after;
- commits and pushes, or explicitly `none`;
- history rewrite, always `no` unless the user separately requested and approved it outside this skill.

Stop when the repository is compliant for the requested scope. Do not broaden one repository cleanup into edits across every dirty repository without explicit authorization.
