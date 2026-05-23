#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
AGENTS_DIR="${HOME}/.agents"
TARGET_DIR="$AGENTS_DIR/skills"
STATE_FILE="$AGENTS_DIR/.veda-agent-skill"
STATE_TMP="${STATE_FILE}.tmp"

linked=0
updated=0
unchanged=0
removed=0
skipped=0
conflicts=0

mkdir -p "$TARGET_DIR" || exit 1
: > "$STATE_TMP" || exit 1

is_recorded_target() {
  local target="$1"

  [ -f "$STATE_FILE" ] || return 1
  awk -F '\t' -v target="$target" '$3 == target { found = 1 } END { exit found ? 0 : 1 }' "$STATE_FILE"
}

record_link() {
  local name="$1"
  local source="$2"
  local target="$3"

  printf '%s\t%s\t%s\n' "$name" "$source" "$target" >> "$STATE_TMP"
}

remove_stale_links() {
  [ -f "$STATE_FILE" ] || return 0

  while IFS="$(printf '\t')" read -r name source target; do
    [ -n "${name:-}" ] || continue
    [ -e "$source/SKILL.md" ] && continue

    if [ -L "$target" ]; then
      current_source="$(readlink "$target")"
      if [ "$current_source" = "$source" ]; then
        rm "$target"
        removed=$((removed + 1))
      else
        printf 'conflict: recorded skill %s target points elsewhere: %s\n' "$name" "$target" >&2
        conflicts=$((conflicts + 1))
      fi
    fi
  done < "$STATE_FILE"
}

link_current_skills() {
  if [ ! -d "$SKILLS_DIR" ]; then
    return 0
  fi

  for source in "$SKILLS_DIR"/*; do
    [ -d "$source" ] || continue

    name="$(basename "$source")"
    target="$TARGET_DIR/$name"

    if [ ! -f "$source/SKILL.md" ]; then
      printf 'skip: %s has no SKILL.md\n' "$source" >&2
      skipped=$((skipped + 1))
      continue
    fi

    if [ -L "$target" ]; then
      current_source="$(readlink "$target")"
      if [ "$current_source" = "$source" ]; then
        unchanged=$((unchanged + 1))
      elif is_recorded_target "$target"; then
        ln -sfn "$source" "$target"
        updated=$((updated + 1))
      else
        printf 'conflict: %s already exists as a symlink to %s\n' "$target" "$current_source" >&2
        conflicts=$((conflicts + 1))
        continue
      fi
    elif [ -e "$target" ]; then
      printf 'conflict: %s already exists and is not a symlink\n' "$target" >&2
      conflicts=$((conflicts + 1))
      continue
    else
      ln -s "$source" "$target"
      linked=$((linked + 1))
    fi

    record_link "$name" "$source" "$target"
  done
}

remove_stale_links
link_current_skills
mv "$STATE_TMP" "$STATE_FILE" || exit 1

printf 'skills: linked=%d updated=%d unchanged=%d removed=%d skipped=%d conflicts=%d\n' \
  "$linked" "$updated" "$unchanged" "$removed" "$skipped" "$conflicts"

if [ "$conflicts" -gt 0 ]; then
  exit 2
fi
