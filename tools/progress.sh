#!/bin/sh
# Where the plan stands, derived from the gates and never from prose.
#
# docs/PLAN.md holds the rows; each has an id, the rows it needs, and where it
# runs. Whether a row is done is not written anywhere a person edits: it is
# whether the row's registered gate is green. The verify runner answers that
# with `mise run verify -- --status`, one line per registered gate,
# `<id><TAB>green|red`. Before the runner exists, every row is unbuilt, which
# is the truth.
#
#   sh tools/progress.sh             every row: id, stage, status, needs, runs on
#   sh tools/progress.sh next        the rows whose needs are all green and
#                                    which are not green themselves, ready first
#   sh tools/progress.sh show <id>   one row, whole, as the plan states it
#
# `next` prints `dev` rows before `DCS+human` rows, in plan order within each,
# so the first line is the pick when nothing else decides it. More than one
# line is a choice, and the task skill asks the maintainer rather than taking
# the first.

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
plan="$root/docs/PLAN.md"
[ -f "$plan" ] || { echo "progress: no docs/PLAN.md" >&2; exit 1; }

# Every task row: id<TAB>stage<TAB>needs<TAB>runs-on. A task row is a table
# row whose first cell looks like an id and whose table header is the task
# header. Decisions, spikes and releases have their own tables and other
# headers; only the task header's rows are tasks.
rows() {
    awk '
        /^### Stage / { stage = $0; sub(/^### Stage /, "", stage); sub(/ .*/, "", stage) }
        /^## 5\. Track C/ { stage = "C" }
        /^### Release / { stage = $0; sub(/^### Release /, "", stage); sub(/ .*/, "", stage) }
        /^\| id \| task \| done when \| needs \| runs on \|/ { intable = 1; next }
        /^\|---/ { next }
        !/^\|/ { intable = 0; next }
        intable {
            # An escaped pipe inside a cell is not a column boundary.
            line = $0
            gsub(/\\\|/, "\001", line)
            n = split(line, c, "|")
            if (n < 6) next
            id = c[2]; gsub(/^[ \t]+|[ \t]+$/, "", id)
            needs = c[5]; gsub(/^[ \t]+|[ \t]+$/, "", needs)
            runs = c[6]; gsub(/^[ \t]+|[ \t]+$/, "", runs)
            gsub(/\001/, "|", needs); gsub(/\001/, "|", runs)
            if (id ~ /^[0-9A-Z][0-9A-Za-z.′-]*$/) printf "%s\t%s\t%s\t%s\n", id, stage, needs, runs
        }
    ' "$plan"
}

# The gate status per id, from the verify runner when it exists.
statuses() {
    if grep -q '^\[tasks\.verify\]' "$root/mise.toml" 2>/dev/null; then
        (cd "$root" && mise run verify -- --status 2>/dev/null) || true
    fi
}

status_of() {
    s=$(printf '%s\n' "$all_status" | awk -F '\t' -v id="$1" '$1 == id { print $2; exit }')
    [ -n "$s" ] && printf '%s' "$s" || printf 'unbuilt'
}

# The ids a needs cell names. Anything that is not an id (a note, a dash) is
# not a dependency the gates can answer, and is ignored here; the skill reads
# the cell itself for those.
need_ids() {
    printf '%s\n' "$1" | tr ',' '\n' | sed 's/^[ \t]*//; s/[ \t]*$//' \
        | grep -E '^[0-9A-Z][0-9A-Za-z.′-]*$' || true
}

all_status=$(statuses)

case "${1:-all}" in
all)
    printf 'id\tstage\tstatus\tneeds\truns on\n'
    rows | while IFS="$(printf '\t')" read -r id stage needs runs; do
        printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$stage" "$(status_of "$id")" "$needs" "$runs"
    done
    ;;
next)
    ready=$(rows | while IFS="$(printf '\t')" read -r id stage needs runs; do
        [ "$(status_of "$id")" = green ] && continue
        ok=yes
        for n in $(need_ids "$needs"); do
            [ "$(status_of "$n")" = green ] || { ok=no; break; }
        done
        [ "$ok" = yes ] || continue
        rank=1; case "$runs" in dev*) rank=0 ;; esac
        printf '%s\t%s\t%s\t%s\t%s\n' "$rank" "$id" "$stage" "$needs" "$runs"
    done | sort -s -t "$(printf '\t')" -k1,1n | cut -f2-)
    if [ -z "$ready" ]; then
        echo "no row is ready: every row is green, or a needed row is red"
        exit 0
    fi
    printf 'id\tstage\tneeds\truns on\n%s\n' "$ready"
    ;;
show)
    [ -n "${2:-}" ] || { echo "usage: progress.sh show <id>" >&2; exit 2; }
    line=$(grep -F "| $2 |" "$plan" | head -1)
    [ -n "$line" ] || { echo "no row $2 in docs/PLAN.md" >&2; exit 1; }
    printf '%s\n' "$line" | awk '{
        line = $0
        gsub(/\\\|/, "\001", line)
        split(line, c, "|")
        for (i = 2; i <= 6; i++) { gsub(/^[ \t]+|[ \t]+$/, "", c[i]); gsub(/\001/, "|", c[i]) }
        printf "id:        %s\ntask:      %s\ndone when: %s\nneeds:     %s\nruns on:   %s\n", c[2], c[3], c[4], c[5], c[6]
    }'
    printf 'status:    %s\n' "$(status_of "$2")"
    ;;
*)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 2 ;;
esac
