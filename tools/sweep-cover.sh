#!/bin/sh
# Hold docs/mutations.md to the rows docs/PLAN.md claims a mutation for.
#
# A control the plan names and nobody wrote down moves neither side of the
# sweep's coverage line: the sweep cannot see it, and the coverage figure
# quietly excludes it. So this compares the plan with the inventory: every green plan row
# whose done-condition names a mutation owes an entry, and every entry names
# a row that exists.
#
# Which rows are green comes from the gates, never from the plan's prose:
# `mise run verify -- --status` prints one line per registered gate. Before
# the verify runner exists nothing is green, nothing is owed, and the check
# passes on an empty inventory, which is the truth.
#
# --root points both reads at a sandbox, which is how the sweep test proves
# this refuses.
#
# No toolchain, so it runs inside `mise run check` and in CI's preflight job.

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
if [ "$1" = --root ] && [ -n "$2" ]; then
    root=$(CDPATH= cd -- "$2" && pwd -P)
fi
plan="$root/docs/PLAN.md"
inventory="$root/docs/mutations.md"

for f in "$plan" "$inventory"; do
    [ -f "$f" ] || { printf 'sweep-cover: missing %s\n' "$f" >&2; exit 2; }
done

# The plan's ids, matched by character classes rather than spelled, because
# spelling one here would redden tools/nospecrefs.sh.
ID='[0-9A-Z][0-9A-Za-z.′-]*'

# Every task row whose done-condition names a mutation: id only. The row is
# matched whole rather than by column, because a cell can carry an escaped
# pipe inside backticks.
naming() {
    awk -v id="$ID" '
        /^\| id \| task \| done when \| needs \| runs on \|/ { intable = 1; next }
        !/^\|/ { intable = 0; next }
        !intable { next }
        $0 !~ ("^\\|[ \t]*" id "[ \t]*\\|") { next }
        /mutations?:/ {
            row = $0
            sub(/^\|[ \t]*/, "", row)
            sub(/[ \t]*\|.*$/, "", row)
            print row
        }
    ' "$plan" | sort -u
}

# The rows the gates say are green. A sandbox may supply its own list in
# a file called status, one `<id><TAB>green` per line, to drive the cases.
green() {
    if [ -f "$root/status" ]; then
        awk -F '\t' '$2 == "green" { print $1 }' "$root/status"
    elif grep -q '^\[tasks\.verify\]' "$root/mise.toml" 2>/dev/null; then
        (cd "$root" && mise run verify -- --status 2>/dev/null) \
            | awk -F '\t' '$2 == "green" { print $1 }' || true
    fi
}

named=$(naming)
owed=$(green | grep -xF "$(printf '%s\n' "$named")" 2>/dev/null || true)

written=$(awk -v id="$ID" '
    $0 ~ ("^- task:[ \t]+" id "[ \t]*$") { print $3 }
' "$inventory" | sort -u)

fail=0

missing=$(printf '%s\n' "$owed" | grep -vxF "$(printf '%s\n' "$written")" 2>/dev/null || true)
for m in $missing; do
    [ -n "$m" ] || continue
    printf 'sweep-cover: row %s is green and names a mutation, and docs/mutations.md has no entry for it\n' "$m" >&2
    fail=1
done

stray=$(printf '%s\n' "$written" | grep -vxF "$(printf '%s\n' "$named")" 2>/dev/null || true)
for s in $stray; do
    [ -n "$s" ] || continue
    printf 'sweep-cover: docs/mutations.md names row %s, which names no mutation in docs/PLAN.md\n' "$s" >&2
    fail=1
done

if [ "$fail" -ne 0 ]; then
    printf '\nAdd the entry to docs/mutations.md in the same pull request as the control, or\n' >&2
    printf 'say in docs/PLAN.md why the row names no mutation.\n' >&2
    exit 1
fi

o=$(printf '%s\n' "$owed" | grep -c . || true)
n=$(printf '%s\n' "$named" | grep -c . || true)
printf 'sweep-cover: %s green rows owe an entry, %s have one; %s rows name a mutation in all\n' "$o" "$o" "$n"
