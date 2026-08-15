# AI Repository Hygiene Policy

## Classification

| Class | Examples | Default action |
|---|---|---|
| Private workspace | Agent instructions, reasoning plans, transcripts, scratch reports, local screenshots, personal logs, tool caches | Move to external sidecar when untracked |
| Product-owned AI | Runtime prompts, model clients, retrieval code, evaluation fixtures, user-facing AI documentation | Keep in Git |
| Shared engineering | Source, tests, schemas, deployment files, reviewed documentation, configuration templates | Keep in Git |
| Runtime-local | `.env`, indexes, databases, downloaded raw data, dependency folders | Keep at required path and ignore appropriately |
| Secrets | Tokens, private keys, credentials, cookies | Move to approved secret storage; never sidecar notes |
| Tracked policy concern | Tracked agent guide, private plan, transcript, generated screenshot archive | Report; remove only through an authorized ordinary commit |
| Historical concern | Prior commit containing private workspace material | Report separately; never rewrite automatically |

## Sidecar convention

```text
programming/
├── github_repos/
│   └── project/
└── repo_local/
    └── project_local/
        ├── project.code-workspace
        ├── migration-report.json
        └── private artifacts
```

The VS Code workspace opens both `github_repos/project` and `repo_local/project_local`. Do not initialize the sidecar as a Git repository unless company policy explicitly requires private version control.

## Review questions

Before moving or deleting a candidate, answer:

1. Is any path under it present in `git ls-files` using a case-insensitive comparison?
2. Does application code, a build file, test, CI job, or documentation reference its exact path?
3. Does it contain credentials or sensitive data requiring approved storage?
4. Does Docker need it in the build context?
5. Is it an intentional project deliverable rather than personal evidence?
6. Would moving it make local and production behavior diverge?

Any uncertain answer means retain and report.

## Compliance report template

```text
AI repository hygiene: PASS | NEEDS REVIEW

Repository: <path>
Sidecar: <path>
Moved private artifacts: <count>
Tracked product files retained: <count>
Protected runtime paths retained: <count>
Tracked policy concerns: <count>
Public ignore findings: <count>
Docker context findings: <count>
Secrets exposed: <count>
Git status preserved: yes | no
Commit/push performed: none | <details>
History rewritten: no
```

## Common failure modes

- A broad `prompt.md` ignore hides real runtime prompts from production.
- Case-sensitive Git queries miss a tracked uppercase path on Windows.
- Removing `.dockerignore` entries sends private local files to the Docker daemon even though Git ignores them.
- Moving `.env` breaks local execution and places secrets in an inappropriate sidecar.
- Cleaning several already-dirty repositories mixes unrelated changes and makes review unsafe.
- Deleting a current file is incorrectly described as removing it from Git history.
