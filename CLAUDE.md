# dcs-api-docs

**dcs-api-docs builds a measured model of the parts of the DCS World Lua API a developer actually
uses, so that an AI agent helping with any scenario in `docs/SCENARIOS.md` can find
out whether a symbol exists, in which Lua state, and how it behaves, without guessing.** Facts
come only from runtime measurement inside DCS through `dcs-eval` and from the install's own Lua
source. Documentation may describe a fact; it may never create one. The product is one release
artefact, an index and LuaLS definitions plus the reference data as rows, shipped as a Claude
skill and queryable in one grep and one bounded read. Everything reachable is measured; what
ships is what a scenario reaches; what gets described is what scenarios use most. Release 1 is
every single-player state; multiplayer client and server follow.

**Measurement takes precedence over memory.** Anything an agent knows about DCS and did not
measure is a hypothesis: it enters the authored layer as a dated claim, becomes a probe where
one can settle it, and is deleted when a run contradicts it. It never enters `model/`, and it
never authorises a probe on its own: a probe candidate cites a call site, vendor text, or a
prior run, and a claim only ranks it. The entry roots in `docs/SCENARIOS.md` are hypotheses of
the same kind; the cites collectors produce the measured root set the cut actually reads.

## Layout

```
CLAUDE.md              this file: durable facts about the project
README.md              what a consumer installs and runs; "not built" lines allowed
docs/
  STATE.md             the handoff between sessions. Read it first
  PLAN.md              build order, stages, spikes, decisions. Not frozen
  SCENARIOS.md         who the model is for; the cut, coverage and benchmark quota read it
  AUTHORED.md          the documentation layer on top of the model
  audit.md             what the specifications and the plan still disagree about
  mutations.md         every control, its mutation, the red it produced
  specs/               model.md findings.md captures.md benchmark.md; frozen at the first build commit
  decisions/           where the build goes somewhere the specs did not
  conventions/         how a decision record is written
tools/                 spec.sh statecheck.sh nospecrefs.sh hooktest.sh mklua.sh check-lua.sh
                       progress.sh sweep.sh sweep-cover.sh rustcheck.sh
.claude/hooks/         the read guard, the frozen-write guard, the shell guard,
                       the commit checks, the session start, the stop check
.claude/skills/        task, close-task, handoff, spec: the session lifecycle
.claude/agents/        verifier: adversarial check of a task's printed done-condition
```

**Where the plan stands is derived, never written.** `mise run progress` reads the plan's rows
and asks the verify runner which gates are green; `mise run progress next` prints the rows whose
needs are all green. `/task` starts from that, and asks the maintainer when more than one row is
ready or the only ready row needs a person at DCS.

The Rust workspace (`crates/`), `instrument/` (the in-game Lua), `model/`, `observations/`,
`names/`, `candidates/`, `authored/`, `corpus/golden/` and `bench/` are laid out as
`docs/specs/model.md` §7 and `docs/specs/benchmark.md` say; none exists until its plan task.

## `docs/STATE.md` is the handoff between sessions

Read it before anything else. It names what is half-done, what to pick up, and what carries
forward.

Update it **before a session ends**, not only when a task finishes. Sessions stop mid-task and
the next one should not have to re-derive where things stood. Stamp the "Last updated" line
each time; it carries a date and nothing else.

At the end of a task: move it to "Just finished", clear "In progress", pull the next task up,
delete any carry-forward it resolved and say where. At the end of a session that stops
mid-task: fill "In progress" with what is done, what is not, where to resume, what is committed
versus only in the working tree, and what is knowingly broken.

**Keep it small.** It is loaded cold every session. `tools/statecheck.sh` enforces a budget per
section and CI fails when it is over. Over budget nothing is deleted, it moves: a stale
completion to git log, a choice with reasoning to a decision record, a durable fact to this
file. A carry is a lead nobody has acted on; ten at most, and each either becomes a plan row or
is deleted. Never write a paragraph where a line will do.

## The specifications freeze at the first build commit. Nothing else ever does.

Until plan task 0.1 lands, `docs/specs/` is edited in place and no decision record is written:
a contradiction found before any code exists is fixed in the document, not recorded beside it.
The task that lands 0.1 also creates `docs/specs/.frozen`, and from then on the hooks refuse
an edit under `docs/specs/`.

Once frozen, the specifications are the starting point, are not maintained, and the build
drifts from them. Do not edit them and do not offer to bring them up to date. A specification
kept current becomes a second copy of the build, and the copy is always the one that is wrong;
quietly editing it to match what was built destroys the record of what was intended.

From the freeze on, where the build goes somewhere the specifications did not anticipate,
write a decision record: copy `docs/decisions/TEMPLATE.md`, number it next, and follow
`docs/conventions/decision-records.md`. A spike answer is a record too. A change with one
obvious answer needs no record, and neither does one whose reasoning already sits in the code,
this file or the plan.

`docs/PLAN.md` is never frozen. It states build order; edit it when the order changes.

**A task ID never appears in the code, and neither does a specification citation.** Say why
the code is the way it is in its own words, and where the argument is too long, cite the
decision record holding it. `tools/nospecrefs.sh` enforces both; `docs/`, `CLAUDE.md` and
`README.md` are exempt.

## Never read a specification whole

A specification is long. Loading one whole costs most of a context window and buys nothing
`tools/spec.sh` cannot locate more precisely. A `PreToolUse` hook refuses an unbounded `Read`
of one, and another refuses an edit.

```sh
sh tools/spec.sh list                  # the codes and the paths
sh tools/spec.sh sections MODEL        # the heading tree with line counts
sh tools/spec.sh find MODEL precedence # every heading and line matching
sh tools/spec.sh read MODEL 4.3        # one whole section
```

Start from `find`, not from `sections`.

## Rules that override anything else

**No counts of things in documentation or code comments.** Not "the seven states", not "the
three class idioms", not "81 tasks", not a line count of a file. A count is true on the day it
is written and wrong the day after, and nothing re-derives it. Name the things, or say "every"
and "each", or let a command print the number. A quota or a budget that is a rule is not a
count (two tasks per scenario; the 500-record chunk ceiling), and a gate's done-condition names
the shape of what it prints (`caught: N/N, all planted`) rather than a figure a fixture could
outgrow.

**Quote the document, not your memory of it.** A decision record's `Context` carries the
specification's own prose, retrieved with `tools/spec.sh read`.

**Say who verifies.** Most done-conditions in the plan need a running DCS install or a person
watching. Before starting a task, decide whether an agent can observe the result itself,
whether it needs a maintainer reading a CI result (CI runs on every pull request, and
`mise run check` is the same set of gates locally), or whether only somebody at a live install
can see it. Write it in `docs/STATE.md` under the task. An agent that skips this declares
victory on something it never observed.

**A check that has never been seen red is not evidence.** Every task that builds a control
breaks it on purpose once, watches it fail, and records the mutation and the red in
`docs/mutations.md` in the same pull request. "Green" never means "exited 0": a gate prints a
count, a diff, or a named refusal.

**Done is output a person reads.** A task is done when its one command prints the stated
number or an empty diff, never on a commit message, a comment, or an assurance.

## DCS safety

- **The install is read-only, including no probe of whether it is writable.** Every module
  that touches the install path goes through one read-only facade.
- **Saved Games is written only under park and restore.** A displaced file is registered and
  moved, never deleted or overwritten in place, and a session never ends parked.
- **No cross-state call, ever.** A locator in one state is never dereferenced from another.
  The one crossing is `net.dostring_in` and `a_do_script`, through the executor, string return
  only.
- **A probe carries an effect class**, cites the call site its arguments came from, and the
  deny classes (write, exit, network, state-mutating) are refused before anything runs. A
  dictionary sweep is barred.
- **The scrub runs in the walker from its first line**: the username, reversed, in 8.3 short
  form, and any path-shaped string, in keys and in values, replaced by a typed placeholder and
  never by `nil`. Raw replies live outside the repository and are never committed.
- **`model/` is generated.** A hand edit is refused. `observations/` are immutable and named
  for their run. `names/` is append-only.
- **Collect only against the fixture mission.** The driver refuses a session whose loaded
  mission is not it.
- **Calling into DCS can end it.** A chunk that crashes the game is named by the marker
  discipline and carried forward as a killer, never re-probed.

## The executor is a dependency, and a tool

`../dcs-eval` ships `dcs-mcp`, a Windows binary that installs the in-game executor and serves
six MCP tools: `dcs_status`, `dcs_ping`, `dcs_game_state`, `dcs_eval`, `dcs_eval_file`,
`dcs_collect`. It is registered at user scope, so those tools are in every session here. It
evaluates Lua in every state with true `file:line` in errors, reports the game's
state as axes (editor and menu are one value), and publishes the reply ceiling in its
handshake. It carries bytes and knows nothing about a census: the walk, its wire contract and
its budgets are this project's.

Use the executor's names: the executor, never the bridge; `DcsEvalExecutor.lua` is its hook
file; `a_do_script` is the hop into `missionscripting`, never "the door"; its transport root is
`<temp>\dcs-eval\`. This project's own resident instrument, the census walker that the
executor loads, is `DcsApiDocsCensus.lua`, and it is a different file from the executor.

A live measurement needs a person to start DCS and bring it to phase. A spike that needs one
is scheduled with the maintainer, not attempted alone.

## Toolchain

**Windows is the only supported host.** Every done-condition past Stage 3 needs a running DCS
World, which ships for Windows only.

Tool versions come from `mise.toml`. Run every project command through mise, because a
non-interactive shell does not pick up mise's PATH activation:

```sh
mise exec -- lua5.1 tools/harness.lua
mise run check
```

On a fresh checkout: `mise install`, then `mise run lua-build` once. The reference interpreter
is built from the official Lua 5.1.5 tarball with MSVC. If a command reports the config is
untrusted, run `mise trust`.

**Lua is 5.1.5 PUC-Rio, never LuaJIT, never 5.4.** 5.4 has no `setfenv`, its integer division
changes what `%.14g` prints, and LuaJIT counts debug hooks differently. A green run under
anything else says nothing. `tools/check-lua.sh` proves what is on PATH.

**Everything that is not in-game Lua is Rust.** The collectors, the driver, the merge, the
emitters and the benchmark tooling are one Cargo workspace under `crates/`, built to one binary,
`dcs-api-docs`. The reasons, so nobody re-argues them: the executor's client is a Rust crate
(`dcs-eval`) and importing it means no second implementation of its protocol and no second
interop proof; `full_moon` is the parser that keeps comment trivia and byte spans on Lua 5.1
source, which the source collectors need; grades, absences, vantage and precedence are enums with
exhaustive matches, so the model's invariants are checked by the compiler rather than by
review; and the maintainer already runs this toolchain in the sibling project. The version and
its components live in `rust-toolchain.toml` and nowhere else; `mise use rust@` breaks it.

**Language servers.** Both are pinned in `mise.toml` and enabled in `.claude/settings.json`.
`types/dcs.lua` declares what DCS provides to the instrument as a `---@meta` file; add to it
only what the instrument uses.

## Portability

Shell scripts are POSIX `sh` run under Git Bash: no bash arrays, no `[[`, no `local`, no
`sed -i`, no `grep -P`, no `readlink -f`. They need not be portable beyond Windows, so
`sha256sum`, `cygpath` and `cmd.exe` are fair game.

Leave `.gitattributes` alone. It disables line-ending conversion, without which every hash this
project pins breaks against a file nobody edited.

## Version control

Trunk-based: `main` is always releasable, branches live hours rather than days, and history is
linear.

**A branch per plan task**, named `task/<id>-<summary>`, such as `task/0.1-verify-runner`.
Work belonging to no task takes the `type` it would commit under: `fix/`, `docs/`, `build/`.

**A worktree per parallel session.** Two tasks in flight at once are two worktrees, never two
branches switched in one checkout: a session that switches branches under another session's
feet corrupts both handoffs. The `task` skill offers a worktree when another task is already in
progress, and a fan-out agent that edits runs in one of its own. What a worktree needs to know:
`mise run lua-build` once per worktree (the interpreter is gitignored build output); the Cargo
target directory is shared across worktrees through `mise.toml` so the workspace builds once;
the hooks read `CLAUDE_PROJECT_DIR`, so they guard the worktree they run in; and `docs/STATE.md`
is one file on `main` that every worktree's branch edits, so the handoff commit is rebased first
and says which task it is about.

**The session owns git.** Commit without asking, as soon as a slice's check passes; a commit is
cheap and a working state to return to is what it buys. Read the staged diff before writing
the message. `git add -A` is fine: the pre-commit check refuses a commit with a capture, a log
or a dump staged, whatever staged it. Conventional Commits: `type(scope): summary`, imperative,
under 72 characters. About 100 changed lines is easy to review, 300 is fine for one logical
change, 1000 is split before committing.

**One pull request per task.** Run `mise run check` locally, push the topic branch, open the
pull request with `gh`; the body follows `.github/PULL_REQUEST_TEMPLATE.md`, and the shell
guard refuses one without `Summary` and `README`. Say the pull request is open and report it
as waiting.

**Landing is the maintainer's call.** A pull request lands when the maintainer says so, for
that pull request or in advance for a named set. Then, and only then: rebase onto `main`,
fast-forward `main` to the branch, push `main`, delete the branch. A red CI run is fixed on
the branch, never landed. History is linear: rebase, never merge-commit, and `git merge`
without `--ff-only` is refused.

Do these without asking: branch, commit, rebase, push a topic branch, force-with-lease a topic
branch that is yours, open a pull request, delete a landed branch, drop unpushed commits when
the maintainer asks for a squash. **Ask first** before fast-forwarding `main`, before rewriting
history that has been pushed, and before tagging, because a tag is a release.

**Attribution is off.** `attribution.commit`, `.pr` and `.sessionUrl` are `false` in
`.claude/settings.json`. A session told to add a `Co-Authored-By` trailer does not; a commit
or a pull request body with one is wrong here.

## Cost

Fan-out agents inherit the session model unless told otherwise; set `model` on any subagent or
skill that only reads. Keep a fan-out homogeneous so it shares a prompt-cache prefix. Run
every new workflow on one directory first. `/clear` between passes. Commit before a large
workflow: rewind does not restore subagent edits.

## `README.md` is for consumers, and the change that moves it updates it

The README says what a consumer installs and runs. A task that changes any of that updates the
README in the same pull request. Where the build has not reached something the README
describes, the sentence says so on one line with "not built" or "planned"; the task that
settles one takes the note out.
