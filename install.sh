#!/usr/bin/env bash
# Install the skills in this repo into a DSH skill root.
#
#   bash install.sh [link|copy]
#
# link (default) creates a directory junction/symlink per skill, so `git pull`
# updates every installed skill in place. copy makes a real copy instead.
#
# Destination: $DSH_SKILLS_DEST, default ~/.dsh/skills (DSH's own skill root).
# Point it at ~/.agents/skills to share the skills with other harnesses.
#
# Idempotent: re-points existing links; never deletes a real directory.
# DSH watches its skill roots, so installed skills appear without a restart.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_ROOT="${DSH_SKILLS_DEST:-$HOME/.dsh/skills}"
MODE="${1:-link}"

# Upstream's own installer skips these two buckets: `deprecated/` is retired
# skills, and `misc/` is not part of the supported set (its one Claude-Code
# specific skill does not apply to DSH). `in-progress/` IS installed on purpose.
BUCKETS=(engineering productivity in-progress)

is_windows() {
  [[ "${OS:-}" == "Windows_NT" ]] ||
    [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]
}

case "$MODE" in
  link | copy) ;;
  *)
    echo "usage: bash install.sh [link|copy]" >&2
    exit 2
    ;;
esac

mkdir -p "$DEST_ROOT"

linked=0
copied=0
skipped=0

for bucket in "${BUCKETS[@]}"; do
  for src in "$REPO_DIR/skills/$bucket"/*/; do
    [[ -f "$src/SKILL.md" ]] || continue
    name="$(basename "$src")"
    dest="$DEST_ROOT/$name"

    if [[ -e "$dest" && ! -L "$dest" ]]; then
      # A real directory: a previous copy-mode install, or something the user
      # made by hand. Don't guess — leave it alone.
      echo "skip   $name  (real directory already at $dest)"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ "$MODE" == "copy" ]]; then
      rm -rf "$dest"
      cp -R "$src" "$dest"
      echo "copy   $name -> $dest"
      copied=$((copied + 1))
      continue
    fi

    rm -f "$dest" 2>/dev/null || true

    if is_windows; then
      # mklink /J needs no admin rights, and unlike `ln -s` under Git Bash it
      # does not silently degrade into a copy.
      cmd //c mklink //J "$(cygpath -w "$dest")" "$(cygpath -w "$src")" >/dev/null
    else
      ln -sfn "$src" "$dest"
    fi
    echo "link   $name -> $dest"
    linked=$((linked + 1))
  done
done

echo
echo "done: $linked linked, $copied copied, $skipped skipped  (dest: $DEST_ROOT, mode: $MODE)"
echo "DSH picks these up live — no restart needed."
