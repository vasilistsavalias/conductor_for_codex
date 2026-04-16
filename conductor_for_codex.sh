#!/usr/bin/env bash
#
# conductor_for_codex.sh
#
# Offline installer for Codex + Conductor skills (no network).
# Non-destructive by default:
# - Does NOT delete files.
# - Does NOT overwrite existing files/folders.
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
#
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
NO_PATH_HINT="${NO_PATH_HINT:-0}"

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

# Install skills one-by-one (skip if destination exists)
for s in conductor-setup conductor-status conductor-implement conductor-newTrack conductor-review conductor-revert update-conductor; do
  src_file="$BUNDLED_SKILLS_ROOT/$s/SKILL.md"
  dst_dir="$CODEX_HOME/skills/$s"
  dst_file="$dst_dir/SKILL.md"

  if [[ ! -f "$src_file" ]]; then
    echo "Missing bundled skill file: $src_file"
    exit 1
  fi

  if [[ -e "$dst_dir" ]]; then
    echo "  Exists, skipping: $dst_dir"
  else
    mkdir -p "$dst_dir"
    cp -a "$src_file" "$dst_file"
    echo "  Installed: $dst_dir"
  fi
done

# Install templates (skip if destination exists)
if [[ -d "$BUNDLED_TEMPLATES_ROOT" ]]; then
  if [[ -e "$CODEX_HOME/conductor/templates" ]]; then
    echo "  Exists, skipping templates: $CODEX_HOME/conductor/templates"
  else
    mkdir -p "$CODEX_HOME/conductor/templates"
    cp -a "$BUNDLED_TEMPLATES_ROOT"/. "$CODEX_HOME/conductor/templates/"
    find "$CODEX_HOME/conductor/templates" -name .DS_Store -type f -delete
    echo "  Installed templates: $CODEX_HOME/conductor/templates"
  fi
else
  echo "  Missing bundled templates directory (skipping): $BUNDLED_TEMPLATES_ROOT"
fi

# Install Conductor skill catalog (skip if destination exists)
if [[ -f "$BUNDLED_SKILLS_ROOT/catalog.md" ]]; then
  if [[ -e "$CODEX_HOME/conductor/skills/catalog.md" ]]; then
    echo "  Exists, skipping skill catalog: $CODEX_HOME/conductor/skills/catalog.md"
  else
    mkdir -p "$CODEX_HOME/conductor/skills"
    cp -a "$BUNDLED_SKILLS_ROOT/catalog.md" "$CODEX_HOME/conductor/skills/catalog.md"
    echo "  Installed skill catalog: $CODEX_HOME/conductor/skills/catalog.md"
  fi
else
  echo "  Missing bundled skill catalog (skipping): $BUNDLED_SKILLS_ROOT/catalog.md"
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

skill_names=(conductor-setup conductor-status conductor-implement conductor-newTrack conductor-review conductor-revert update-conductor)

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
    find "$REPO_ROOT/conductor/templates" -name .DS_Store -type f -delete
    echo "  Installed: conductor/templates"
  fi
else
  echo "  NOTE: Missing templates at $CODEX_HOME/conductor/templates (re-run conductor_for_codex.sh)"
fi

# Install Conductor skill catalog (non-destructive)
if [[ -f "$CODEX_HOME/conductor/skills/catalog.md" ]]; then
  if [[ -e "$REPO_ROOT/conductor/skills/catalog.md" ]]; then
    echo "  Exists, skipping: conductor/skills/catalog.md"
  else
    mkdir -p "$REPO_ROOT/conductor/skills"
    cp -a "$CODEX_HOME/conductor/skills/catalog.md" "$REPO_ROOT/conductor/skills/catalog.md"
    echo "  Installed: conductor/skills/catalog.md"
  fi
else
  echo "  NOTE: Missing skill catalog at $CODEX_HOME/conductor/skills/catalog.md (re-run conductor_for_codex.sh)"
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
  cat >"$REPO_ROOT/AGENTS.md" <<'AGENTS_EOF'
# AGENTS.md

Always run $conductor-status before doing anything else.


AGENTS_EOF
  echo "  Created AGENTS.md"
fi

# Ensure conductor/ ignore exists (no duplicates if grep is available)
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
