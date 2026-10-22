#!/usr/bin/env bash
# governed-files.sh BASE HEAD OWNERS_FILE PATHS_FILE
#
# Fails if any non-merge commit in BASE..HEAD changes a governed path and is not
# authored by an owner. This enforces CODEOWNERS-style protection for the no-PR
# workflow, where agents push to dev directly.
#
#   OWNERS_FILE: one author email per line (# comments allowed)
#   PATHS_FILE:  one path per line, as in CODEOWNERS ("/AGENTS.md", "/.github/")
set -euo pipefail
base="$1"; head="$2"; owners_file="$3"; paths_file="$4"

mapfile -t owners < <(grep -vE '^\s*(#|$)' "$owners_file" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]//g')
mapfile -t paths < <(grep -vE '^\s*(#|$)' "$paths_file" | awk '{print $1}' | sed 's#^/##')
[ "${#owners[@]}" -gt 0 ] || { echo "no owners configured" >&2; exit 2; }
[ "${#paths[@]}" -gt 0 ] || { echo "no governed paths configured" >&2; exit 2; }

if ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  echo "base $base not available; checking only $head"
  range="$head^!"
else
  range="$base..$head"
fi

violations=0
while IFS=$'\t' read -r sha email subject; do
  [ -n "$sha" ] || continue
  email_l="$(printf '%s' "$email" | tr '[:upper:]' '[:lower:]')"
  ok=0; for o in "${owners[@]}"; do [ "$email_l" = "$o" ] && ok=1; done
  if [ "$ok" -eq 0 ]; then
    files="$(git diff-tree --no-commit-id --name-only -r "$sha" -- "${paths[@]}" | tr '\n' ' ')"
    echo "::error::$sha by $email changes governed files: $files($subject)"
    violations=$((violations + 1))
  fi
done < <(git log --no-merges --format='%H%x09%ae%x09%s' $range -- "${paths[@]}")

if [ "$violations" -gt 0 ]; then
  echo "$violations commit(s) changed governed files without an owner. Revert them, or have an owner make the change."
  exit 1
fi
echo "governed files: ok"
