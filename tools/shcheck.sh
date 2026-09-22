#!/bin/sh
# Every shell script parses as sh.
#
# A script with a syntax error fails the first time it is needed, which is
# usually inside a hook or a gate where the failure reads as something else.
# Parsing them all here puts the failure where it can be read.

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

fail=0
for f in tools/*.sh .claude/hooks/*.sh; do
    [ -f "$f" ] || continue
    if ! out=$(sh -n "$f" 2>&1); then
        printf '%s does not parse as sh:\n%s\n' "$f" "$out" >&2
        fail=1
    fi
done

[ "$fail" -eq 0 ] || exit 1
echo "every shell script parses as sh"
