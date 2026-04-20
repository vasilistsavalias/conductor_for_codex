---
description: Update Codex Conductor prompts from upstream Gemini Conductor changelog
---
<!-- markdownlint-disable MD013 -->

# User Input

```text
$ARGUMENTS
```

## 1.0 SYSTEM DIRECTIVE

You are updating Codex Conductor prompts based on upstream Gemini Conductor changes. WARNING: ITS NOT NECESSARY TO FORCE AN UPDATE IF THE CONDUCTOR VERSION HASNT CHANGED.

CRITICAL: CURRENT CONDUCTOR VERSION UPDATE: "0.4.1" . IF YOU FIND THE SAME VERSION JUST REPLY ACCORDINGLY DONT DO ANYTHING ELSE.

Source changelog (upstream):
`https://github.com/gemini-cli-extensions/conductor/blob/main/CHANGELOG.md`

Source changelog (if the first operation fails):
`https://github.com/gemini-cli-extensions/conductor`

Local changelog (global Codex home):
`%USERPROFILE%\.codex\changelog_conductor.md`

## 2.0 REQUIRED PROCESS

1. Fetch the upstream changelog from the URL above.
2. Read the local changelog file from `%USERPROFILE%\.codex\changelog_conductor.md`.
   - If it does not exist, create it.
3. Compare upstream vs local:
   - Identify new entries or differences.
4. If new items exist:
   - Update the local changelog to include the new content.
   - Review upstream repo changes that impact prompts or workflow.
5. Update Codex prompts to match upstream behavior, adapted for Codex:
   - `.codex/skills/conductor-setup/SKILL.md`
   - `.codex/skills/conductor-implement/SKILL.md`
   - `.codex/skills/conductor-newTrack/SKILL.md`
   - `.codex/skills/conductor-review/SKILL.md`
   - `.codex/skills/conductor-revert/SKILL.md`
   - `.codex/skills/conductor-status/SKILL.md`
   - `conductor/templates/`
   - `conductor/skills/catalog.md`
6. Summarize the differences and any prompt changes made.

## 3.0 NOTES

- Codex cannot directly update Gemini extensions. This workflow emulates updates by syncing prompt content.
- Keep Codex-specific rules intact (Conductor local-only, no auto-commit unless explicitly asked).
