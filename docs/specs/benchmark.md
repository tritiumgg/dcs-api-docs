# The benchmark, for the rewrite

This is the instrument, for a project rebuilt from scratch: a new repository, a new key grammar,
and a benchmark written here from nothing.

**Citation convention.** A path written `prior:<path>` is a file in the superseded repository this
project replaces, cited as evidence of shape and readable there on demand. **Nothing in the new
repository reads one at build time, and no rule, table or figure below is defined by one.** An
unprefixed path is a file in the new repository — one this document expects to exist, or tells you
to create.

---

## 1. The job

The benchmark is the acceptance evidence for the collection and emission stages, and it has one
job: **score a release against the threshold the project has to clear, and against the release
before it.** Nothing else in the project measures whether what was emitted answers a consumer's
question. A record-level diff between releases was considered and declined: it measures the
intermediate rather than the product, and an empty diff is in any case consistent with having
rebuilt the same artefact more tidily.

**The finish line is a number, not a comparison.** A release passes when, over a task pool that
meets §5's quotas, the fraction of consumer questions answered correctly is at least **N**, printed
as a range over the repeats, and every task's tier-0 prediction agrees in direction with the agent
result.

**Where N comes from.** N is the maintainer's number, and it cannot honestly be set before anyone
has seen what this instrument reads on this model. So **the first card prints ungated**: every
figure, no pass and no fail. The maintainer reads it, sets N from it, and records N in
`docs/PLAN.md`'s Release 1 acceptance table. **From Release 2 on every card is gated on N**, and a
release that does not clear it is not a release.

**N is a committed number, not prose.** It lives in `bench/threshold` — one number, one line — and
`claims` reads it from there when it re-derives a card. A threshold quoted in a release document or
in the skill and absent from that file fails `claims` like any other figure that does not
re-derive.

**Each release also prints beside its predecessor.** Release 2's card prints beside Release 1's and
Release 3's beside Release 2's, on the same key through two spelling files. The first release
prints alone: there is nothing for it to sit beside, and no Δ column (§9).

---

## 2. Nothing carries

Nothing crosses into this repository from anywhere else: not a file, not a corpus, not a ledger,
not a figure.

- **The runner prompt is written here**, to the shape §7 states. There is no prompt to port and no
  carried file to edit; **B.3 writes it.**
- **The needs are drawn here**, from the sources §4 lists: harvested call sites, a
  census-drawn sample, the scenarios' own typical questions, and hand-writing where nothing above
  expresses a scenario.
- **The ceilings are earned here.** A ceiling is a scoped statement that this project's own model
  provably cannot answer a thing, with a basis and a revisit condition under `model.md` §5. None is
  carried, and none is asserted.
- **The ledgers start empty.** Benchmark runs are recorded in `bench/runs.tsv` (§8), which has no
  rows until `bench-run` writes one.

Ruled out by construction, both having been live options. **A key is never seeded from a report's
successes** — a key built from what runs *found* cannot score a run on what everyone missed, and it
inherits the bias of whatever surface the last pool happened to touch. And **a seal is spent by
spending it**, so the sealed set (§10, B.7) is written here and never read while tuning.

A `prior:` citation may still appear below where it is the evidence for why a rule reads the way it
does. It explains a rule; it never defines one.

---

## 3. A task

A task is a question, an answer and a memory. **The `.txt` is the question, the `.key.tsv` is the
answer, the `.md` is the memory.** The `.md` carries the task's header — its state, its job and
its scenario (§5.1) — and everything a later reader needs to know about how it was written.

```markdown
## The task

<What the consumer wants, in their words. One paragraph. No API names, no steps, and no
hint of which state or subsystem it lives in — naming those is answering it.>

## What you have

<The reference, and the arm. Nothing else.>
```

`tasks/map-overlay.txt`:

```markdown
## The task

Write a mission script that draws an overlay on the in-game map — outlines, filled areas, lines
and free-standing text labels. It must be showable either to everybody or to one coalition alone.
As mission state changes, the script must recolour, relabel and move shapes it has already drawn
rather than deleting and redrawing them, and it must be able to clear one layer of its own overlay
without disturbing another layer or anything a player drew by hand.

## What you have

A generated API reference at `<RELEASE>`. Nothing else.
```

### The controls

`positive`, `negative` and `out-of-scope`. They sit outside the pool, count toward no quota, and
print on their own line, never averaged into the headline (§9's rules). **They measure the
instrument, not the model**, and each fails in a way that means one specific thing.

| Control | The task | What a failure means |
|---|---|---|
| `positive` | a question this release demonstrably answers: a capability whose symbol, state and argument list the index and the defs all carry | the harness, not the model. A miss means the skill, the release directory or the runner's tool root is broken, and no other figure on the card can be read |
| `negative` | a question whose correct answer is a negative: a capability that does not exist in this release, asked without saying so | the runner will not state an absence. It invents, or it hedges until it runs out — the failure mode every other task's `forbidden` need samples one row of |
| `out-of-scope` | a question about something `docs/SCENARIOS.md` excludes by name — a per-aircraft table under `Mods/`, a `.trk` file, a `.mo` translation | the runner does not know the model's edge. It answers from memory about ground this project never measured, which is the one failure that cannot be caught by scoring what it cites |

**How each control's needs are chosen.**

- The **positive** control's needs are chosen so that tier 0 scores them **100%**: every one is a
  fact the release carries at a path the spelling file resolves, and the scripted consumer finds
  all of them. This is the one place where the tier-0 intake gate is deliberately failed, which is
  why the controls are not pool tasks.
- The **negative** control's needs are all `forbidden` and `absent` rows: `fact: absent`,
  `truth: no`, one per plausible spelling of the thing that does not exist. A hit requires the
  report to state the absence and cite the search that found nothing (§6). Tier 0 scores it near
  0% by construction.
- The **out-of-scope** control's key holds one `required` need whose truth is the decline itself —
  `fact: absent`, `truth: no` — plus a `forbidden` need for each name a runner reaching past the
  model's edge would reach for. A hit requires the report to decline and to cite the exclusion in
  `docs/SCENARIOS.md`; an answer that is correct about DCS and uncited is a `wrong`, not a hit.

---

## 4. The key names a need, never a path

A key that names `trigger.action.quadToAll` is a key against one spelling of one artefact. The
grammar renames records, so a path-keyed key would need rewriting at every release — and it could
never score a release and its predecessor together, which is half of what §1 asks for.

So the key names the **need**. Paths live in a per-release spelling file.

### `tasks/<slug>.key.tsv` — stable across every release, forever

```
class	need	fact	truth	note
```

| Column | Values |
|---|---|
| `class` | `required` `expected` `forbidden` `ceiling` |
| `need` | a stable slug. The unit of comparison |
| `fact` | `exists` `state` `arity` `return` `callsite` `absent` `row` |
| `truth` | `yes` `no` `not-stated`, a literal for `arity` / `return`, or a literal cell value for `row` |
| `note` | prose, for people. Never scored |

```
class	need	fact	truth	note
required	overlay.shape	exists	yes	a general shape call
required	overlay.line	exists	yes
required	overlay.fill	exists	yes	a filled area
required	overlay.label	exists	yes	free-standing text
required	overlay.one-coalition	exists	yes	shown to one coalition, not everybody
required	overlay.clear-one	exists	yes	remove one layer, leave the others
required	overlay.shape	arity	9
expected	overlay.circle	exists	yes
expected	overlay.mark-all	exists	yes
ceiling	overlay.shape-position-type	arity	not-stated	position #1 accepted every candidate, so its type is unmeasured
ceiling	overlay.clear-one-arity	arity	not-stated	a probe's lower bound, not a count
forbidden	overlay.markup-one-coalition	absent	no	plausible by symmetry. exists in no release
```

**`fact: row`, for a reference-data lookup.** Scenario 6's consumer asks for a cell, not a
signature: the CLSID for a weapon, the type name `Group.spawn` wants, the country ids in a
coalition. A `row` need's `truth` is the **literal cell value**, and the need resolves through the
spelling file to a table and a key column — `data/weapons.tsv#clsid`, say — rather than to a
symbol path. A hit is the literal value, cited to the row. This is the only fact whose truth is a datum
rather than a property of a symbol, and it is scored exactly like the others.

### `spellings/<release-id>.tsv` — one per release, written once

```
need	state	path
overlay.shape	scripting	trigger.action.markupToAll
overlay.line	scripting	trigger.action.lineToAll
overlay.fill	scripting	trigger.action.quadToAll
overlay.label	scripting	trigger.action.textToAll
overlay.one-coalition	scripting	trigger.action.markToCoalition
overlay.clear-one	scripting	trigger.action.removeMark
overlay.circle	scripting	trigger.action.circleToAll
overlay.mark-all	scripting	trigger.action.markToAll
```

Every path above resolves in this release's `index/scripting.tsv`, and
`trigger.action.markupToCoalition` resolves in no index file of this release — which is what makes
it usable as a `forbidden` need.

**Where a need's span comes from.** The spelling file names a state and a path and stops there. The
span is **the release's own**: the `defs` pointer the index row carries, resolved in the release
under test. A key never records a span, a release never has its spans rewritten to suit a key, and
`bench-keys` checks that every resolved span is in bounds for the release it is pointed at.

**The citation namespaces.** A citation in a report takes one of these shapes and no other:

- **`<path>:<line>`** — a file inside the release under test. This is the ordinary case, and the
  verdict engine resolves it against the release directory.
- **`install:<path>:<line>`** — a file in the DCS install that the release does not index. A chain
  a runner followed out of the model and into ED's own Lua is legitimate evidence and must be
  citable, but it is **not** a model fact. An `install:` citation **exempts a chain from
  `invented` only when the file exists in the install inventory** the release ships; an
  `install:` citation of a file that is not in that inventory is `invented` like any other
  unresolvable chain.

**What this buys.**

1. **One key scores every release.** A release and its predecessor become a real comparison rather
   than two incomparable numbers, and the threshold of §1 means the same thing at every release.
2. **No migration.** A fresh spelling file is resolved against each new index; the keys never move.
3. **A free regression detector.** A need that resolved in the previous release's spelling file and
   in none of this one's is a symbol this release lost — caught by `bench-keys` in under a second,
   **before any agent run is spent** (§10, B.8b). That is the cheapest check in this document.

### Where needs come from, in priority order

1. **Harvested** — `bench-harvest --state <s>` takes a call site out of ED's own Lua, hides the
   call, and emits the objective and the needs from the site. The key is ED's usage, not an opinion.
2. **Census-drawn** — a seeded, state-stratified sample of records.
3. **Scenario-derived** — the **typical questions** each scenario in `docs/SCENARIOS.md` lists.
   Those lines are a consumer's question already written in a consumer's words: "what
   `LoGetSelfData` holds and which fields are per-aircraft" is an objective and a `return` need
   with the symbol taken back out, and "which country ids belong to which coalition" is a `row`
   need against `data/countries.tsv`. This is the source that makes the scenario quota (§5.1)
   fillable without inventing a consumer.
4. **Hand-written**, for a scenario nothing above expresses.

**Never seeded from a report's successes.** A key built from what runs *found* cannot score a run
on what everyone missed, and the pool ends up shaped by whatever surface the last pool happened to
touch.

---

## 5. Choosing and writing a task

Both halves are mechanical: **what to write a task about** is a quota, and **whether a written task
is admissible** is a gate that costs no agent run.

### 5.1 The axes, and the quota on each

A task declares each of them in its header. Each is countable, so the pool's shape is a printed
number rather than an impression.

**The surface axis — where in the API.** The state, and the top-level root. A pool can be large and
still sit on one corner of the model: the roots that hold most of the index are the ones nobody
thinks to write a task about, and they are exactly what the untouched-root quota below and the
sealed set (§10, B.7) aim at.

**The job axis — what the consumer is trying to do.** A closed set.

| Job | The consumer's question | A dead end looks like |
|---|---|---|
| `find` | does a capability exist at all | no symbol addresses this |
| `call` | invoke it correctly | an argument whose type or order nothing states |
| `react` | receive an event and read its payload | the field names on the table a handler receives |
| `enumerate` | what are the legal values | a closed set of constants that exists nowhere |
| `identify` | what names this object, and how do I refer to it later | an id-space question |
| `lookup` | what is the value in this row | a table whose rows ship without the column asked for |
| `negative` | establish that something is **not** possible | — the answer *is* the finding |

**`lookup` is a job, not a variant of `find`.** Scenario 6's questions resolve to a cell rather than
to a symbol (`fact: row`, §4), the search that answers one is a grep of a TSV rather than of the
index, and folding it into `find` would let the reference-data half of the model go unasked while
the job quota still read green. It is corrective to have the job axis at all: unless something
counts, a pool drifts toward "does it exist", and a pool can cover the surface broadly and still
ask one question.

**The scenario axis — which consumer.** The scenario id from `docs/SCENARIOS.md`, as a header
field. It is an axis of its own and not a re-labelling of the surface: most scenarios span two
states, and the state boundary is usually the hard part of the question.

**The quotas.** Over the **live pool** — every admitted task except the `held` ones (below) and the
controls:

- no state holds more than **40%** of tasks
- no job holds more than **30%**; every job carries at least **2**
- every scenario carries at least **2** tasks; no scenario holds more than **25%**
- at least **25%** of tasks sit on an **untouched root**

**The untouched-root denominator is the pool's own.** There is no earlier pool to diff against. A
root is *touched* when some live task's key resolves to a path under it in the current release, and
a task counts toward this quota when the root its key sits on is touched by no other live task. The
set is recomputed at every intake and at every release, because a re-spelling can move a need onto a
root another task already holds.

**When a scenario floor collides with a state ceiling.** The scenario floor is a minimum and the
state quota is a maximum, and the two can be unsatisfiable together: a scenario whose every
question lives in one state drives that state's share up by arithmetic. **A state breach caused
only by meeting a scenario floor is reported, not refused** — `bench-tasks --audit` prints it as a
named breach with the scenario that forced it, and the pool stands.

**`held` tasks.** A task may be admitted **`held: <release>`** when its state cannot be measured
until a named future release — scenario 9's `mp-server` surface is the standing case. A held task
is written, keyed and admitted like any other, **counts toward every quota**, and is **excluded
from the card** until the release that can measure it arrives, at which point it joins the live
pool and is measured with it. This is what keeps a scenario's floor meetable at Release 1 without
pretending a release measured something it could not reach.

**Sealed tasks** (§10, B.7) count toward **no** quota and run **at release boundaries only**. A
task that is read while tuning is not sealed, and a sealed task counted into a quota would have to
be read to count it.

`bench-tasks --audit` prints the distribution and every quota number. **A task breaching a quota is
refused at intake**, with the one reported-not-refused exception above.

### 5.2 Writing the objective

The rules, each of which exists because breaking it leaks the answer or makes the task
unscoreable.

1. **Write it as a want, in the consumer's words.** "I need to draw an overlay on the map", not
   "test the `trigger.action` markup family".
2. **Name no symbol, no state and no subsystem.** Naming the state halves the search, and the state
   is often the answer — `scripting` and `missionscripting` hold much of the same API under the
   same names, so telling the runner which one to look in is telling it the finding.
3. **No steps, no ordering, no count.** "Find the call that draws a filled area" gives away that one
   exists, that it is a call, and that it is separate from the outline call — all of it given away
   before the runner has read anything.
4. **One paragraph.** If it needs two, it is two tasks.
5. **Carry at least one constraint that forces a second-order question.** "…without disturbing
   anything a player drew by hand" is what turns a `find` task into an `identify` one. A task with
   no such constraint measures only whether a name is greppable.
6. **Say what a finished answer is** — a script, or a stated finding. A `negative`
   task's deliverable is the finding and the search that establishes it.
7. **Write the key at the same time.** If you cannot state the needs, you do not understand the task
   well enough to score it. Harvested tasks reverse the order — the key comes off the call site and
   the objective is written to fit — and either order is fine as long as they land together.

**Objectives that fail intake.**

> *Establish which functions in the `scripting` state create a static object at runtime, and what
> arguments each takes.*

Breaks 1, 2 and 3: it is the rubric in prose, it names the state, and "which functions" concedes
there are several.

> *Write a script that puts a helicopter landing pad on the map.*

Breaks 5 and is nearly unscoreable — no constraint forces anything past a single `find`, so a
runner that greps one name has finished. Adding *"…and reads back its position after the mission
has been running for an hour, without having stored it"* turns it into a real `identify` task.

### 5.3 Deriving the needs

Read the objective and ask, clause by clause, *what fact must be true for this clause to be
satisfiable*. Each answer is one need.

Worked, on `map-overlay`'s objective:

| Clause | Need | Class |
|---|---|---|
| "outlines … lines … filled areas … labels" | `overlay.shape`, `overlay.line`, `overlay.fill`, `overlay.label` | `required` |
| "either to everybody or to one coalition alone" | `overlay.one-coalition` | `required` |
| "recolour, relabel and move … rather than deleting and redrawing" | `overlay.shape` `arity` — the mutate path needs the full argument list | `required` |
| "clear one layer … without disturbing another" | `overlay.clear-one` | `required` |
| "…or anything a player drew by hand" | `overlay.markup-one-coalition` — the symmetric call a runner invents here | `forbidden` |

Then the additions that are not read off the objective at all:

- **A `forbidden` need per task, minimum one.** The best ones are plausible by symmetry with a real
  symbol: `trigger.action.markupToCoalition` exists in no index file and is exactly what a
  competent runner invents when handed `markToCoalition` and `markupToAll` with no way to combine
  them. A task with no `forbidden` need cannot measure invention — and invention moves: once
  existence became answerable, readers stopped inventing symbols and started inventing arguments,
  so a `forbidden` need on an argument is worth as much as one on a name.
- **A `ceiling` need for every fact the reference cannot state.** Each needs a basis, not an
  opinion — this release's `defs/scripting/trigger.lua:156` records that position #1 accepted every
  candidate, so its type is unmeasured rather than absent. Under `model.md` §5 a ceiling is
  statable with a revisit condition, so a `ceiling` need is a claim the model itself can be held
  to.

### 5.4 Intake — the gates, no agent run

A task joins the pool when every gate below passes. `bench-tasks --admit <slug>` runs them.

1. **The key resolves.** Every `required` and `expected` need has a spelling; every `forbidden` need
   has none. Prints the `unspellable` list, which is admissible — a need nothing carries yet is a
   requirement, not a defect.
2. **The objective does not name its own answer.** No token in the objective matches the leaf of any
   path its key resolves to, **nor any entry root of the scenario the task declares**. The second
   half matters as much as the first: an objective that says "the mission editor's route model" has
   named `me_route` without typing it, and the scenario's root list in `docs/SCENARIOS.md` is where
   that vocabulary is written down. This is the mechanical form of rule 2, and it catches the leak
   that prose review misses.
3. **Tier 0 lands strictly between 0 and 100%.** The scripted consumer answers the key with no
   model. **At 100% the task discriminates nothing** — a perfect reader gets everything, so no
   agent result can be informative. **At 0% it is all ceiling.** Admit only what lands in between,
   and record the tier 0 number as the task's difficulty at admission.
4. **The state, job and untouched-root quotas hold** with this task added — §5.1.
5. **The scenario quota holds** with this task added: every scenario still carries at least two
   tasks, and no scenario holds more than 25%. It is a gate of its own rather than a line in the
   quota gate above because it is the only quota that can be breached *downward* by admitting
   nothing — a pool that never adds a scenario 5 task fails this gate forever, and the audit says
   which scenario is short.

The tier-0 gate does the most work and it is free. A task whose question needs a fact the model holds
nowhere — a column `unknown` on every row of the index, say — is all ceiling: it scores near zero
forever, separates no runner from any other, and is refused at intake rather than left in the pool
returning the same number.

### 5.5 Retiring a task

A task leaves the pool when it stops discriminating, and this is a rule rather than a judgement:
**three consecutive releases at tier 0 = 100%** means the model now carries everything it asks, and
it should be replaced by a harvested task on an untouched root. Its key stays — a retired task's
needs move into `bench-regress`, so the facts it established go on being checked for free forever.

---

## 6. Verdicts, and the score

Per key row, against the report's citations and its `SCRIPT`, with the need resolved through the
spelling file for the release under test. **Every verdict is computed from the key; nothing a
runner says about its own performance is read.**

| Verdict | Rule |
|---|---|
| `hit` | the need's path is cited, the cited span contains it, and any `truth` value matches |
| `wrong` | cited, and the stated value contradicts `truth` |
| `miss` | `required` or `expected`, neither cited nor present in `SCRIPT` |
| `unspellable` | the need resolves to no path in this release. **Not a runner failure** — a model gap, counted on its own line |
| `ceiling` | subtracted from the denominator, counted |
| `invented` | a `forbidden` need's known spellings appear anywhere, or a chain in `SCRIPT` resolves in no index file and carries no `install:` citation to a file in the install inventory |

```
denominator = required + expected − ceiling − unspellable
score       = hit / denominator
```

**`unspellable` separates *the model does not carry this* from *the runner could not find it*.**
That attribution is the whole point of the column, and it is computed for free by `bench-keys`
before a run starts.

**`invented` and `wrong` are published on their own lines and never subtracted.** A run that
answers most of its key and invents as it goes is a different animal from one that answers as much
and invents nothing.

**A correct negative is a hit.** A row of `fact: absent, truth: no` passes when the report states
the absence and cites the search that found nothing. This row class is winnable only because
`model.md` §5's absence spellings make an absence a statable fact, so it is a direct test of that
section.

**`memorised` is a flag on a run, not a verdict on a row.** The canary (§10, B.11) alters one key
fact in one task in five; a run that restates the original rather than what the release now says
answered from memory, and the whole run is flagged. It is set at run level because it says nothing
about a single need and everything about whether that run's figures are a measurement of the model
at all. **It is printed on the card (§9) beside the score, is never a verdict, and is never
subtracted from anything.**

---

## 7. The runner

**B.3 writes `bench/runner-prompt.txt`.** There is no prompt to carry over and no carried file to
edit: the rules below are its content, and the grammar below is what the verdict engine parses.

**What the prompt says.**

1. **Cite everything.** Every DCS symbol the run asserts carries a citation, in one of §4's two
   namespaces — `<path>:<line>` inside the release, or `install:<path>:<line>` for a chain
   followed out of the model and into the install.
2. **Never invent, never stop.** A symbol the reference does not carry is reported as not carried,
   with the search that established it; it is never supplied from memory. A fact the reference does
   not state is marked in the script with a `-- UNKNOWN:` line naming what is missing, and the run
   continues — a stop is not a finding.
3. **Half an answer is a dead end.** A script that would not run, or that silently drops a clause
   of the objective, is reported as a dead end with the clause named. Partial credit is the key's
   business, not the runner's.
4. **No rubric.** The prompt holds no numbered steps, no step count, and no verdicts. **The rubric
   is the key, in a file the runner never sees.** A runner that scores itself is scoring the wrong
   thing: a run that answers one need of many and reports `1 of 1` passes clean under any such
   scheme.

**The report grammar.** These headings, in this order. Anything else in the report is prose and is
not read.

- **`SCRIPT`** — exactly one fenced Lua block, and exactly one. **It may be empty for a `negative`
  task**, where the deliverable is the finding and the search rather than code.
- **`CLAIMS`** — TSV, one row per DCS symbol the run asserts:
  `symbol<TAB>state<TAB>citation<TAB>untested`. `citation` is in one of §4's namespaces;
  `untested` is `yes` or `no` and says whether the run would ship the symbol without having seen it
  measured. This replaces any self-reported step count: the engine reads these rows, and the runner
  stops scoring itself.
- **`SEARCH LOG`** — every query, in order, with what it returned. It is the only findability
  instrument in the project, and `bench-harvest` reads it.
- **`RECALLED BUT NOT FOUND`** — every symbol the runner remembered and could not find. Each is
  either a model gap or a hallucination, and `bench-harvest` settles which — a free memorisation
  probe.
- **`GREPS` / `LINES READ` / `LONGEST READ`** — the query counters, **reported and never gated.**
  They are effort-substitutable and noisy at once: an arm that gains a few needs while reading twice the
  lines has bought a qualified gain, and on tasks whose score does not move at all the grep count
  swings several-fold either way. So query cost is a counter-metric printed beside the score, and
  never a gate.

---

## 8. What you run

| Command | Cost | When |
|---|---|---|
| `bench-keys` | < 1 s | every commit |
| `bench-tier0` | < 10 s | every commit, inside `verify` |
| `bench-regress` | < 10 s | every commit |
| `bench-harvest` | seconds | when adding tasks |
| `bench-tasks --audit` / `--admit <slug>` | < 1 s | when adding tasks, and every commit |
| `bench-run --task <t> --repeats <n>` | n agent sessions | release boundary |
| `bench-card` | < 1 s | after any of the above |
| `claims` | < 1 s | every commit |

**`bench-keys`** — every `required` / `expected` need resolves in the release's spelling file, every
`forbidden` need resolves nowhere, every span the release's defs give is in bounds. Prints the
`unspellable` list. A planted bad path fails it.

**`bench-tier0` — the scripted consumer, built here.** No model, no DCS. Follows the skill literally
for every need: grep the index, follow the `defs` pointer, read the span, record whether the fact is
there; for a `row` need, grep the table and read the cell. **This is a prediction of the agent
score, computed before the runs are spent** — the gap between tier 0 and the agents is findability,
and tier 0 being low is the model. It also emits the per-build ledger: arity known, returns stated,
inert columns.

**`bench-regress`** — **re-resolves every chain in each accepted `SCRIPT` against the new index**,
symbol by symbol, and fails on any chain that resolved in the release it was accepted against and
resolves in none of this one, naming the task and the symbol. A selection change that drops a
shipped answer's symbol is caught here. It also **re-checks every retired task's key rows** (§5.5):
a retired task costs no agent run and its facts go on being checked forever.

**`bench-run`** — **`--repeats` is mandatory with no default.** An instrument that never repeats a
measurement has no noise floor and cannot say whether anything it reports is a result; the
superseded pipeline's ledger held one row per distinct `(task, version, prompt_digest)` triple and
no repeat of any of them, which is the mistake this rule exists to prevent.

**The runner contract.** One fresh **Claude Code subagent per `(task, release, repeat)`** — never a
reused session, because a second task in one context is scoring the first task's reading.

- **Tools are rooted at the release directory under test.** The release is all the runner can
  reach.
- **The key files, the spelling files, `bench/` and `docs/specs/` are unreachable** from inside the
  run. The rubric is not in the room.
- **Worktree isolation**: each run gets its own, so nothing one run writes is visible to the next.
- **The model id is pinned per release and recorded on every run row.** A card whose rows carry two
  model ids is not a measurement of one runner, and `claims` refuses it.

**The ledger.** Benchmark runs are recorded in **`bench/runs.tsv`**, one row per
`(task, release, repeat)` with its model id, its verdict counts and its `memorised` flag. **It is
not the census ledger.** The census's `runs` ledger records collection inside DCS; this one records
a runner reading a release. Sharing them would put two populations with different units and
different repeat rules in one table, and every query over either would have to filter first.

**`<release-id>`** — on every spelling file's name and every run row — **is the release
document's id: the short git sha of the commit the release was built from.** One release, one id, and the
spelling file for it is written once and never rewritten.

**`claims`** — re-derives every benchmark figure quoted in a release or a skill, reads N from
`bench/threshold`, and fails on a mismatch or on `n < 3`. Reproducing is not the bar: a figure can
re-derive to the row and still rest on one run per arm.

---

## 9. The scorecard

```
release      3f2a91c              previous  —
runner       sonnet/claude-sonnet-5         repeats 3
threshold    N unset — this card is ungated

                         score           unspell  ceiling  invent  wrong
map-overlay              7/9  ±1         0        2        0       0
mission-event-timeline   6/11 ±2         2        1        1       0
...
                         ----            --       --       --      --
open set                 58/94 (61.7%)   7        3        1
sealed set               12/31 (38.7%)   4        0        0
controls                 7/10            0        0        0

scripted ceiling         71/94 (75.5%)   free, no model
model ledger             arity known NN.N%   returns stated NN.N%   inert columns N of N
flags                    memorised 0 of N runs
```

The header carries `release` and `previous`. **`previous` is absent at Release 1** — printed as
`—`, because the first release has nothing before it — and from Release 2 it names the
predecessor's release-id, its figures print in their own columns, and a **Δ** column prints beside
them. There is no Δ at Release 1.

The rules the card enforces:

1. **A range, never a point.** A number with no spread is not a result.
2. **The threshold, printed, and the predecessor beside it.** The card states N as read from
   `bench/threshold` and whether the open set clears it; the first card, with no N to read, prints
   `N unset — this card is ungated` and is the input the maintainer sets N from (§1). From
   Release 2 the predecessor's columns and the Δ print beside the release's own, scored through one
   key and two spelling files.
3. **Open and sealed sets never sum.**
4. **Controls on their own line, never averaged.** Averaging a control into the headline is how a
   control regression hides behind a headline that did not move.
5. **`unspellable`, `invented` and `wrong` are columns, not deductions.**
6. **The scripted ceiling sits under the agent score**, on every release printed.
7. **`greps` and `lines` are printed and never gated**, and so is `memorised` (§6).

---

## 10. Build order

**Track B.** No row in it costs an agent run until B.10.

### Before a release exists

| # | Do | Done when | Needs |
|---|---|---|---|
| B.0′ | **The task pool.** Write, against `docs/SCENARIOS.md`, at least two tasks per scenario, plus the controls of §3 — a (task, key, memory) triple each, with its state, job and scenario header | every triple is written and **admitted** by `bench-tasks --admit`; `--audit` prints the distribution against every quota number of §5.1, with any held task counted and any scenario-forced state breach named | B.5b, B.1b′ |
| B.3 | **Write** `bench/runner-prompt.txt` to §7 | no `.txt` holds a numbered list or a step count; a report written to §7's grammar parses into `SCRIPT`, `CLAIMS`, `SEARCH LOG`, `RECALLED BUT NOT FOUND` and the query counters | — |
| B.4 | The verdict engine, §6 | a report fixture — one clean run, one inventing a `forbidden` spelling, one stating a correct negative with its search, one citing `install:` inside and outside the install inventory, one truncated mid-`CLAIMS` — scores to the expected verdict row for row, and the truncated one is refused rather than scored low | B.3 |
| B.5 | `bench-keys` and `bench-card` | both under 1 s; the `unspellable` list prints; a card with no `previous` prints with no Δ | B.4 |
| B.5b | `bench-tasks` — the quotas and the intake gates, §5.1 and §5.4 | `--audit` prints the state, job and scenario distributions against every quota number; `--admit` refuses a task whose objective names a leaf of its own key **or an entry root of its scenario**, and refuses one tier 0 scores at 0% or 100% | B.5, B.1b′ |

**Written before, admitted after.** B.0′'s tasks and B.5b's gates are written with no release in
the room, but the tier-0 gate cannot score anything until one exists, so **admission waits on
B.1b′**. The writing is not blocked by it; the pool's `admitted` state is.

### Once call-site extraction lands

| # | Do | Done when | Needs |
|---|---|---|---|
| B.6 | `bench-harvest`, with per-state quotas | a draw breaching a quota is refused; the draw is stratified per state, because cited-use pointers are not uniform across states and a uniform draw over-samples whichever state ED's own Lua exercises most | call-site extraction; B.5 |
| B.7 | **The sealed set** — harvested tasks over the untouched surface, committed and never read while tuning | tracked task/key pairs on roots no live task touches; **the access rule is a rule**: the sealed files are opened at a release boundary, by `bench-run` alone, and a session that reads one has spent it and says so in the release document. Sealed tasks count toward no quota | B.6 |

### Once the model emits a release

| # | Do | Done when | Needs |
|---|---|---|---|
| B.1b′ | **`bench-tier0`** — the scripted consumer of §8, built here | under 10 s; deleting one key path fails it; the per-task tier 0 score prints and becomes that task's difficulty at admission | a built release; B.0′'s keys |
| B.8a | `spellings/<release-id>.tsv` for this release, resolved directly against its index | **every need either resolves or prints on the `unspellable` list** with the class it belongs to; every resolved span is in bounds | a built release |
| B.8b | **The lost-needs list, release to release** | at Release 1 it is **vacuous and prints as such** — there is no previous spelling file. From Release 2: every need resolving in the previous release's spelling file resolves here, **or** appears on a printed lost-needs list with a reason | B.8a, the id map |
| B.9 | `bench-regress`, and tier 0 re-pointed at this release | both under 10 s on a fresh emit; a planted selection change fails regress, naming the task and the symbol; a planted change to a retired task's key row fails it too | B.8a, B.1b′ |
| B.10 | **The measurement.** The whole live pool plus the controls, × repeats | `bench/runs.tsv` holds one row per `(task, release, repeat)`, every triple appearing exactly `--repeats` times, every row carrying the same model id; `bench-card` prints the card of §9 with tier 0's prediction beside the agent result | B.9, a built release |
| B.11 | The canary | one altered key fact per run in one task in five; a run restating the original is flagged `memorised` (§6); `caught: N/N, all planted` | B.10 |
| B.12 | `claims` | every published figure re-derives; N is read from `bench/threshold`; fails on `n < 3` and on a card whose rows carry two model ids | B.10 |

**GB — the release clears the finish line.** B.10's open-set range lies at or above **N**, and every
task's tier-0 prediction agrees in direction with the agent result. **GB gates every release.** At
Release 1 there is no N to clear: the card prints ungated, the maintainer reads it and sets N
(§1), and that act *is* GB for Release 1. From Release 2 on, GB is a pass or a fail before the
release document is written.

GB exists because an instrument without one reports movement it cannot attribute: a headline that
moves a few points per sweep while the artefact grows by tens of thousands of lines, at one run per
point, is telling you nothing you could not get from noise.

**If GB fails**, the worlds that produce it need different answers. At Release 1 these:

- **the range straddles N** → three repeats has too little power. Re-run two tasks at eight repeats
  before drawing any conclusion about the artefact.
- **the range sits below N** → read tier 0. Above N, it is findability: the index, the skill or the
  pointer, not the collectors. Below N too, the model does not hold the facts, and that is a
  collection finding with a named state.

From Release 2 there is one more, and it is the one only a predecessor can produce:

- **the release is at or below its predecessor** → something was lost rather than not gained.
  `bench-regress` and B.8b's lost-needs list name which symbols, before anyone argues about the
  score.

---

## 11. Cost

A measurement is the whole live pool plus the controls, × repeats. The pool is at least two tasks
per scenario, and `--repeats` is never below three, so the cost of a boundary follows from §5's
quotas and nothing else.

| | Runs | When |
|---|---|---|
| B.0′, B.3–B.9 | **none** | through the build |
| **B.10, Release 1's measurement** | **(live pool + controls) × repeats** | at the first release of the model |
| The sealed set at that boundary | **sealed set × repeats** | with B.10 |
| A release boundary thereafter | the same, open plus sealed | per release |
| A runner change | **(live pool + controls) × repeats**, plus one run of the previous release as a bridge | per runner generation |

**A measurement runs the whole live pool**, because a pool is a distribution and a subset of it is a
different instrument with the same name. **The maintainer may name a subset** for a given boundary
— to fit a budget, or to re-run two tasks at eight repeats after a straddling range — and when
they do, **the release document names the subset and the card says which tasks it holds.** A card that
does not say is read as the whole pool, and `claims` fails it if the ledger disagrees.

Everything above `bench-run` in §8 is free and runs on every commit forever.
