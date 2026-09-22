# The implementation plan

A rewrite of the DCS World API measuring instrument, into a new, empty repository. The model is
specified in `model.md`; the acceptance instrument in `benchmark.md`; the shapes it must hold in
`findings.md`; the evidence tier and the scrub in `captures.md`. This document plans the
construction of what they specify and redesigns none of it. Where a section number is cited
without a file, it is `model.md`'s.

---

## 0. Granularity

A task is one nameable artefact the specifications require — an instrument piece, a ledger or
ingest contract, a driver piece, a collector, a live session, a model piece, an emitter, a gate, an
authored-layer piece, a benchmark row — and nothing else. What makes it a task is that it has an
interface ingest, merge, the driver or the benchmark depends on, and a check that can be shown red.
Its done-condition is that artefact's own check, so changing how it is built changes no other row.

Where the old plan split a collector into "write the manifest", "write the positive control",
"write the mutation check", this plan has one row, because a manifest, its control and its mutation
are one interface — seen once as a manifest, once as a control, once as a mutation — and cannot be
changed independently. Where it would be tempting
to fold "the collectors" into one row, this plan does not, because every collector's manifest is
its own contract with ingest and its own mutation. A live session is a row because it is one
sitting with one `status` line, and its immutable observation files are the artefact.

Decisions, open questions and standing rules are not rows: they are listed once in §7, §8 and §9,
each with the task that emits or enforces it.

---

## 1. Definition of done

"Done" is never a judgement. It is output a person reads, and "green" never means "exited 0".

### 1.1 A task

A task is done when its one command prints the stated number or an empty diff. Where the task builds
a check, the check must go red under the stated mutation — break it deliberately, and it must fail.
A check that cannot be shown to fail is not evidence and the task is not done. Where a task
forecloses an option, the numbered decision record in §7 is part of its done-condition and
`mise run decisions` must count it.

### 1.2 A stage

A stage is done when every task in it is done and its named stage-level command — `mise run stage:N`
— re-runs every task's check together and prints `tasks: N/N green`. A stage command is a registered
gate of `mise run verify` and stays there for the life of the project.

### 1.3 A release

A release is done when its acceptance criteria pass, and every criterion is a command with a printed
number or diff (§6). A release names what it cannot contain rather than omitting it, and every such
exclusion cites a decision or a spike id that `mise run release:check` finds.

### 1.4 The project

The project is done when the benchmark of `benchmark.md` reports it against an **absolute finish
line**, not against a predecessor instrument. `bench-card` prints the open set's fraction of
consumer questions answered — as a range, with the failure-mode split (`unspellable`, `ceiling`,
`invented`, `wrong`) beside it and the query cost (`greps`, `lines`) printed and never gated — and
gate **GB** holds when the open set's range reaches the finish line **N**.

N is a number, not a delta. The first card the project ever prints is **ungated**: it prints the
open-set range, the sealed set, the controls and the scripted ceiling, and the maintainer records N
against it in the same commit, on the card's own `threshold N` line. Every card after that prints
that line and says whether it is met. From Release 2 on a card also prints its **own predecessor**
beside it, and a fall against the predecessor is a finding the release document carries; it is not
a second gate. Nothing is compared against the prior repository, and there is no baseline column.

`benchmark.md` §9–§10 define the card and this plan defines no second thing.

### 1.5 What "not done" means

Each of these is a task, stage or release that is **not done**, whatever anyone says about it:

- a record under `model/` that was hand-edited — `model/` is generated, and 0.3's hook refuses it;
- a capture or observation tracked before 1.3's scrub control prints every plant caught;
- a run ledgered with `controls` unrun or failed, or a clean run that exercised nothing;
- a collector without a mutation check, or a check that has never been seen red;
- a task closed on prose — a commit message, a comment, an assurance — rather than on its output;
- a green harness run under any interpreter but PUC-Rio Lua 5.1.5 (0.2), which says nothing;
- a release whose exclusion list omits a state, a tree or a tier it did not reach;
- any statement that a state no instrument reached is absent — out of reach is a fact about the
  instrument, and such a state is *untested*;
- a probe run from an authored claim that carries no `cite`, `text` or `external-cite` row of its
  own — a claim ranks a candidate and never authorises one;
- a shipped record whose `ship` names neither a scenario nor an exclusion rule (6.7).

---

## 2. What the plan depends on, and what it assumes

**Depended on, not planned.** `../dcs-eval`, the executor. Its protocol has the operations `ping`
and `eval`, which `dcs-mcp` wraps in the tools registered in every session here. It evaluates Lua in
any state with true `file:line` in errors; it reaches `missionscripting` through `a_do_script`, two
hops, with a string return only; it reports the game's state as **axes** rather than as one phase
word, with editor and menu a single value; it publishes the reply ceiling in its handshake; it
offers no mission hash, only `DCS.getMissionName()`; it names the killer when a chunk crashes DCS,
and it goes dormant. The executor carries bytes and knows nothing about a census; the walk's wire
contract (§9.6) is this project's.

**Decided, not assumed.** The tooling language is **Rust**, with **full_moon** as the Lua parser
(comment trivia, byte spans, Lua 5.1), the **dcs-eval client crate** imported for the executor
protocol, and **mise** as the task runner. The binary is `dcs-api`; project commands are
`mise run <task>`. The in-game instrument stays PUC-Rio Lua 5.1.5 (0.2, **D002**). 0.7 stands the
workspace up and puts build, test, clippy and fmt inside `mise run check`.

**Assumptions**, stated because they could not be looked up under the reading rule:

| # | Assumption | Where it bites |
|---|---|---|
| A1 | A PUC-Rio Lua 5.1.5 interpreter can be built from source or obtained as a binary and pinned by hash into the repository's tooling | 0.2 |
| A4 | The executor's handshake publishes the reply ceiling and the driver can read it, so the driver passes it to the walk as an argument; the loaded mission's **name** is readable inside DCS and its **hash** is taken outside, over the `.miz` file | 1.4, 3.2, 3.4, SP-5 |
| A5 | Saved Games is writable and the instrument may keep a progress file there under a project-owned, registered path | 1.6, 3.1 |
| A6 | DCS writes into Saved Games during any session (logs, tracks, autosaved config) and those paths can be enumerated once and excluded from the restore diff | SP-6, 3.7 |
| A7 | The dedicated-server environment carries the same executor, hook-side, and its writable tree is a Saved Games sibling that the parks register can address | R3.1 |
| A8 | C-function signatures are measurable by some mix of error-text parsing, cited-argument calls and cite-derived names; no document says which yields what | SP-4, 4.3 |
| A9 | The benchmark runner is a Claude Code subagent (`bench-runner`) plus a workflow that drives it, both defined in B.3 and B.10; the maintainer accepts a boundary costing the live pool × D014's repeats in agent sessions | B.10, R2, R3 |
| A10 | Raw executor replies live in a configured directory outside the repository, defaulting to `../dcs-api-captures-local`; nothing in the repository reads it at build time and nothing in this plan reads it at all | 2.4, 6.6 |

---

## 3. Where the specifications disagree, and what this plan does

Most of what the audit found is settled inside the specifications themselves. What remains are the
disagreements a build has to pick between, and this plan picks:

1. **§9.3 has a human launch DCS; §9.4 has the supervisor restart it.** Resolved by **D010**: the
   supervisor restarts on menu-phase runs; on mission configurations it stops and asks for a human
   reload, and each crash there costs one human mission load — which is why killers carry forward
   and why the C-function tier is wall-clock bound.
2. **`benchmark.md` §5.1 has a task declare its state for the quota audit while §5.2 forbids the
   objective naming it.** The declaration lives in the key file's header, which the runner never
   sees; the scenario declaration lives there too (B.5c).

---

## 4. Stages

Column key — **runs on**: `dev` is developer-only; `DCS+human` needs DCS running with a human
present for the in-game setup. Every stage's command is `mise run stage:N`.

### Stage 0 — Foundation

Everything here gates from the first commit. Nothing in a later stage is done until 0.1's runner
counts it.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 0.1 | The verify runner: `mise run verify` runs every registered gate and counts | `mise run verify` prints `gates: N run, 0 red`; a planted always-red gate makes it print `1 red` and exit non-zero | — | dev |
| 0.2 | The Lua 5.1.5 pin: the harness interpreter, hash-committed, and the gate proving it is 5.1 (**D002**) | `mise run lua:pin` prints `Lua 5.1.5 <sha256>` and `5.4-only chunk: rejected`; mutation: point `LUA` at a 5.4 binary → the `goto` chunk parses → red | 0.1 | dev |
| 0.3 | The commit hook: Conventional Commits; refuses `model/**` whose hash is not in `model/.manifest`; refuses any modification or deletion under `observations/`; refuses `*.log`, crash dumps and supervisor zips; refuses edits to a closed row of `runs.yaml`; refuses an edit to `docs/specs/` after the first build commit | `mise run hook:test` plants one violation per rule and prints `refused: N/N`, each naming its rule; mutation: remove one refusal → `N-1/N` | 0.1 | dev |
| 0.4 | The documentation budget gate (**D012**) | `mise run docs:budget` prints `docs: N / M lines`; a commit that exceeds M is refused, not warned | 0.1 | dev |
| 0.5 | The decision-record check over `docs/decisions/`: every record carries a revisit **sentence** in its Consequences, and the `Dnn` → `NNNN` mapping in §7 resolves | `mise run decisions` prints `records: N, missing revisit sentence: 0`; N starts at zero, because decision records begin at the first build commit; mutation: plant a record whose Consequences state no revisit condition → `missing revisit sentence: 1` | 0.1 | dev |
| 0.6 | The install read-only gate: one filesystem facade exposing read calls only, and a static check that every module touching the install path imports only that facade — no write, and no write probe | `mise run install:ro` prints `modules touching install: N, write imports: 0`; mutation: import a write call in one → `1` → red | 0.1 | dev |
| 0.7 | The Rust workspace: crates for the collectors, the driver, merge and the emitters, the `dcs-api` binary, the `dcs-eval` client crate and `full_moon` pinned in `Cargo.lock`, the toolchain pinned in `mise.toml`, and `mise run check` extended to build, test, clippy and fmt | `mise run check` prints `build: ok, tests: T passed, clippy: 0 warnings, fmt: clean`; mutation: plant a `clippy::all` warning → `clippy: 1 warning` → red | 0.1 | dev |

### Stage 1 — Instruments

The Lua side, under 0.2's interpreter only. One resident source, the primitives, and the scrub inside
the walker from its first line. This is the developer tooling that makes every later session fast.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 1.1 | The harness fixture graph: a 5.1.5 state exercising every **collected** step class of §2.2 (`<env>` is reserved by §13 and not collected), every `mechanism` value — `class.lua`, `LuaClass`, `dxgui-module`, a native userdata, a plain metatable — a function `__index`, a frozen table, a shared metatable, a registry root, and planted PII in every token spelling, in keys and in values | `mise run fixture:census` prints `step classes: N/N, all collected, idioms: N/N, pii plants: N, nodes: N`; the node figure becomes the golden node count | 0.2 | dev |
| 1.2 | `DcsApiCensus.lua`: this project's own resident instrument, one source, `HOST` = `hook` or `export`, built once per host, every build loaded by the harness | `mise run instrument:build` prints `hosts: N/N loaded under Lua 5.1.5`; mutation: a 5.4-only token in the source → red | 0.2 | dev |
| 1.3 | The scrub filter in the walker: tokens derived at run start in-state — forwards, reversed, 8.3 short form — plus §10.3's unanchored `ROOTS` regexes (drive-letter, UNC, and a POSIX arm covering `/Users/` and `\Users\`); keys and values; typed placeholders `{redacted: path\|user\|host}`, never `nil`. The plants are each token spelling once in a key and once in a value, with the host placeholder planted beside them and counted on its own line | `mise run scrub:control` prints `planted: N, caught: N/N, nil written: 0, host placeholders: caught`; mutation: disable the reversed arm → `caught: N-2` → red | 1.1, 1.2 | dev |
| 1.4 | `walk`: frontier, identity map, the store as node 0 excluded by identity, budgets clamped, the reply ceiling taken as an **argument** the driver passes in (never read from inside DCS), a body refused whole above it, the record grammar (`node key missing note truncated end`), and the clear verb (**D004** with 1.7) | `mise run walk:golden` prints `nodes: N, frontier: 0, refused-whole: N/N, unaddressable: u, cleared: c, store named by identity: yes` against 1.1's node count and writes `corpus/golden/walk.body`; invoking it with no ceiling prints `refused: no ceiling`; mutation: drop one edge from the fixture → `nodes: N-1` | 1.1, 1.3 | dev |
| 1.5 | `inspect`: `__index` identity, its span where `debug` exists and a `note` where it does not, and the `mutability` probe — a write attempted against the table's own `__newindex`, `frozen` when it errors, the key omitted when it does not; its capture grammar stated in §9.6's shape and versioned with its parser | prints `dispatchers: D, spans: D, frozen: f` with `debug` present and `spans: 0, notes: D` with it removed; mutation: delete the debug-less branch → red | 1.4 | dev |
| 1.6 | `index`: one candidate per round trip on the progress-file path, `B\|<id>` before and `O\|<id>\|<outcome>` after | over K candidates prints `B: K, O: K, unbalanced: 0`; the harness kills the process after a `B\|` → `unbalanced: 1 (<key>)`; mutation: write `O` before the read → the kill leaves `unbalanced: 0` → red | 1.4 | dev |
| 1.7 | `call`: the supervised in-state probe on the progress-file path; refuses a cross-state locator and any candidate without an effect class (**D004**); its capture grammar stated in §9.6's shape and versioned with its parser | prints `probes: P, outcomes: P, refused cross-state: N/N, refused unclassed: N/N`; mutation: remove the in-state guard → the cross-state figure falls short → red | 1.6 | dev |
| 1.8 | `survey`: the offline container load under a sandboxed 5.1.5 environment — `_()` yields `{msgid}`, `module`, `external_profile` and ED's globals stubbed, nothing written; its capture grammar stated in §9.6's shape and versioned with its parser | over a fixture tree prints `files: F, tables: T, msgids: M, msgids stored as strings: 0`; mutation: remove the `_()` recogniser → the last figure rises to `M` → red | 0.2 | dev |

### Stage 2 — Ledger, grammar and ingest

The contracts every collector writes to. Pure Rust; no DCS.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 2.1 | The id grammar — `sym`, `src`, `def`; the state vocabulary including `unplaced`; parser, printer and the §2.3 total order. `src` carries its kind like `def` does: `src <kind> <path>:<span>`. This row is also the authority for the closed vocabularies: the phase vocabulary `menu-or-editor \| mission \| mission-paused \| sim-paused \| loading`, the `scope` shape, and the transport-alias table (`server` ≡ `scripting`; `userhooks`, `userhook`, `zone`, `zones` recorded as measured absences) | `mise run grammar` prints `examples: N/N round-trip` against §2.5's worked cases, `order cases: N/N, phases: declared, aliases: declared, alias absences: declared`; mutation: break JSON-string quoting → a composite key fails to round-trip → red | 0.1 | dev |
| 2.2 | The run ledger `runs.yaml`: §4.1's fields verbatim — `method origin collector role vantage config phase date capture` — plus `status` moving forward only, `scope` derived per collector and read from the body's `end` record for a walk, `controls`, `capture` path and hash, `candidates: {path, hash}` required wherever the manifest declares `reach: index`, `supersedes`, the §13 sandbox-level stamp, and `build` read from `autoupdate.cfg`, never typed | `mise run runs` prints `runs: N, open: M, invalid: 0`; mutation: a `complete` row lacking `controls: {positive: pass, mutation: pass}` → `invalid: 1`; a `reach: index` row lacking `candidates` → `invalid: 1` | 2.1 | dev |
| 2.3 | The collector manifest: schema and loader (`name version method origin needs reach writes scope msgid_aware controls`) | `mise run manifests` prints `collectors: N, without mutation control: 0`; mutation: drop one `controls.mutation` → `1` | 2.1 | dev |
| 2.4 | `ingest`: every row validated against §4.2's shape `{id, f, v, reach, cand}` and against the closed `reach` vocabulary (`walk inspect index cite call survey`); rows validated against the manifest's `writes` and `msgid_aware`; candidate citation required; retired ids refused; the scrub backstop; observations immutable, gzipped above 8 MB (**D003**) | `mise run ingest corpus/golden` prints `rows: N accepted, refused: N/N planted (field-outside-writes, value-from-non-msgid-aware, uncited-candidate, retired-id, unscrubbed-token, reach: guess)`; mutation: remove any one rule → `N-1/N` | 2.2, 2.3, 1.3 | dev |
| 2.5 | `canonicalise` and `names/<chunk>.jsonl`: input is `(previous names, the run's capture edge list)`; pin once, aliases folded as `also_at` with `owner` and `inherits`, retirement rows, byte-identical re-run | over two fixture edge lists (the second with shorter paths) prints `pinned: N, aliased: M, also_at rows: k, retired: r, rerun: identical`; the shared-metatable case pins `gui:.Widget`; the fixture carries one freshly authored `unplaced` record that a later census places, and one retirement; mutation: swap order rules 1 and 2 → it pins `gui:.Button<meta>` → red | 2.1, 1.4 | dev |

### Stage 3 — Driver and sessions

The other half of the developer tooling: the thing that turns a request into a session a human can
run alone or hand to an agent. The stage ends with one real session, because a driver proven only
against a stub is a driver proven against nothing that crashes.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 3.1 | The parks register: displace to a register, restore from it, never delete or overwrite in place; `status` reports an outstanding park | over a fixture Saved Games tree, `park` then `restore` prints `displaced: N, restored: N, diff: empty`; a file removed from the register between the two → `restored: N-1, missing: 1` and red, never silent | 0.3 | dev |
| 3.2 | The fixture mission `census-fixture.miz`: authored in the editor, committed under `*.miz binary`, hashed **outside DCS** over the file; the driver refuses a session unless the name the executor reports matches the fixture's and the file on disk hashes to the committed value | `mise run fixture:miz` prints `name: census-fixture, hash: <sha256>` equal to the committed one; a stub executor reporting another name → `session refused: mission mismatch`; an edited `.miz` → `session refused: mission hash`; SP-5 closes the live half | 3.3, SP-5 | DCS+human to author; dev to check |
| 3.3 | The plan: request → sessions grouped by launch configuration (**D006**) → steps `machine` or `human`; measurement-confirmed steps wait on the measurement, others on an ack recorded as human-attested; run rows `planned` before and closed after; last steps restore and register; a plan ending parked is refused | `mise run plan census --states all` prints the sessions with step kinds; a dry run over a stub executor prints `runs: N closed, human-attested: K, parks outstanding: 0`; mutation: delete the restore step → `plan refused: ends parked` | 2.2, 3.1 | dev |
| 3.4 | The phase model: the driver consumes `dcs_game_state`'s **axes** and projects them onto `{role, phase}` — `role` is `sp`, `mp-client` or `mp-server`; `phase` is `menu-or-editor` (**D005**), `mission`, `mission-paused`, `sim-paused` or `loading`, and nothing else. `multiplayer` is a role and never a phase. The driver also reads the reply ceiling from the handshake here and hands it to the walk. Loading silence of ~15 s tolerated; role and phase stamped on the run row | a scripted sequence with a 15-s silent window prints the `{role, phase}` timeline and `false failures: 0`; a stub reporting a multiplayer axis prints `role: mp-client` with the phase unchanged; mutation: tolerance 5 s → `1` | 3.3 | dev |
| 3.5 | The crash supervisor (`.ps1` + Rust): the killer named from the unbalanced `B\|`, `dcs.log` archived locally and never committed, the run row → `crashed` with `scope.covered`, a hazard row on the parent, resumption planned as a **new** run minus covered minus killer (**D010**) | kill a stub mid-candidate → `crashed: r, covered: k, killer: <key>, resumption: new run, candidates: N-k-1`; mutation: keep the killer in the list → `N-k` → red | 3.3, 1.6 | dev |
| 3.6 | The two paths over one CLI: `dcs-api collect <capability>` for a human, and a Claude Code **skill** that drives the same verbs for an agent. There is no second MCP server. `equivalence` is kept, narrowed: it diffs the CLI path's captures and observations against the skill path's over one capability | `mise run equivalence census --stub` prints `captures diff: 0 bytes, observations diff: 0 rows`; mutation: change the skill path's default budget → non-zero → red | 3.3 | dev |
| 3.7 | The first live session: `parked-standin-sp` end to end against the real executor with a small `walk` of `hook`, on the real Saved Games tree | `dcs-api status` prints `parks outstanding: 0, runs: 1 complete`; the Saved Games diff, excluding SP-6's list, prints empty | 3.1–3.6, 1.4, SP-6 | DCS+human |

### Stage 4 — Runtime collectors and the single-player sessions

Each collector is a pure function `capture → observations/<run>.jsonl` with a manifest, a positive
control and a mutation check, done offline on the golden corpus. Then the live sessions, each one
sitting. The equivalence check of 3.6 is run live once per session on one capability.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 4.1 | The census collector: walk + inspect capture → observations; manifest; `native-userdata` written from the walk's own `type()`; the reference-surface deviation filter of 5.11 applied, so a symbol the declaration already states is emitted as a deviation rather than as a fresh fact; positive control `sym gui:.Widget exists`; mutation "drop one edge" | `mise run collector census corpus/golden` prints `nodes: N, native-userdata: u, deviations: d, controls: positive pass, mutation pass, ingest refused: 0` | 2.4, 1.4, 1.5, 5.11 | dev |
| 4.2 | The tier-2 index collector: candidates only from the closed `from` vocabulary — `cite`, `text`, `external-cite`, `prior-run` — each carrying its row; `tried: {n, found}`; a `nil` result written as a measured absence; killer hazards taken from 3.5 | over a golden progress file prints `tried: n, found: f, absent: n-f, by from: cite/text/external-cite/prior-run, uncited refused: N/N`; mutation: accept an uncited candidate → the refusal figure falls short → red | 2.4, 1.6, 3.5, 5.5, 5.5b | dev |
| 4.3 | The probe collector — the C-function tier's instrument: whatever SP-4 shows yields, written under a manifest whose `writes` names it; effect class required per candidate | over a golden probe capture prints `probed: P, min_arity: a, positional types: t, returns: r, refused unclassed: N/N`; mutation: accept an unclassed candidate → red | 2.4, 1.7, 3.5, C.1, SP-4 | dev |
| 4.4 | `missionscripting` through `a_do_script`: two hops, string return, the body reassembled and verified, refused whole above the inner ceiling SP-3 measured. The walk is **read-only** and therefore runs in the parked census session, not in `unparked-sp` | the golden body through a stub two-hop path → `observations diff vs direct: 0`; an oversize body → `refused: count, limit`; mutation: permit truncation → red | 4.1, SP-3 | dev |
| 4.5 | `export` from both sides: vantage `hook` and vantage `export`, the run row's `vantage`, and the same-object report between the two | two golden captures → `same-object: N, differ: M`; mutation: drop `vantage` → the report cannot pair the runs → red | 4.1, 1.2 | dev |
| 4.6 | Live session A — `parked-standin-sp` at the menu: census of `gui`, `hook`, `config`, `scripting`, each at SP-7's budget | `dcs-api status` prints `runs: N complete, controls: N/N pass, frontier: 0 ×N`; `equivalence census gui` prints `0`; every observation file tracked | 4.1, 3.7, SP-7 | DCS+human |
| 4.7 | Live session B — `parked-standin-sp` with the fixture mission loaded and paused: census of `mission`, `missionscripting` through `a_do_script`, `export` from both sides, and a further run re-censusing `hook` at `mission-paused`, so that §6.8's two-phases-of-one-state rule has a measured case to agree or split on | `dcs-api status` prints `runs: N complete` (`mission`, `missionscripting`, `export/hook`, `export/export`, `hook@mission-paused`), `controls: N/N pass` | 4.4, 4.5, 4.6 | DCS+human |
| 4.8 | Live session C — `unparked-sp`: tier-2 index over every cited candidate on the `mission` dispatcher tables, crashes handled by 3.5 | `dcs-api status` prints `runs: n (complete c, crashed k), candidates: N, covered: N, killers: K`; every candidate cites its source | 4.2, 5.5, 4.7 | DCS+human |

### Stage 5 — Offline collectors, joins and gates

The rows that need no game. They run in parallel with Stage 4's sessions and are the developer work
that fills the calendar while the session chain waits on a human.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 5.1 | The inventory collector: the install's `.lua` files as `src file` records with the install's own casing and hash; ED's `package.path` taken from each state's census | over a fixture install prints `files: F`; mutation: remove one → `F-1`; `install:ro` still prints `write imports: 0` | 0.6, 2.4 | dev |
| 5.2 | The survey collector core: container load → `src data-table` records, `index` signatures, `def shape` with `seen: N of M`, `variants` merged only at a real type boundary | a fixture where `name` is present on most rows → `name.seen: n/m`; the bindings fixture → `variants: v`; mutation: drop the counts → red | 1.8, 2.4 | dev |
| 5.3 | The survey value vocabulary: `{msgid}`, `self`, `{t: function}`, value-class histograms, facets with units, and `key_shape` on composite keys carrying the delimiter, the arity and **per position** its `distinct` count and a `sample`; manifest `msgid_aware: true` | the CLSID fixture → `classes: guid g, bare b, braced-non-guid n`; the composite-key fixture → `key_shape: <delimiter> × <arity>, positions: each with distinct and sample printed`; mutation: drop the per-position block → red | 5.2 | dev |
| 5.4 | The `resolves-to` edge: foreign key by filename and `external_profile`, checked by the target file existing, read-only | a preset fixture with one target missing → `ok: N-1, missing: 1`; mutation: skip the existence check → `ok: N, missing: 0` → red | 5.2, 0.6 | dev |
| 5.5 | The cites collector over **ED's own Lua**: `Scripts/`, `MissionEditor/`, `Config/`, and the trigger scripts inside every `.miz` ED ships under `Mods/campaigns/` and the training missions. Every site as `call` or `read`, `src site` records, `src declaration` records for the enclosing declaration (this row is that kind's only producer), `cites` edges carrying it, `cites.n`, the ≤5-site sample, constructor-shape overloads, and the `from: cite` half of the candidate list 4.2 consumes | over a fixture prints `sites: S (call a, read b), miz scripts: m, declarations: d, constructor shapes: c, candidates: k, uncited: 0`; mutation: disable read sites → `read 0` → red; mutation: skip the `.miz` trigger scripts → `miz scripts: 0` → red | 2.4, 1.8 | dev |
| 5.5b | The external-cites collector over the community exemplars named per scenario in `docs/SCENARIOS.md`: the same site extraction, written with `from: external-cite`, ranked below `cite` and at source rank 0, documentary only — it can never create a symbol and never set a type | over a fixture exemplar tree prints `sites: S, roots touched: r, rank: 0, symbols created: 0, types set: 0`; mutation: let it create a symbol → ingest refuses → red | 5.5 | dev |
| 5.6 | The mechanism collector: a recogniser per `mechanism` value — source fingerprints for `class.lua`, `LuaClass` and `dxgui-module`, `native-userdata` joined from 4.1's `type()`, and `plain-metatable` as the residual — the inspect span match, `inherits` edges with `via` and `hop` (`class.lua` yielding two), `role: module-boilerplate`; an idiom none of them recognises → `{absent: measured}` and a report row | a fixture carrying every idiom plus one unknown → `recognised: N/N, reported: 1, inherits edges: e (class.lua: 2)`; mutation: drop the `LuaClass` fingerprint → `recognised: N-1/N` → red | 5.5, 1.5, 4.1 | dev |
| 5.7 | The vendor-text collector (**D001**): bitmask, union and enum tokens from comment spans, gaps as `reserved`, `def` only, every slot graded `D`; the "not yet measured" absence is never written — the key is simply missing until a probe fills it | fixture span → `def bitmask: b (members m, reserved r), unions: u, sym rows: 0, unmeasured keys written: 0`; mutation: let it write a `sym` → ingest refuses → red | 0.5, 2.4 | dev |
| 5.8 | The enum-tree collector: `wsTypes` banners → a `def enum` tree with `scoped: true`, `levels`, and per-node `sym` back-links across states, grouping graded `D`, values `S`, `member-of` edges | a `wsTypes` fixture with two same-value members in different branches → `nodes: n, levels: l, scoped: true, sym back-links: b (cross-state: x), value collisions within a branch: 0, across branches: 1`; mutation: flatten the tree → `levels: 1, within: 1` → red | 5.7 | dev |
| 5.9 | The alias-class derivation: equal `(suffix, value)` pairs across states → `def alias-class` with a measured basis and `same-value-space` edges | fixture `hook` and `mission` `S_EVENT` sets → `classes: 1, members: M, unequal pairs excluded: 0`; alter one value → `M-1, 1` | 2.4 | dev |
| 5.10 | The `declares` join: a span join between a container load (5.2's `src data-table`) and a census `debug.getinfo` span, emitting `declares` edges on the source record and nothing else. An ambiguous join is reported, never picked | over a fixture with clean joins and one ambiguity prints `declares: d, ambiguous: 1 (reported), picked: 0`; mutation: let it pick the first → `ambiguous: 0` → red | 5.2, 4.1 | dev |
| 5.11 | The reference surface: `authored/reference-surface.yaml` declares once what ED's own definitions state, and this filter classes each census fact as **agreeing**, **deviating** or **unstated**; only deviations and unstated facts become observations, and a deviation carries the declared value beside the measured one | over a fixture declaration and a fixture census prints `declared: D, agreeing: a, deviating: v, unstated: u` with `a + v` accounting for every declared fact; mutation: drop the deviation carry → a deviating row loses the declared value → red | 6.5, 4.1 | dev |
| 5.12 | The root gate over 5.5 and 5.5b's output: `docs/SCENARIOS.md`'s hypothesised entry roots beside the measured root set, per scenario and per state, with call counts — **added** (measured, not listed), **unconfirmed** (listed, no source cites it), **absent** (listed, nothing reaches it, recorded as a measured absence and never removed). It prints both lists and settles nothing by memory; scenario 1's state stays a hypothesis until it prints | `mise run roots` prints per scenario `listed: L, measured: M, added: a, unconfirmed: u, absent: x` and the measured state of every root; mutation: drop a root from the fixture's cites → it moves to `unconfirmed` → red | 5.5, 5.5b | dev |

### Stage 6 — The model

Merge is pure; the writer is deterministic; a hook refuses hand edits; renames are a reviewed event.
The golden corpus makes the whole chain a gate.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 6.1 | The record schema, as code, against the field sets `model.md` §3.6 states per kind: the kind-tagged `sym`, `src` and `def` variants — there is no `edge` kind and no `def tree`, because an edge is a field on the source record and a tree is `def enum` nodes with `scoped: true`, `levels` and `member-of` edges — `kind` the bare discriminator with the measured Lua type in `luatype`, the slot encoding (flow vs block), §5's absence spellings with `unmeasured` unwritable, tri-state `optional`, the §3.4 type expressions, `impl` never `implementation` | `mise run schema` prints `kinds: N/N accepted, planted refusals: N/N (field outside variant, null in v, written unmeasured, nil placeholder, unenumerable spelled absent, value kind outside §11.1's tuple, scrub placeholder verbatim)`; mutation: remove any rule → `N-1/N` | 2.1 | dev |
| 6.2 | `merge`: `(runs, observations, names, authored, precedence) → records`, reading nothing from `model/`. Precedence is a committed table `verify` checks: §4.3's field groups with `value` split into `declared` and `observed`, one ordering each with its rationale, `authored` at rank 100 and `external` at rank 0 throughout, `vendor-text` ranked as a method label under `origin`. Merge never lifts a non-absence into an absence; `varies` is derived, sticky and one-directional; a `{redacted: …}` placeholder reaching merge maps to `{absent: withheld, why}`; the scrub backstop runs here too; two phases of one state agree under one `v` or split as `also`; ties as `lost: tie` on both plus a `CONFLICTS.md` row; a grade per slot (**D015**) | over the golden corpus prints `records: R, groups: G, conflicts: 1 (planted), picked: 0, lifted: 0, varies: v, withheld from placeholder: w, backstop caught: 1, agree: g, also: s, rerun: identical`; mutations: let merge pick → `conflicts: 0` → red; let it lift an `unenumerable` → `lifted: 1` → red; clear a `varies` → red; pass a placeholder through → `backstop caught: 0` → red | 6.1, 2.5, 2.4 | dev |
| 6.3 | The model writer: flat `model/{sym,src,def}/`, chunked by case-folded first segment, the 500-record chunk ceiling with ordinal parts (**D007**), `model/.manifest` for 0.3's hook | `mise run model:write` prints `files: F, max records per file: ≤500, manifest entries: F`; mutation: a chunk one record over the ceiling → two files | 6.2, 0.3 | dev |
| 6.4 | The rename gate: `RENAMES.md`, rename count against a committed threshold (**D011**) | a planted re-pin with no `RENAMES.md` row → `verify` red naming the ids; with the row → green | 6.3, 2.5 | dev |
| 6.5 | The authored layer: `authored/` holds entries, guides, examples, `reference-surface.yaml`, `defs/`, ceilings, overrides and exclusions. An entry requires a basis (run id or decision); may set hazards, a ceiling, an exclusion, an override or a description; may create a `def` with a basis; may not create a `sym` and may not set a type. A **ceiling is earned by totality within its scope**: this row recomputes coverage over the scope and refuses a ceiling the coverage does not support; none is carried | `mise run authored:check` over fixtures prints `accepted: a, refused: N/N (no basis, creates sym, sets type, non-total ceiling), ceilings recomputed: k`; mutation: drop the `sym` guard → `N-1/N`; mutation: accept a partial-coverage ceiling → `N-1/N` | 6.2, 7.5 | dev |
| 6.6 | The golden corpus and `rederive`: `corpus/golden/` captures → observations → merge → write → **every** emitter, byte-for-byte across two builds, inside `verify` | `mise run verify` prints `rederive: C captures, emitters: N/N, determinism: identical`; mutation: a timestamp in an observation → `differs` | 6.3, 4.1, 5.1–5.12, 7.7 | dev |
| 6.7 | The cut: a pure function of 5.12's measured root set and the "meant to be used" signals of `docs/SCENARIOS.md`. Everything is measured; what ships is what a scenario's measured root set reaches. `ship` holds the lowest-numbered scenario id that reaches the record, or the named exclusion rule; `defs` is `-` exactly when `ship` names a rule; the dropped count prints | `mise run cut` prints `records: R, shipped: s, dropped: R-s, by scenario: …, by rule: …, ship unset: 0, defs '-' where ship names a rule: all`; re-run prints `identical`; mutation: let a record ship with `ship` unset → `ship unset: 1` → red | 6.2, 5.12 | dev |

### Stage 7 — Emit and the consumer surface

The emitted artefacts and the skill that ships them, and the query stays one grep and one bounded
read.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 7.1 | The index emitter: the §8 columns in order, grades in `sig` and `ret`, the `ship`/`defs` pair from 6.7, `hazard` before `defs` and `defs` last, `states` from alias-class membership and `same-object`, `trees` from 5.10's `declares`, and grade `x` **computed at emit** by joining the record's scope to the ceiling's scope, because a state-scoped ceiling is stored once on its `def` and the record omits the slot | `mise run emit:index` prints `rows: R = shipped records, columns: as §8, defs last: yes, x computed: n (from c ceilings)`; mutation: append a column after `defs` → red; mutation: read `x` from the record → `x computed: 0` → red | 6.6, 6.7 | dev |
| 7.2 | The defs emitter: LuaLS text with the declaration span and the build it was read at, the ≤5-site sample, flat member sets with `from` and `hop`, module boilerplate filtered by role, overloads as a list, and the authored entry's `summary`, `behavior`, `params`, `returns`, `hazards`, `see_also` and `examples` rendered with its verification marker | `mise run emit:defs` prints `chunks: N, parse errors: 0, entries rendered: e, golden diff: empty`; mutation: emit `_M` → golden diff non-empty | 7.1 | dev |
| 7.3 | The grade-survival gate: every `D`- or `A`-graded slot carries `[D]` or `[A]` inline on the annotation it reaches, and an authored entry that is not fully run-backed carries `[A, unverified]` — the verification state sits beside the grade, never inside it | `mise run verify` prints `graded slots: G, surviving: G, unverified markers: u, surviving: u`; positive control: a fixture def graded `D`, one graded `A`, one `[A, unverified]`; mutation: remove the renderer → `surviving: 0` → red | 7.2, 6.5, 8.5 | dev |
| 7.4 | The uses emitter: every site, `call` or `read`, as `uses/<group>.tsv`, with `from: cite` and `from: external-cite` in their own column and never summed | `mise run emit:uses` prints `rows: U = sites in observations (cite c, external-cite e)` | 7.1, 5.5, 5.5b | dev |
| 7.5 | `dcs-api coverage` and `COVERAGE.md`: "not yet measured" as a query over manifests × run scopes, the absence counts per field, ceilings joined by scope, both denominators, and **per scenario** the reached nodes with a record over reached nodes plus the same absence counts | prints `reached nodes with a record: a/b, install .lua in any run: c/d, per field: unmeasured / measured-absent / ceiling / withheld`, then one line per scenario with its own `a/b` and its own split; mutation: remove one run's `scope` → unmeasured rises by that run's `reached` | 7.1, 5.1, 5.12 | dev |
| 7.6 | The release document and its exclusions check: `states` defined afresh, the query procedure, the C-function ledger line, and every exclusion citing a decision or spike id that exists | `mise run release:check` prints `exclusions: E, uncited: 0`; mutation: an exclusion with no cite → `uncited: 1` | 0.5, 7.5 | dev |
| 7.7 | The reference-data emitter: `generated/data/<table>.tsv` for units, weapons, countries, airbases and liveries, one row per entry, each row carrying its run, source file and build, and a `disagreement` column stating it where the runtime `db`, the `Config/` source and the shipped `.miz` files differ rather than picking; the matching `---@class` shapes go to 7.2's defs with each field's seen count and value class | `mise run emit:data` prints `tables: N/N, rows per table: …, provenance complete: yes, disagreements: d, picked: 0`; two builds from the golden corpus → `byte-identical`; mutation: let it pick a side → `picked: 1` → red | 7.1, 5.2, 5.3 | dev |
| 7.8 | The skill package: the consumer-facing Claude Code skill that ships with a release — 7.6's query procedure as its text, the index, the defs, the uses and the data tables as its files, and nothing that reads the repository. `benchmark.md` §8's tier 0 follows this text literally | `mise run emit:skill` prints `skill: <name>, files: F, bytes: B, procedure steps: s`; a fresh checkout with only the package present answers a fixture question in `greps: 1, lines: ≤ L`; mutation: remove the procedure section → tier 0 falls to zero → red | 7.6, 7.2, 7.4, 7.7 | dev |

### Stage 8 — The authored capability

Machinery only. Descriptions are sparse by design, concentrate on the most-used and most-hazardous
symbols, and are never finished; who writes one, and which, is decided by the maintainer from 8.3's
list, outside this plan.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 8.1 | `authored add`: creates an entry, demands a basis, refuses symbol creation and type setting at the command | adding without a basis prints `refused: basis required`; with one → `added: 1`; mutation: drop the basis demand → red | 6.5 | dev |
| 8.2 | `authored review`: lists entries with basis resolution and drift — a cited run superseded, a described symbol retired or renamed with the ledger row that did it, a symbol whose measured facts changed since the entry's build stamp, an example that has not run on the current build | prints `entries: N, basis unresolved: 0, drifted: k (retired r, superseded s, stale-facts f, example-unrun x)`; mutation: retire a cited symbol → `drifted: k+1` | 8.1 | dev |
| 8.3 | The ranked worklist: most-called from `uses/`, most-hazardous from `hazards`, undescribed first, with the community-cites rank beside the ED-cites rank and the claim ratio per root | `authored worklist` prints the head of the list with every rank; mutation: drop the hazard rank → a known killer leaves the list → red | 7.4, 7.5 | dev |
| 8.4 | The ceilings this project earned: `def ceiling` entries with a run basis, each recomputed by 6.5's totality check, count printed as `k`. None is carried from anywhere | `authored review` lists `ceilings: k, earned: k, carried: 0`; `bench-keys` resolves every `ceiling` need to one | 8.1, 6.5 | dev |
| 8.5 | The entry format and the `verified` computation: the schema of `authored/entries/<state>/<root>.yaml`, the basis kinds (`run` → `A` backed by `M`; `external` → `A` backed by rank-0 `external`; `claim` → `A`, unverified), and `verified` as `yes`/`partial`/`no` computed from them and never typed | `mise run authored:schema` prints `entries: N, verified computed: N, typed verified: 0, refused: N/N (fact with no basis line)`; mutation: allow a typed `verified` → `typed verified: 1` → red | 6.5 | dev |
| 8.6 | The examples runner: `authored/examples/<id-slug>.lua` with a header naming its state and its expected printed output; the harness runs the ones needing no game under 1.8's stub environment, the driver runs the rest in-state as read-only probes under D009's effect classes, and every run is ledgered | `mise run examples` prints `examples: E, stub: s pass, in-state: i pass, never run: n`; mutation: change one example's output → red naming the example | 8.5, 1.7, 1.8 | dev |
| 8.7 | Guides and the reference gate: `authored/guides/<scenario-or-topic>.md`, one per scenario plus cross-cutting topics, every symbol reference in the one fenced link spelling, resolved against the current index, with a section-level basis block | `mise run guides` prints `guides: G, references: R, unresolved: 0, sections without a basis: 0`; mutation: retire a cited id → `unresolved: 1` → red naming the guide | 8.5, 6.4 | dev |
| 8.8 | `authored claims` and the claim-to-probe path: every outstanding claim listed most-cited symbol first; a claim a probe could settle emits a probe candidate that must carry its own `cite`, `text` or `external-cite` row, because a claim ranks and never authorises; when the run lands the basis moves from `claim` to `run` in the same commit as the observation; a claim a run contradicts is deleted | `authored claims` prints `claims: c, probe-able: p, candidates emitted: p, uncited candidates: 0, contradicted since last release: k`; mutation: emit a candidate whose only citation is the claim → `uncited candidates: 1` → red | 8.5, C.1 | dev |

### Stage 9 — The benchmark

`benchmark.md` §10's rows, restated for a project with no predecessor to score. Nothing is carried
from the prior repository: B.0′ writes the task pool here and B.1b′ scores tier 0 against this
project's own releases. Ids are kept where they still mean the same thing so the documents
cross-reference. `mise run stage:9` is `bench-keys`, `bench-tier0`, `bench-regress`,
`bench-tasks --audit` and `claims` together, every commit.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| B.0′ | The task pool, written fresh: at least two tasks per scenario in `docs/SCENARIOS.md`, plus the controls — one whose answer the skill's procedure alone yields, one whose answer no release can hold, one whose answer is stable across every release — each with its `tasks/<slug>.key.tsv` and its needs | `bench-tasks --audit` prints `tasks: T, scenarios with ≥2: N/N, controls: present, no scenario over 25%`; mutation: delete one scenario's second task → `N-1/N` → red | — | dev |
| B.1b′ | `bench-tier0`: the scripted consumer that answers a key from a release with no model, re-pointable at any release | under 10 s; deleting one key path fails it; the per-task tier 0 score prints and becomes that task's difficulty at admission | B.0′, 7.8 | dev |
| B.3 | **Write** the runner prompt, with §7's edits and the report grammar B.4 parses: `CLAIMS` as a TSV of `symbol state citation untested`, `SCRIPT` as exactly one fenced block, every citation a `<path>:<line>` inside the release under test | no `.txt` holds a numbered list; a fixture report parses into `CLAIMS`; a report with a second `SCRIPT` block or a citation outside the release is rejected naming the line | B.0′ | dev |
| B.4 | The verdict engine (§6), against a fixture written for it — one report per verdict plus one malformed | scoring the fixture prints computed beside self-reported counts and their disagreement as a number; the malformed report is rejected, not scored | B.3 | dev |
| B.5a | `bench-keys` | under 1 s; the `unspellable` list prints; a planted bad path fails it | B.4 | dev |
| B.5b | `bench-card` | under 1 s; every number a range; controls on their own line; open and sealed never summed; the `threshold N` line prints on every card; **no Δ column at Release 1**, and from Release 2 on the predecessor column is the release's own predecessor | B.5a | dev |
| B.5c | `bench-tasks --audit` and `--admit`: the key file's header carries state, job and **scenario**; `--audit` checks the state and job quotas and the scenario quota as a further gate; gate 2 is extended to reject an objective naming any of its scenario's roots as well as a leaf of its own key; a task whose state no current release can measure is admitted `held` for a named release, counted toward quotas and excluded from the card as `held: k` | `--audit` prints the state, job and scenario distribution against the quota rules and `held: k`; `--admit` refuses an objective naming a leaf of its own key or one of its scenario's roots, and refuses a task tier 0 scores at 0% or 100%; a breach caused only by a scenario floor prints as a report, not a refusal | B.5b, B.1b′ | dev |
| B.6 | `bench-harvest` with per-state quotas | a draw breaching a quota is refused; the cited-use pointer counts per state are re-derived from `uses/` and printed, with `cite` and `external-cite` counted separately | 7.4, B.5c | dev |
| B.7 | The sealed set — harvested tasks over the untouched surface, never read while tuning. The access rule is mechanical: the sealed keys and reports live under a path `mise run check` refuses to read outside `bench-card`, and opening one is a tracked event | tracked task/key pairs over the named roots; `bench-seal --status` prints `sealed: N, opened: 0`; touched roots print as a delta on the untouched-root denominator this project measured; mutation: read a sealed key from a tuning command → refused, naming the path | B.6 | dev |
| B.8a | `spellings/<release-id>.tsv`, resolved directly against that release's index | every `required` and `expected` need resolves or appears on the printed `unspellable` list with a reason; a planted bad path fails it | 7.1, B.5a | dev |
| B.8b | The lost-needs list, release to release: every need the **predecessor** release spelled either resolves in this one or prints with a reason. At Release 1 the list is empty by construction and the command says so | `bench-lost` prints `needs: n, resolved: r, lost: l` with a reason on every lost row; at Release 1 → `predecessor: none, lost: 0`; mutation: drop a reason → red | B.8a | dev |
| B.9 | `bench-regress`, tier 0 re-pointed at the new release, and the **retired-needs re-check**: a need retired in an earlier release is re-resolved against the current one, and one that resolves again is reported | both under 10 s on a fresh emit; a planted selection change fails regress naming the task and the symbol; `retired re-resolving: k` prints | B.8b, B.1b′ | dev |
| B.10 | The card at a release boundary: the whole live pool at D014's repeats, driven by the `bench-runner` subagent and the workflow that fans it out — tools rooted at the release under test, `bench/`, the specifications and the model sources denied, worktree isolation, the model id pinned per release and recorded on every run row, one fresh agent per `(task, release, repeat)`, `--repeats` mandatory | `bench-card` prints the open set's range with `threshold N`, tier 0's prediction beside the agent result, and from Release 2 the predecessor beside it; `runs` holds one row per `(task, release, repeat)` with the model id on each | B.9, R1 emitted | dev — pool × repeats agent sessions |
| B.11 | The canary: one altered key fact per run in one task in five | every altered run caught as `memorised` | B.10 | dev |
| B.12 | `claims`: every published figure re-derives | every figure re-derives; `n < 3` fails | B.10 | dev |

**GB — the finish line.** The open set's range reaches **N**. The first card prints ungated and N is
recorded against it (§1.4); GB gates from the card after that. **If GB fails**, the worlds that
produce it at Release 1 need different answers:

- **the range sits below N with a wide spread** → three repeats has too little power. Re-run two
  tasks at eight repeats before drawing any conclusion about the artefact.
- **the range sits below N tightly, and tier 0 is above the agents** → the model holds facts the
  consumer cannot find. A findability problem: the index, the skill package or the pointer, not the
  collectors.

---

## 5. Track C — the C-function tier

The largest gap and a priority: most of what a mission-script author uses is C-implemented — a node
in the walk with no source span and no Lua body to read. It is session-bound, so it is wall-clock
bound: no developer effort parallelises it, and it must start as soon as 1.7, 3.5 and C.1 exist —
before merge exists, because observations are the evidence and merge is offline. It runs beside
every stage from 4 onward. Its scope is bounded by the cited candidate list, never by a target
figure; a figure is reported, not aimed at.

**A candidate's citation comes from one of the `from` vocabulary's sources**, in rank order:
`cite` — ED's Lua under the install, including the trigger scripts inside the `.miz` files ED ships
under `Mods/campaigns/` and the training missions; `text` — vendor text at a `src` id;
`external-cite` — the community exemplars named per scenario in `docs/SCENARIOS.md`, ranked below
`cite` and at source rank 0; and `prior-run` — this project's own earlier observation. An authored
claim ranks a candidate and never authorises one, so a claim-derived candidate carries a row of its
own from one of the citing sources.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| C.1 | The probe candidate ledger: every candidate cites its source from the vocabulary above with the cited call's argument shapes copied in or none, an effect class reviewed per candidate, and the deny classes (write, exit, network, state-mutating) refused by the driver (**D009**) | `probe:ledger` prints `candidates: N, cited: N, by from: cite/text/external-cite/prior-run, effect-classed: N, denied: d`; mutation: an uncited candidate → refused | 5.5, 5.5b, 0.5 | dev |
| C.2 | The campaign at Release 1 scope: every `mission` and `scripting` candidate probed, killed or refused, over as many `unparked-sp` sessions as it takes | `probe:status` prints `remaining: 0` for the R1 states, and the C-function ledger line — functions, returns known %, parameters typed % — is in the release document via `claims` | 4.3, C.1, 4.8, SP-4 | DCS+human, wall-clock |
| C.3 | The campaign at Release 2 and 3 scope, for the states each release adds | `probe:status` prints `remaining: 0` for that release's states | C.2, R2.2, R3.2 | DCS+human, wall-clock |

---

## 6. Releases

Release 1, Release 2 and Release 3, each cumulative over the last. Each names what it cannot
contain, citing a decision or spike, and `release:check` refuses an uncited exclusion. A rule across
all of them: **out of reach is a fact about the instrument and never a measured absence** — a state
no instrument reached is untested and the index's role columns hold `-` for it, never an absence
spelling.

### Release 1 — `sp`

Every state, at single-player. Acceptance, every line a command:

| criterion | command prints |
|---|---|
| every gate green | `mise run verify` → `gates: N run, 0 red` |
| every state censused | `mise run runs --by-state` → `states with a complete census: N/N` |
| no session left parked | `dcs-api status` → `parks outstanding: 0` |
| scrub proven, not asserted | `mise run scrub:control` → `caught: N/N, all planted` |
| the walk exhausted each state within budget | `mise run runs --frontier` → `frontier 0: N/N` |
| tier 2 covered its list | `dcs-api status` → `candidates: N, covered: N` |
| the C-function tier covered its list | `probe:status` → `remaining: 0` for `mission`, `scripting` |
| the roots were checked, not assumed | `mise run roots` → per scenario `added`, `unconfirmed`, `absent` |
| the cut is a function, not a judgement | `mise run cut` → `ship unset: 0`, re-run `identical` |
| both denominators printed, and per scenario | `dcs-api coverage` → `a/b`, `c/d`, the per-field split, one line per scenario |
| grades survive | `mise run verify` → `graded slots: G, surviving: G` |
| exclusions cited | `mise run release:check` → `uncited: 0` |
| the finish line is met | `bench-card` → the open-set range, `threshold N`, `GB: holds` |
| figures honest | `claims` → every figure re-derives, none on `n < 3` |

Named exclusions, each cited: the `mp-client` and `mp-server` roles (untested, Releases 2 and 3);
`<env>` (§13, reserved); `Mods/`, `Bazar/`, `DemoMods/` (§13); per-key userdata identity (§13);
`.mo` translations (out of scope); tier 3 outside the supervised probe path (**D004**); any state
whose census `frontier` is not 0, named with its number; any root 5.12 printed as `absent`.

### Release 2 — `+mp-client`

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| SP-2 | Spike: can a hook-resident instrument run under a multiplayer client, or is collection export-resident only (**D013** until it closes) | one run row per vantage attempted, each `complete` or `aborted` with the reason | 4.5, 3.7 | DCS+human |
| R2.1 | The `parked-standin-mp-client` configuration in the plan: the launch steps, the `role: mp-client` stamp, the states the instrument reaches under SP-2's answer, and `-` for the rest | `mise run plan census --role mp-client` prints the session; a dry run closes every run row; unreached states print as `untested`, never absent | 3.3, SP-2 | dev |
| R2.2 | Live session D — `parked-standin-mp-client`: every state SP-2 reached, at the phase each needs | `dcs-api status` prints `runs: n complete, controls: n/n pass`; `equivalence` over one capability prints `0` | R2.1, 4.7 | DCS+human |
| R2.3 | The release: the `mp-client` index column populated from R2.2's runs, the exclusions list extended, the benchmark re-run at the release boundary | R1's table again, plus `runs --by-role mp-client` prints the reached-state count; `bench-lost` prints `lost: l` with a reason on every row against Release 1; and `bench-card` prints the release beside Release 1 over the whole live pool at D014's repeats | R2.2, B.12, C.3 | dev — pool × repeats agent sessions |

### Release 3 — `+mp-server`

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| SP-1 | Spike: which states exist on a dedicated server, and which the instrument reaches | a table with one row per state, each `reached` or `unreached (<reason>)`; unreached rows enter the exclusions as untested | 3.7, A7 | DCS+human |
| R3.1 | The `parked-standin-mp-server` configuration: the server's writable tree under the parks register, the launch and mission-hosting steps, the `role: mp-server` stamp | `mise run plan census --role mp-server` prints the session; `park` then `restore` over the server tree prints `diff: empty` | 3.1, 3.3, SP-1 | dev, then DCS+human for the restore diff |
| R3.2 | Live session E — `parked-standin-mp-server`: every state SP-1 reached, with the fixture mission hosted | `dcs-api status` prints `runs: n complete, controls: n/n pass`; `equivalence` over one capability prints `0` | R3.1, R2.2 | DCS+human |
| R3.3 | The release: the `mp-server` column, the exclusions, the benchmark at the boundary | R1's table again, plus `runs --by-role mp-server`; `bench-lost` against Release 2 with a reason on every lost row; and `bench-card` beside Release 2 over the whole live pool at D014's repeats | R3.2, C.3 | dev — pool × repeats agent sessions |

---

## 7. Decisions this plan emits

A task that forecloses an option emits the record below, with a revisit condition, and
`mise run decisions` counts it as part of that task's done-condition. None is re-litigated by a row.

The `Dnn` ids in this table are **this plan's own**. Decision records live under `docs/decisions/`,
are numbered `NNNN` with a slug, and begin at the first build commit; before that the documents are
corrected in place. This table is the one mapping from a `Dnn` to the record that files it, and 0.5
checks that the mapping resolves.

| id | decision | emitted by | revisit when |
|---|---|---|---|
| D001 | Text ED ships inside the product may write a `def`, graded `D`, never a `sym` | stated in `model.md` §14, enforced by 2.4, 5.7 | a `vendor-text` def is contradicted by a runtime measurement, or a `D` value reaches a consumer ungraded |
| D002 | The harness interpreter is PUC-Rio Lua 5.1.5, hash-pinned; a green under any other says nothing | 0.2 | a census reads a different `_VERSION` in any DCS state |
| D003 | Observations are tracked; raw replies stay outside the repository; a collector-version bump re-collects rather than re-derives | 2.4 | a bump whose re-collection cannot be scheduled inside one release |
| D004 | Tier 3 is barred on the walk and across states. The one carve-out is the supervised in-state probe path: in-state only, supervised, one candidate per round trip, every candidate effect-classed, deny classes refused before anything runs. `pcall` is assumed not to help | 1.4, 1.7 | a build in which `pcall` is measured to catch a dispatcher fault |
| D005 | `menu-or-editor` is one phase value while the executor cannot distinguish them | 3.4 | the executor distinguishes them |
| D006 | The session vocabulary is the launch configurations `unparked-sp`, `parked-standin-sp`, `parked-standin-mp-client` and `parked-standin-mp-server`, and no other | 3.3 | a collection fits none of them |
| D007 | The model chunk ceiling is 500 records, split by ordinal part (§7) | 6.3 | the file count passes 4,000, or a review names a chunk a reader cannot hold |
| D009 | A probe's arguments are copied from a cited call site or are none; every candidate carries a reviewed effect class; write, exit, network and state-mutating classes are denied | C.1 | `remaining: 0` is reached with C-function returns known below a figure the maintainer names — the rule, not the list, is then the bottleneck |
| D010 | The supervisor restarts DCS itself on menu-phase runs only; on mission configurations it stops and asks for a human reload; killers carry forward and are never re-probed | 3.5 | an unattended mission load becomes possible without a cross-state call |
| D011 | The rename threshold starts at zero unexplained renames | 6.4 | the first rename ED itself causes |
| D012 | The documentation budget is a committed line count, gating from the first commit | 0.4 | the budget is hit twice by a documented need |
| D013 | `mp-client` collection reaches `hook` and `export` and no other state, until SP-2 says otherwise. SP-2 answers by attempting a resident instrument per vantage, never by reading a `nil` return, because `nil` is ambiguous between "no such name" and "not on this role" | R2.1 | SP-2 closes, or a run reaches a further state |
| D014 | Three repeats per task at a release boundary; eight on a power re-run of two tasks when GB fails with a wide spread | B.10 | GB fails that way twice |
| D015 | `COVERAGE.md`, `RENAMES.md` and `CONFLICTS.md` are all tracked | 6.2 | their combined diff exceeds the model's in a release |
| D016 | The Saved Games restore diff excludes the list SP-6 produces, and nothing else | 3.7 | DCS writes a new path the list does not name |

---

## 8. Spikes

An open question is a spike with an exit condition, never a row that "investigates".

| id | question | exit condition | runs on |
|---|---|---|---|
| SP-1 | Which states exist on a dedicated server, and which does the instrument reach | a table with one row per state, `reached` or `unreached (<reason>)` | DCS+human |
| SP-2 | Can a hook-resident instrument run under a multiplayer client | one run row per vantage attempted, with status | DCS+human |
| SP-3 | The inner string ceiling of the two-hop `a_do_script` path into `missionscripting` | the number, entered in the walk's budget table | DCS+human |
| SP-4 | Which method names C-function parameters and types returns — error-text parsing, cited-argument calls, cite-derived names | per-method yield on a function sample, printed as a table | DCS+human |
| SP-5 | How the driver reads the loaded mission's identity: the name from inside DCS, the hash from the `.miz` outside it | a command prints name and hash equal to the fixture's, and a mismatch for any other mission | DCS+human |
| SP-6 | Which paths DCS itself writes under Saved Games during a session | the exclusion list, and 3.7's diff printing empty with it applied | DCS+human |
| SP-7 | The walk budget that exhausts each state within the executor's per-chunk budget and the handshake's reply ceiling | one number per state, each with `frontier: 0` | DCS+human |

---

## 9. Standing rules, stated once, enforced by a check

| rule | enforced by |
|---|---|
| The DCS installation is read-only, including no write probe | 0.6 |
| `model/` is generated; a hand edit is refused | 0.3 with 6.3's manifest |
| An observation file is immutable and named for its run; runs are never reopened | 0.3, 2.2 |
| `dcs.log`, crash dumps and supervisor zips are never committed | 0.3 |
| Conventional Commits | 0.3 |
| The documentation budget gates | 0.4 |
| The specifications under `docs/specs/` freeze at the first build commit and are never edited after it | 0.3, 0.4 |
| Lua is 5.1.5 PUC-Rio; nothing else counts | 0.2 |
| Scrub in the walker; never `nil`; every token spelling and the `ROOTS` regexes; keys and values | 1.3, backstop in 2.4 and 6.2 |
| Collect only against the fixture mission, matched by name inside and hash outside | 3.2 |
| A run is ledgered only with both controls passed | 2.2, 3.3 |
| A tier-2 candidate cites its source; never a dictionary sweep | 2.4, 4.2 |
| A probe carries an effect class; deny classes are refused | 1.7, C.1 |
| An authored claim ranks a probe candidate and never authorises one | C.1, 8.8 |
| `unmeasured` is never written; `null` is never a value | 6.1 |
| Conflicts are reported, never resolved | 6.2 |
| An authored entry needs a basis and can neither create a `sym` nor set a type | 6.5, 8.1 |
| A ceiling is earned by totality within its scope and recomputed, never carried | 6.5, 8.4 |
| A `D` or `A` grade survives to the emitted text, and `unverified` beside it | 7.3 |
| `model/` conflicts are regenerated, never merged; `observations/` cannot conflict | 0.3, 6.6 |
| A session never ends parked | 3.3 |
| An exclusion cites a decision or a spike | 7.6 |

---

## 10. Sequencing and the critical path

**The critical path is wall-clock, not effort.** It is the chain of sessions a human must sit
through: 3.7 → 4.6 → 4.7 → 4.8 → C.2, then R2.2 and R3.2. Every one of those needs DCS started, the
fixture mission loaded and the game brought to phase by a person, and none can be parallelised by
adding developers. So:

1. **Stages 0–3 first, in that order.** They are the developer tooling, and every session before
   they exist is a session spent slowly. Stage 3 ends on the first real session because a driver
   proven only against a stub has proven nothing about crashes.
2. **Start the C-function tier as soon as 1.7, 3.5 and C.1 exist** — during Stage 4, before merge.
   Its observations are evidence whether or not a model exists yet to merge them into.
3. **Spend the spikes early, and several of them before Stage 3 exists.** The executor's tools are
   registered at user scope and so are in every session here, which means SP-3, SP-6 and SP-7 need
   only a person at DCS and a chunk to evaluate — no driver, no parks register, no plan. Run them in
   the first sitting anyone can arrange. SP-5 needs 3.2's `.miz` to exist but nothing else; SP-4
   needs 1.7. Each spike deferred is a later session re-run.
4. **Stages 5, 6 and 7 fill the calendar** while the session chain waits on a human. They are
   developer-only and depend on the golden corpus, not on live runs.
5. **Stage 9's B.0′–B.5c can start on day one** — they need only the scenarios and the tasks written
   against them. B.1b′ waits on 7.8's skill package, B.6 on 7.4, and B.8a onward on Release 1's emit.
6. **Releases 2 and 3 are real work, scheduled after C.2 reaches `remaining: 0`** for the
   single-player states, so that the multiplayer sessions are not competing for the same sitting
   with the probe campaign. A server environment exists well before then (A7), so SP-1 can be run
   the moment 3.7 is done, and its answer shapes R3.1 long before R3.2 is scheduled.

A crash on a mission configuration costs one human mission load (~15 s of silence plus attention),
and that is the unit the campaign is budgeted in — D010 exists to keep that number falling.

---

## 11. Kept outside the plan

Anything unbounded and demand-driven is not a row. The plan builds the machinery and says who
decides.

| thing | why not a row | machinery | who decides |
|---|---|---|---|
| Authored descriptions of symbols | never finished; a target would be invented | Stage 8; 8.3's worklist | the maintainer, from the worklist |
| The finish line N itself | it is a judgement about what is enough, made once against a real card | 1.4; B.5b's `threshold N` line | the maintainer, at the first card |
| New benchmark tasks beyond the sealed set | the pool grows as roots are touched | B.5c intake, B.6 harvest | whoever adds a task, gated at intake |
| Tier-2 candidates from future captures | the list grows with every run | 2.4's citation rule, 4.2 | the cited sites, not a person |
| Probe candidates beyond the cited list | a dictionary sweep is barred | C.1 refuses uncited entries | D009's revisit condition |
| Adding or removing a scenario | it changes the cut, the coverage denominator and the quota at once | `docs/SCENARIOS.md`, 5.12's root gate, B.5c | a decision record naming the roots, the exemplars and the two tasks |
| Re-collection after a collector-version bump | one per bump, on demand | D003, the one-command session | the maintainer, per bump |
| Retiring a benchmark task | a rule, not a judgement | `benchmark.md` §5.5, `bench-regress` | the rule |
