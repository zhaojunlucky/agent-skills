#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"
SETUP_SCRIPT="$REPO_ROOT/scripts/setup-hook.sh"
MARKER="veda-agent-skills-hook"

installed=0
skipped=0
failed=0

install_hook() {
  local hook_name="$1"
  local hook_path="$HOOKS_DIR/$hook_name"

  if [ -e "$hook_path" ] && ! grep -q "$MARKER" "$hook_path"; then
    printf 'skip: .git/hooks/%s already exists and is not managed by this repo\n' "$hook_name" >&2
    skipped=$((skipped + 1))
    return 0
  fi

  if ! cat > "$hook_path" <<EOF
#!/usr/bin/env bash
# $MARKER
"$SETUP_SCRIPT"
EOF
  then
    printf 'error: failed to write .git/hooks/%s\n' "$hook_name" >&2
    failed=$((failed + 1))
    return 0
  fi

  if ! chmod +x "$hook_path"; then
    printf 'error: failed to make .git/hooks/%s executable\n' "$hook_name" >&2
    failed=$((failed + 1))
    return 0
  fi

  installed=$((installed + 1))
}

if [ ! -d "$HOOKS_DIR" ]; then
  printf 'error: git hooks directory not found: %s\n' "$HOOKS_DIR" >&2
  exit 1
fi

if ! chmod +x "$SETUP_SCRIPT"; then
  printf 'error: failed to make setup script executable: %s\n' "$SETUP_SCRIPT" >&2
  exit 1
fi
install_hook post-merge
install_hook post-rewrite

printf 'hooks: installed=%d skipped=%d failed=%d\n' "$installed" "$skipped" "$failed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi

if [ "$skipped" -gt 0 ]; then
  exit 2
fi
