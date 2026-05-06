#!/usr/bin/env bash
#
# conductor_for_codex.sh
#
# Installer for Codex + Conductor skills.
# Non-destructive by default:
# - Does NOT delete files.
# - Does NOT overwrite existing files/folders.
#
# With FORCE_REFRESH=1: removes and re-copies all conductor skill folders.
# With PROPAGATE_ALL=1: after global install, also updates all repos under
#   GITHUB_REPOS_DIR that have a .codex/skills/ folder.
#
# Installs into your HOME by default (no sudo):
#   $HOME/.codex/skills/<skill>/SKILL.md
# Installs a global init command (if missing):
#   $HOME/.local/bin/codex_conductor_init
#
# Transparency note:
# - Skill markdown content is copied from plain files in ./skills.
# - No base64 payloads are used for skill installation.
#
# Override paths via env vars:
#   CODEX_HOME=/custom/.codex BIN_DIR=/custom/bin bash ./conductor_for_codex.sh
#   FORCE_REFRESH=1 PROPAGATE_ALL=1 bash ./conductor_for_codex.sh
#
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
NO_PATH_HINT="${NO_PATH_HINT:-0}"
FORCE_REFRESH="${FORCE_REFRESH:-0}"
PROPAGATE_ALL="${PROPAGATE_ALL:-0}"
GITHUB_REPOS_DIR="${GITHUB_REPOS_DIR:-$HOME/Documents/programming/github_repos}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLED_SKILLS_ROOT="$SCRIPT_DIR/skills"
BUNDLED_TEMPLATES_ROOT="$SCRIPT_DIR/templates"

echo "==========================================="
echo "  Conductor for Codex - Installer (Linux)"
echo "==========================================="
echo ""

if [[ ! -d "$BUNDLED_SKILLS_ROOT" ]]; then
  echo "Missing bundled skills directory: $BUNDLED_SKILLS_ROOT"
  exit 1
fi

mkdir -p "$CODEX_HOME/skills" "$BIN_DIR"

SKILL_NAMES=(conductor-setup conductor-status conductor-implement conductor-newTrack conductor-revert conductor-review conductor-update)

# Install skills one-by-one
for s in "${SKILL_NAMES[@]}"; do
  src_file="$BUNDLED_SKILLS_ROOT/$s/SKILL.md"
  dst_dir="$CODEX_HOME/skills/$s"
  dst_file="$dst_dir/SKILL.md"

  if [[ ! -f "$src_file" ]]; then
    echo "Missing bundled skill file: $src_file"
    exit 1
  fi

  if [[ -e "$dst_dir" ]]; then
    if [[ "$FORCE_REFRESH" == "1" ]]; then
      rm -rf "$dst_dir"
      echo "  Removed (force-refresh): $dst_dir"
    else
      echo "  Exists, skipping: $dst_dir"
      continue
    fi
  fi

  mkdir -p "$dst_dir"
  cp -a "$src_file" "$dst_file"
  echo "  Installed: $dst_dir"
done

# Install templates
if [[ -d "$BUNDLED_TEMPLATES_ROOT" ]]; then
  if [[ -e "$CODEX_HOME/conductor/templates" ]] && [[ "$FORCE_REFRESH" == "1" ]]; then
    rm -rf "$CODEX_HOME/conductor/templates"
    echo "  Removed (force-refresh): $CODEX_HOME/conductor/templates"
  fi
  if [[ -e "$CODEX_HOME/conductor/templates" ]]; then
    echo "  Exists, skipping templates: $CODEX_HOME/conductor/templates"
  else
    mkdir -p "$CODEX_HOME/conductor/templates"
    cp -a "$BUNDLED_TEMPLATES_ROOT"/. "$CODEX_HOME/conductor/templates/"
    echo "  Installed templates: $CODEX_HOME/conductor/templates"
  fi
else
  echo "  Missing bundled templates directory (skipping): $BUNDLED_TEMPLATES_ROOT"
fi

# Install init command only if missing
if [[ -e "$BIN_DIR/codex_conductor_init" ]]; then
  echo "  Exists, skipping: $BIN_DIR/codex_conductor_init"
else
  cat >"$BIN_DIR/codex_conductor_init" <<'INIT_EOF'
#!/usr/bin/env bash
# codex_conductor_init
#
# Non-destructive by default:
# - Does NOT delete files.
# - Does NOT overwrite existing files/folders.
#
# Usage:
#   codex_conductor_init            # initializes current directory
#   codex_conductor_init /path/to/repo
#
set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

skill_names=(conductor-setup conductor-status conductor-implement conductor-newTrack conductor-revert conductor-review conductor-update)

mkdir -p "$REPO_ROOT/.codex/skills"

for s in "${skill_names[@]}"; do
  src="$CODEX_HOME/skills/$s"
  dst="$REPO_ROOT/.codex/skills/$s"
  [[ -d "$src" ]] || { echo "Missing installed skill: $src"; exit 1; }
  if [[ -e "$dst" ]]; then
    echo "  Exists, skipping: .codex/skills/$s"
    continue
  fi
  cp -a "$src" "$dst"
  echo "  Installed: .codex/skills/$s"
done

# Install Conductor templates (non-destructive)
if [[ -d "$CODEX_HOME/conductor/templates" ]]; then
  if [[ -e "$REPO_ROOT/conductor/templates" ]]; then
    echo "  Exists, skipping: conductor/templates"
  else
    mkdir -p "$REPO_ROOT/conductor/templates"
    cp -a "$CODEX_HOME/conductor/templates"/. "$REPO_ROOT/conductor/templates/"
    echo "  Installed: conductor/templates"
  fi
else
  echo "  NOTE: Missing templates at $CODEX_HOME/conductor/templates (re-run conductor_for_codex.sh)"
fi

rule_line='Always run $conductor-status before doing anything else.'
if [[ -e "$REPO_ROOT/AGENTS.md" ]]; then
  if command -v grep >/dev/null 2>&1; then
    if ! grep -Fxq "$rule_line" "$REPO_ROOT/AGENTS.md"; then
      echo "$rule_line" >>"$REPO_ROOT/AGENTS.md"
    fi
  else
    echo "$rule_line" >>"$REPO_ROOT/AGENTS.md" || true
  fi
  echo "  Ensured AGENTS.md contains conductor-status rule"
else
  printf '# AGENTS.md\n\nAlways run $conductor-status before doing anything else.\n' >"$REPO_ROOT/AGENTS.md"
  echo "  Created AGENTS.md"
fi

# Ensure conductor/ ignore exists
if [[ ! -f "$REPO_ROOT/.gitignore" ]]; then
  echo "conductor/" >"$REPO_ROOT/.gitignore"
elif command -v grep >/dev/null 2>&1; then
  if ! grep -qx "conductor/" "$REPO_ROOT/.gitignore"; then
    echo "conductor/" >>"$REPO_ROOT/.gitignore"
  fi
else
  echo "conductor/" >>"$REPO_ROOT/.gitignore" || true
fi

echo "  Ensured .gitignore contains conductor/"
INIT_EOF
  chmod +x "$BIN_DIR/codex_conductor_init"
  echo "  Created: $BIN_DIR/codex_conductor_init"
fi

if [[ "$NO_PATH_HINT" != "1" ]]; then
  case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *) echo "  NOTE: Add $BIN_DIR to PATH to run codex_conductor_init from anywhere." ;;
  esac
fi

echo ""
echo "Run in any repo directory:"
echo "  codex_conductor_init"

# --- PropagateAll: push conductor skills to all repos that already have .codex/skills/ ---
if [[ "$PROPAGATE_ALL" == "1" ]]; then
  echo ""
  echo "==========================================="
  echo "  PropagateAll: Updating repo-local skills"
  echo "==========================================="

  if [[ ! -d "$GITHUB_REPOS_DIR" ]]; then
    echo "  WARNING: GITHUB_REPOS_DIR not found: $GITHUB_REPOS_DIR"
    echo "  Set GITHUB_REPOS_DIR=/path/to/repos to specify the correct path."
  else
    global_skills="$CODEX_HOME/skills"
    updated=0

    for repo in "$GITHUB_REPOS_DIR"/*/; do
      repo_skills="$repo/.codex/skills"
      [[ -d "$repo_skills" ]] || continue

      repo_name="$(basename "$repo")"
      echo ""
      echo "  Repo: $repo_name"

      for s in "${SKILL_NAMES[@]}"; do
        src="$global_skills/$s"
        dst="$repo_skills/$s"
        [[ -d "$src" ]] || { echo "    WARNING: Global skill missing: $s"; continue; }

        if [[ -e "$dst" ]]; then
          rm -rf "$dst"
          echo "    Refreshed: .codex/skills/$s"
        else
          echo "    Added:     .codex/skills/$s"
        fi
        cp -a "$src" "$dst"
      done

      updated=$((updated + 1))
    done

    # Hash verification for key skills
    echo ""
    echo "  Hash verification:"
    for skill in conductor-implement conductor-review conductor-update; do
      skill_file="$global_skills/$skill/SKILL.md"
      if [[ -f "$skill_file" ]]; then
        hash_val=$(sha256sum "$skill_file" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$skill_file" | awk '{print $1}')
        echo "    Global $skill: $hash_val"
      fi
    done

    echo ""
    echo "  Propagation complete: $updated repos updated."
  fi
fi
