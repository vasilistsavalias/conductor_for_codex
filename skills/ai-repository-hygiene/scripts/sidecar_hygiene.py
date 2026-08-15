#!/usr/bin/env python3
"""Audit and safely migrate private repository workspace artifacts."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


PRIVATE_CANDIDATES = (
    ".codex",
    ".agents",
    ".claude",
    ".agent-cache",
    ".codex-cache",
    "conductor",
    "for_ais",
    "for_claude",
    "for_codex",
    "screenshots",
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "debate.md",
    "plan.md",
    "handoff.md",
    "agent_handoff.md",
    "loc_analysis.md",
    "src_loc_analysis.md",
)

PUBLIC_MARKERS = (
    "codex",
    "claude",
    "gemini",
    "conductor",
    "for_ais",
    "for_claude",
    "for_codex",
    "agents.md",
    "debate.md",
    "agent-cache",
    "codex-cache",
)


@dataclass(frozen=True)
class Candidate:
    path: str
    classification: str
    reason: str


def git(repo: Path, *args: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout


def repository_root(value: str) -> Path:
    supplied = Path(value).expanduser().resolve()
    root = git(supplied, "rev-parse", "--show-toplevel").decode().strip()
    return Path(root).resolve()


def infer_sidecar_root(repo: Path, supplied: str | None) -> Path:
    if supplied:
        root = Path(supplied).expanduser().resolve()
    elif repo.parent.name.casefold() == "github_repos":
        root = repo.parent.parent / "repo_local"
    else:
        raise ValueError("Pass --sidecar-root when the repository is not under github_repos")
    try:
        root.relative_to(repo)
    except ValueError:
        return root
    raise ValueError("The sidecar root must be outside the Git repository")


def tracked_paths(repo: Path) -> set[str]:
    raw = git(repo, "ls-files", "-z")
    return {
        item.decode("utf-8", errors="surrogateescape").replace("\\", "/").casefold()
        for item in raw.split(b"\0")
        if item
    }


def contains_tracked(relative: str, tracked: set[str]) -> bool:
    normalized = relative.replace("\\", "/").strip("/").casefold()
    prefix = normalized + "/"
    return normalized in tracked or any(path.startswith(prefix) for path in tracked)


def find_candidates(repo: Path, tracked: set[str]) -> list[Candidate]:
    findings: list[Candidate] = []
    seen: set[str] = set()
    for name in PRIVATE_CANDIDATES:
        path = repo / name
        if not path.exists():
            continue
        key = str(path).casefold()
        if key in seen:
            continue
        seen.add(key)
        relative = path.relative_to(repo).as_posix()
        if contains_tracked(relative, tracked):
            findings.append(Candidate(relative, "tracked", "Git index contains this path or a child"))
        else:
            findings.append(Candidate(relative, "moveable", "Untracked private workspace candidate"))
    return findings


def public_ignore_findings(repo: Path) -> list[str]:
    findings: list[str] = []
    for filename in (".gitignore", ".dockerignore"):
        path = repo / filename
        if not path.is_file():
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            lowered = line.casefold()
            if any(marker in lowered for marker in PUBLIC_MARKERS):
                findings.append(f"{filename}:{number}:{line.strip()}")
    return findings


def git_status(repo: Path) -> list[str]:
    return git(repo, "status", "--short").decode("utf-8", errors="replace").splitlines()


def write_workspace(repo: Path, sidecar: Path) -> Path:
    workspace = sidecar / f"{repo.name}.code-workspace"
    relative_repo = Path("..", "..", "github_repos", repo.name).as_posix()
    payload = {
        "folders": [
            {"name": repo.name, "path": relative_repo},
            {"name": f"{repo.name} local", "path": "."},
        ]
    }
    workspace.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return workspace


def apply_migration(repo: Path, sidecar: Path, candidates: list[Candidate]) -> list[str]:
    moveable = [candidate for candidate in candidates if candidate.classification == "moveable"]
    conflicts = [candidate.path for candidate in moveable if (sidecar / candidate.path).exists()]
    if conflicts:
        raise ValueError("Sidecar destination already exists: " + ", ".join(conflicts))

    sidecar.mkdir(parents=True, exist_ok=True)
    exclude = repo / ".git" / "info" / "exclude"
    if exclude.is_file():
        shutil.copy2(exclude, sidecar / "git-info-exclude.before-migration.txt")

    moved: list[str] = []
    for candidate in moveable:
        source = repo / candidate.path
        destination = sidecar / candidate.path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))
        moved.append(candidate.path)
    write_workspace(repo, sidecar)
    return moved


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="Repository path")
    parser.add_argument("--sidecar-root", help="Parent directory for <repo>_local")
    parser.add_argument("--apply", action="store_true", help="Move safe untracked root candidates")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        repo = repository_root(args.repo)
        sidecar_root = infer_sidecar_root(repo, args.sidecar_root)
        sidecar = sidecar_root / f"{repo.name}_local"
        tracked = tracked_paths(repo)
        before = git_status(repo)
        candidates = find_candidates(repo, tracked)
        ignore_findings = public_ignore_findings(repo)
        moved = apply_migration(repo, sidecar, candidates) if args.apply else []
        after = git_status(repo)
        report = {
            "repository": str(repo),
            "sidecar": str(sidecar),
            "mode": "apply" if args.apply else "audit",
            "candidates": [asdict(candidate) for candidate in candidates],
            "moved": moved,
            "public_ignore_findings": ignore_findings,
            "git_status_before": before,
            "git_status_after": after,
            "history_rewritten": False,
        }
        if args.apply:
            (sidecar / "migration-report.json").write_text(
                json.dumps(report, indent=2) + "\n", encoding="utf-8"
            )
        if args.json:
            print(json.dumps(report, indent=2))
        else:
            print(f"Repository: {repo}")
            print(f"Sidecar: {sidecar}")
            print(f"Mode: {report['mode']}")
            for candidate in candidates:
                print(f"{candidate.classification.upper()}: {candidate.path} - {candidate.reason}")
            for finding in ignore_findings:
                print(f"PUBLIC IGNORE: {finding}")
            print(f"Moved: {len(moved)}")
            print(f"Git status changed: {before != after}")
            print("History rewritten: no")
        return 0
    except (OSError, subprocess.CalledProcessError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
