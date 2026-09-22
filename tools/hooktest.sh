#!/bin/sh
# Drive every hook in .claude/hooks/ with a payload and assert its exit code.
#
# A hook that stops firing fails silently: the guard it enforces just goes
# away, and nothing notices until something frozen has been edited. Each case
# below is one rule from CLAUDE.md, with the payload the harness would send.
#
# 0 = the hook renders no decision and the call proceeds.
# 2 = the hook blocks and hands its stderr to the model.
#
# `mise run docs` runs this, and so does CI.

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
CLAUDE_PROJECT_DIR=$root
export CLAUDE_PROJECT_DIR
# The frozen branch is tested without docs/specs/.frozen existing.
SPECS_FROZEN=1
export SPECS_FROZEN

pass=0
fail=0

case_() {
    hook=$1; want=$2; name=$3; payload=$4
    printf '%s' "$payload" | sh ".claude/hooks/$hook" >/dev/null 2>&1 && got=0 || got=$?
    if [ "$got" = "$want" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf 'FAIL  %-24s %s\n  wanted exit %s, got %s\n' "$hook" "$name" "$want" "$got" >&2
    fi
}

read_payload() {
    printf '{"tool_name":"Read","tool_input":{"file_path":"%s"%s}}' "$1" "$2"
}
write_payload() {
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1"
}
bash_payload() {
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"
}

# --- the read guard: a specification is never loaded whole ------------------
case_ guard-spec-reads.sh 2 "unbounded read of a spec"   "$(read_payload docs/specs/model.md '')"
case_ guard-spec-reads.sh 0 "bounded read of a spec"     "$(read_payload docs/specs/model.md ',"limit":200')"
case_ guard-spec-reads.sh 2 "limit over the cap"         "$(read_payload docs/specs/benchmark.md ',"limit":9000')"
case_ guard-spec-reads.sh 0 "the plan is not guarded"    "$(read_payload docs/PLAN.md '')"

# --- the frozen-write guard -------------------------------------------------
case_ guard-frozen-writes.sh 2 "write to a spec"         "$(write_payload docs/specs/model.md)"
case_ guard-frozen-writes.sh 2 "write to .gitattributes" "$(write_payload .gitattributes)"
case_ guard-frozen-writes.sh 0 "write to STATE.md"       "$(write_payload docs/STATE.md)"
case_ guard-frozen-writes.sh 0 "write to a decision"     "$(write_payload docs/decisions/0006-x.md)"

# --- the shell guard: refusals ----------------------------------------------
case_ guard-bash.sh 2 "bare lua5.1"           "$(bash_payload 'lua5.1 tools/harness.lua')"
case_ guard-bash.sh 2 "bare lua"              "$(bash_payload 'lua x.lua')"
case_ guard-bash.sh 0 "lua through mise"      "$(bash_payload 'mise exec -- lua5.1 tools/harness.lua')"
case_ guard-bash.sh 0 "a mise task"           "$(bash_payload 'mise run check')"
# The lua refusal matches the interpreter, not every command starting "lua".
case_ guard-bash.sh 0 "lua-language-server"   "$(bash_payload 'lua-language-server --check .')"
case_ guard-bash.sh 2 "sed -i"                "$(bash_payload 'sed -i s/a/b/ f.txt')"
case_ guard-bash.sh 2 "grep -P"               "$(bash_payload 'grep -P \\d f.txt')"
case_ guard-bash.sh 2 "readlink -f"           "$(bash_payload 'readlink -f .')"
case_ guard-bash.sh 2 "merge without ff-only" "$(bash_payload 'git merge feature')"
case_ guard-bash.sh 0 "merge --ff-only"       "$(bash_payload 'git merge --ff-only feature')"
case_ guard-bash.sh 2 "push --force"          "$(bash_payload 'git push --force origin topic')"
case_ guard-bash.sh 2 "rm a spec"             "$(bash_payload 'rm docs/specs/model.md')"
case_ guard-bash.sh 2 "redirect into a spec"  "$(bash_payload 'echo x > docs/specs/captures.md')"
case_ guard-bash.sh 2 "redirect into model/"  "$(bash_payload 'echo x > model/sym/a.yaml')"
case_ guard-bash.sh 2 "rm under observations" "$(bash_payload 'rm observations/r1.jsonl')"
case_ guard-bash.sh 0 "read under model/"     "$(bash_payload 'cat model/sym/a.yaml')"
case_ guard-bash.sh 2 "git add a .res"        "$(bash_payload 'git add captures/x.res')"
case_ guard-bash.sh 0 "git add -A"            "$(bash_payload 'git add -A')"
case_ guard-bash.sh 0 "git add by name"       "$(bash_payload 'git add docs/STATE.md')"
case_ guard-bash.sh 2 "PR body, no headings"  "$(bash_payload 'gh pr create --body words')"
case_ guard-bash.sh 0 "git status"            "$(bash_payload 'git status')"
case_ guard-bash.sh 0 "a Read of anything"    "$(read_payload docs/specs/model.md '')"

# --- the commit-message check -----------------------------------------------
case_ postcommit.sh 0 "not a commit command"  "$(bash_payload 'git log -1')"

if [ "$fail" -ne 0 ]; then
    printf '\nhooks: %d passed, %d failed\n' "$pass" "$fail" >&2
    exit 1
fi
printf 'hooks: %d checks, all passed\n' "$pass"
