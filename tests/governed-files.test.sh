#!/usr/bin/env bash
# Tests for scripts/governed-files.sh. Run: bash tests/governed-files.test.sh
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"; gf="$here/scripts/governed-files.sh"
t="$(mktemp -d)"; cd "$t"; fails=0
printf 'owner@x.nz\n' > owners; printf '/AGENTS.md  @o\n/.github/   @o\n' > paths
git init -q repo && cd repo
commit() { git -c user.email="$1" -c user.name=n commit -qm "$2"; }
echo x > README && git add . && commit owner@x.nz init; base="$(git rev-parse HEAD)"
expect() { local want="$1"; shift; "$@" >/dev/null 2>&1; local got=$?; [ "$got" -eq "$want" ] && echo "ok   $*" || { echo "FAIL want $want got $got: $*"; fails=1; }; }
echo a > app.js && git add . && commit agent@x.nz "feat: app"
expect 0 "$gf" "$base" HEAD ../owners ../paths
mkdir .github && echo y > .github/ci.yml && git add . && commit agent@x.nz "ci: change"
expect 1 "$gf" "$base" HEAD ../owners ../paths
b2="$(git rev-parse HEAD)"; echo z > AGENTS.md && git add . && commit OWNER@x.nz "docs"
expect 0 "$gf" "$b2" HEAD ../owners ../paths
expect 0 "$gf" 0000000000000000000000000000000000000000 HEAD ../owners ../paths
exit $fails
