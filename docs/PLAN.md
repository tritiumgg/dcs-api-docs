# The plan

This plan builds usable DCS World Lua API documentation for AI agents with a small amount of
work: few stages, little new machinery, the executor and the existing tools reused, one or two
sittings at DCS, and a light process. It replaces the earlier plan of many stages, a C-function
track, three releases and a statistical benchmark. Section 7 says what that plan had that this
one keeps, and what each cut costs.

The facts in the output come only from the install's own files and from measurement inside DCS
through the executor. A fact found in neither is written as unknown, never filled in from
memory. The budget is a rule about what the plan contains, not a clock: no stage here carries
an estimate of hours or days.

Scope, set by the maintainer on 2026-11-06:

- Every API that exists on every terrain is in, even where its result differs by map
  (`land.getHeight`, `world.getAirbases`, `Airbase` and `Warehouse` methods).
- Lua that exists on one map only, under `Mods/terrains/<map>/`, is out, and so are per-map
  values such as the airbases of one map.
- The shared modding API is in, by the same rule as terrains: an API that more than one module
  uses is in, and code that belongs to one module is out. The shared API has three layers, each
  with a row in Stage 1: the plugin declarations (`declare_plugin`, `make_flyable`,
  `declare_weapon`, `declare_loadout` and the like), the C/C++ SDK headers under `API/include/`
  and `API/ExternalFMTemplate/`, and the cockpit and avionics framework (`GetDevice`,
  `get_param_handle`, `dispatch_action`, `make_default_activity`, `avionics.*`, the code under
  `Scripts/Aircrafts/_Common/`). One module's own cockpit Lua is out. The unit and weapon
  rows a module adds to `db` are data, kept, and the maintainer decides whether to filter them.
- The reference databases are in: static object type names, unit types, weapons and CLSIDs,
  countries, `wsTypes`, and the item names `Warehouse` accepts.
- Single-player states only. Multiplayer client and server are out.

---

## 1. What discovery measured

Measured on 2026-11-06 against the install at `C:\Program Files\Eagle Dynamics\DCS World`,
read-only, with the commands shown so a later run re-derives every figure.

### 1.1 What the install yields with no DCS running

| Source | Command | Printed |
|---|---|---|
| Lua function definitions under `Scripts/` and `MissionEditor/` | `grep -rEh '^\s*(local\s+)?function\s+[A-Za-z_.:]+\s*\(\|[A-Za-z_.]+\s*=\s*function\s*\(' Scripts MissionEditor --include=*.lua \| wc -l` | about 13,350; about 11% have a comment line directly above |
| ED's own call sites of C functions in `Scripts/`, `MissionEditor/`, `Config/` | `grep -rEoh '\b(Group\|Unit\|…)\.[A-Za-z_]+\s*\(' …` | 888 sites, 190 distinct `Namespace.method` names; `DCS` 80 names, `net` 57, the rest small |
| Namespaces with no ED call site in those trees | the same grep | `StaticObject`, `Warehouse`, `land`, `trigger`, `radio`, `AI`, `Weapon`, `Controller`, `Spot`, `SceneryObject` |
| Shipped `.miz` files | `find . -name '*.miz'` | 2,093; the `mission` table of 99 of them holds `a_do_script` actions; 51 distinct API names appear in those scripts, `trigger.action.*`, `Unit.getByName`, `timer.*`, `missionCommands.*`, `world.addEventHandler`, `coalition.addStaticObject` among them |
| Shipped API documentation | `ls API Doc` | `API/Sim_ControlAPI.md`: `Sim.*`, `log.*`, `net.*`, `lfs`, the `Lo*` export functions and the hook callbacks. No mission-scripting reference ships |
| The core `db` source | `ls Scripts/Database` | `Scripts/Database.edce` is encrypted; only `db_countries.lua`, `wsTypes.lua` and `Troops/` are readable. Weapon and unit declarations are readable under `CoreMods/` and `Mods/` (`declare_weapon`, `declare_loadout`, 143 distinct CLSID literals) |
| Terrain Lua | `find Mods/terrains/<map> -name '*.lua'` | per map, `Beacons.lua`, `NotInstances.lua`, `Radio.lua`; no global defined there is referenced from `Scripts/` |
| Module Lua | `find Mods/aircraft -name '*.lua'` | 5,043 files, most under `Cockpit/`; none carries a mission-visible API |
| The binaries, `bin` and `bin-mt`, build 2.9.31.29434 | a byte scan for Lua C API imports and for API names, ASCII and UTF-16 | `Scripting.dll`, `WorldGeneral.dll`, `edCore.dll` and others import `luaL_register`; `addStaticObject`, `getAirbases`, `dostring_in`, `outTextForCoalition`, `setUserCallbacks`, `LoGetSelfData` appear in no binary as plain text, so the registration tables are packed or encrypted and a static `luaL_Reg` extraction cannot recover the API; `bad argument` appears only in `lua.dll`, so the bindings use the stock `luaL_check*` functions and a bare call returns the standard `bad argument #n to 'f' (T expected, got U)` text |

What this means for the plan:

- Offline parsing covers Lua-defined functions well and the hook and GUI C surface partly. It
  covers the mission-scripting C surface poorly: ED's own Lua almost never calls it, and the
  shipped missions reach only the names 1.2 prints.
- Function names come from the runtime walk and from nowhere else; the binaries do not yield
  them.
- Signature evidence for most mission-scripting C functions therefore comes from measurement
  inside DCS, or stays unknown. The binary scan supports the error-text method: the error
  names the position and the expected type.
- The `db` rows come from a runtime dump in the editor state, because the source is encrypted.
- The terrain and module exclusions are cheap to apply by path, and a two-map comparison at
  the sitting settles which runtime globals are terrain-specific.

### 1.2 What the predecessor's crash records say

Records under `../dcs-api/docs/memory/` (`fault-signatures.md`, `crasher-matrix.md`,
`scripting-error-message-probe.md`, `argument-ladder-probe.md`, `export-ladder.md`). They are
this maintainer's own prior measurements and enter this plan only as a safety input, the deny
list in 3.2; no fact in the output cites them.

| Run | Probed | Crashed |
|---|---|---|
| `scripting`, every function called bare, build 2.9.28 | 308 | 5 (about 1.6%; Wilson 95% interval about 0.7% to 3.8%) |
| `scripting`, cited-argument ladder, 2.9.28 | 112 targets, 451 trials | 1 |
| `scripting`, the same ladder, 2.9.29, known killers excluded | 112 targets | 1 |
| `export`, 2.9.28 | 69 targets | 1 |

Lessons the records state: a crash is an access violation that `pcall` does not catch; a
killer can stop killing between builds; a missing string argument reaching `strlen` is the
common bare-call fault; a nested table returned across states crashes; `land.getHeight` with
no mission loaded crashes; the heap fault can fire later than the call.

What `../dcs-eval` already provides, so the plan builds none of it: `B|<id>` and `O|<id>`
markers per request in `events.log`; the request file deleted before the chunk runs, so a
killer is never re-run on restart; a `stale-session` refusal after a restart; the reply
ceiling published in the handshake; a pending reply collected later with `dcs_collect`; death
detection from heartbeat and process id; state targeting by name for `hook`, `gui`,
`scripting`, `mission`, `config`, `export` and `missionscripting`.

### 1.3 The predecessor's skill

`../dcs-api/.agents/skills/dcs-api-lookup/SKILL.md` exists; `consuming-the-model` does not
exist on disk. The skill's query is one grep on `index/<state>.tsv` and one bounded `sed -n`
read of `defs/<state>/…lua`, and its index row is `path kind impl arity ship proto states
trees sp mp-server mp-client defs`. This plan keeps the query shape and a shorter row (4.1)
and ships none of the predecessor's data.

### 1.4 The executor and the cockpit states

`../dcs-eval/executor/DcsEvalExecutor.lua` declares the states it answers: `hook`, `gui`,
`scripting`, `mission`, `config`, `export` and `missionscripting`. A cockpit device's Lua runs
in a state the executor does not name, so no sitting walks it. Row 1.6 takes that layer from
call sites instead. If a later executor build lists a cockpit state in its handshake, sitting B
walks it with two different aircraft in turn and keeps the globals both show, by the two-map
rule of 2.2.

---

## 2. Stages

Column key. **runs on**: `dev` needs no DCS; `DCS+human` needs a person at a running DCS.
**who verifies** is in the done-condition: `agent` reads the printed output itself; `CI` is
the maintainer reading a CI result; `person at DCS` is the sitting's operator. A row is done
when its one command prints the stated shape.

The DCS sittings are two: sitting A at the main menu and editor (2.1 to 2.3), sitting B with
a mission loaded and paused (3.1 and 3.2). Where the maintainer can keep DCS running through
both, they are one.

### Stage 0 — Scaffold

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 0.1 | One Rust crate, `dcs-api-docs`, with `full_moon` and the `dcs-eval` client crate pinned; subcommands `cites`, `defs-src`, `walk-ingest`, `db-ingest`, `probe-plan`, `probe-ingest`, `emit`, `describe`; `mise run check` builds and tests it | `mise run check` prints `build: ok, tests: N passed, clippy: 0 warnings`; verified by CI | — | dev |
| 0.2 | The read-only install facade: every read of the install path goes through one module exposing read calls only, and a test refuses a write import | `cargo test` prints `install facade: write imports: 0`; verified by CI | 0.1 | dev |

Departure from `CLAUDE.md`'s toolchain rule, stated here: one crate, not a workspace of crates,
and no driver, supervisor, ledger or merge-precedence machinery. The in-game walker and the
probe chunks are plain Lua files run through `dcs_eval_file`; the sitting's operator is the
driver.

### Stage 1 — Offline collection

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 1.1 | `defs-src`: parse every `.lua` under `Scripts/`, `MissionEditor/`, `Config/` with `full_moon`; record each function definition's name, parameter names, arity, variadic flag, file and span, and the comment block directly above it | `dcs-api-docs defs-src` prints `files: F, parse errors: E, definitions: D, with comment: C`; verified by agent | 0.2 | dev |
| 1.2 | `cites`: every call site of a dotted name in the same trees and in the `mission` table of every shipped `.miz`; per site the file, span, argument count and the literal type of each argument where it is a literal, `?` where it is not; aggregated per callee into a min and max arity and a per-position type set | `dcs-api-docs cites` prints `sites: S (install s1, miz s2), callees: K, with literal types: T`; verified by agent | 0.2 | dev |
| 1.3 | `vendor-text`: `API/Sim_ControlAPI.md` parsed into per-symbol descriptions and parameter lists, graded `D` | `dcs-api-docs vendor-text` prints `symbols: N, with params: P`; verified by agent | 0.2 | dev |
| 1.4 | `plugin-decls`: every call site of a plugin declaration function in `entry.lua` and the database scripts under `Mods/` and `CoreMods/`, collected as 1.2 does, with the declaring module as a column; a function called from more than one module is shared and ships; one called from one module only is listed and left out | `dcs-api-docs plugin-decls` prints `sites: S, functions: F, shared: K, single-module: M`; verified by agent | 1.2 | dev |
| 1.5 | `sdk`: the headers `API/include/Cockpit/ccParametersAPI.h`, `API/include/ed_object_access.h`, `API/include/FM/wHumanCustomPhysicsAPI.h`, `API/include/FM/wHumanCustomPhysicsAPI_ImplementationDeclare.h` and the sources under `API/ExternalFMTemplate/`, parsed with the `tree-sitter-c` grammar into function declarations, their parameters and the comment above each, emitted as `release/sdk/<header>.md` beside the Lua definitions; the preprocessor is not run, so a declaration under a conditional is emitted with its condition as text | `dcs-api-docs sdk` prints `headers: H, declarations: D, with comment: C, parse errors: 0`; verified by agent | 0.2 | dev |
| 1.6 | `cockpit-framework`: the cockpit and avionics API from static call sites, because the executor declares no cockpit state (1.4); every dotted or bare call under `Scripts/Aircrafts/_Common/` and under each module's `Cockpit/` tree, with the calling module as a column; a function called from `_Common/` or from more than one module is shared and ships, one called from one module only is left out; the `export`-side half of the framework (`GetDevice`, `LoGetAircraftDrawArgumentValue`) comes from the walk in 3.1 | `dcs-api-docs cockpit-framework` prints `sites: S, functions: F, shared: K, single-module: M`; verified by agent | 1.2 | dev |

Techniques. 1.1 is syntactic signature extraction over a concrete syntax tree; `full_moon`
keeps comment trivia and byte spans on Lua 5.1 source. 1.2 is call-site constraint
collection as in the Cartesian Product Algorithm of Agesen (1995), reduced to the base case:
each site contributes one tuple of argument types, a literal's type is known, anything else is
`?`, and no fixpoint over data flow is computed. That reduction is why the per-position type
set can hold `?` and why the plan states no coverage figure for it in advance; 1.2 prints the
figure. Full abstract interpretation is not attempted, because the mission-scripting surface
has too few sites for it to pay (1.1). 1.5 parses C with the `tree-sitter-c` grammar
(Brunsfeld, tree-sitter), a mature incremental parser; a full C front end such as libclang
would need the SDK's include paths and is more than four headers justify.

### Stage 2 — Sitting A: menu and editor

The operator starts DCS, opens the editor on one map, runs the chunks through `dcs_eval_file`,
then opens a new mission on a second map and runs the walk again.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 2.1 | The walker, `instrument/walk.lua`: from `_G` and the registry of one state, breadth first, with an identity map so a table is visited once; per node the path, Lua type, and for a function whether it is C or Lua with `debug.getinfo` source and line; the scrub applied inline from the first line (the username forwards, reversed and in 8.3 form, and every path-shaped string, replaced by a typed placeholder, never `nil`); output as JSON lines under the reply ceiling, continued across replies with a cursor | under the harness interpreter over a fixture state, `mise exec -- lua5.1 tools/walk-test.lua` prints `nodes: N, pii planted: P, caught: P/P, nil written: 0`; the scrub control is the one control this plan breaks on purpose; mutation: disable the reversed arm → `caught: P-2/P` → red, then restore; verified by agent | 0.1 | dev |
| 2.2 | The walk of `hook`, `gui`, `scripting`, `mission` and `config` at the menu, on map one, then of `gui` and `config` again on map two; `walk-ingest` scrubs again as a backstop and writes `observations/<date>-<state>-<map>.jsonl`; a global present on one map only is marked `terrain-specific` and excluded | `dcs-api-docs walk-ingest` prints per state `nodes: N, c functions: C, lua functions: L, backstop caught: 0`, and `terrain-specific: T` from the two-map diff; verified by the person at DCS reading the executor's reply and by agent reading the ingest | 2.1 | DCS+human |
| 2.3 | The `db` dump, `instrument/db.lua`, in the `gui` state with the editor open: `db.Units` by category, `db.Weapons` with CLSIDs, static object types, `db.Countries`, `wsTypes`, and the warehouse item names the editor's warehouse code lists; one row per entry, scrubbed, chunked under the reply ceiling; `db-ingest` writes `observations/<date>-db-<table>.jsonl` and marks each row with the module that declared it where `db` records one | `dcs-api-docs db-ingest` prints `tables: N, rows per table: …, rows with a module: M`; verified by the person at DCS and by agent | 2.1 | DCS+human |

### Stage 3 — Sitting B: a mission loaded and paused

The operator loads any mission that places a controllable aircraft, enters the slot, pauses,
and records the mission's name on the run. The two-map rule does not apply here.

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 3.1 | The walk of `missionscripting` through `a_do_script` and of `export` from the slot, with the same chunk as 2.1 and a string-only return; the operator reads `dcs_status`'s handshake and records whether a cockpit state is listed (1.4) | `walk-ingest` prints the two states' lines as in 2.2; verified by the person at DCS and by agent | 2.2 | DCS+human |
| 3.2 | The bounded probe (section 4): `probe-plan` writes one chunk per candidate from the cited argument shapes, safest first, with every candidate carrying its effect class and the deny list applied; the operator sends chunks one at a time; a crash names the killer from the executor's unbalanced `B\|` marker; at most two restarts in the sitting; `probe-ingest` writes the outcomes | `dcs-api-docs probe-plan` prints `candidates: N, denied: D, by shape: cited c, bare b`; `probe-ingest` prints `probed: P, answered: A, errored: E, killers: K, unknown: N-P`; verified by the person at DCS and by agent | 1.2, 3.1 | DCS+human |

### Stage 4 — Emit, describe, ship

| id | task | done when | needs | runs on |
|---|---|---|---|---|
| 4.1 | `emit`: joins the observations and the offline collections by `state:path` and writes `release/index/<state>.tsv` with the row `path kind impl arity states hazard grade defs`, `release/defs/<state>/<root>.lua` as LuaLS text, `release/data/<table>.tsv`, the shared modding functions of 1.4 and 1.6 as `release/defs/modding/<root>.lua`, and the SDK section of 1.5 beside them; each definition carries its source span or its probe outcome, and a fact nobody measured is written `unknown` | `dcs-api-docs emit` prints `index rows: R, defs: F, parse errors: 0, data tables: T`; `mise run check` runs `lua-language-server --check` over `release/defs` and prints `0 errors`; verified by CI | 2.2, 2.3, 3.1, 3.2, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6 | dev |
| 4.2 | `describe` (section 5): an agent writes a description for each symbol from the evidence the pipeline holds and nothing else, each description citing its evidence, or writes `no description: evidence insufficient`; `describe --audit N` prints a seeded random sample of N descriptions beside their cited evidence for the maintainer to read | `dcs-api-docs describe --check` prints `symbols: S, described: D, insufficient: I, uncited: 0`; the maintainer reads the audit sample; verified by CI for `uncited: 0` and by the maintainer for the sample | 4.1 | dev |
| 4.3 | The skill package, `.claude/skills/dcs-api-lookup/`: the query procedure as `SKILL.md`, the index, the defs and the data tables beside it; the README says what a consumer installs and runs and takes out every "not built" line this plan settles | a fresh checkout with only the package answers `does Group.getByName exist in missionscripting, and what does it take` in one grep and one bounded read; `mise run check` passes; verified by agent and by the maintainer | 4.2 | dev |

---

## 3. Who verifies, and what "done" means

A row is done when its command prints the stated shape. A sitting's row is done when the
operator saw the executor's reply and the ingest printed its line. `mise run check` is the
same set of gates CI runs. A check that exits 0 and prints nothing is not green.

---

## 4. The bounded probe

Goal: a signature, or `signature unknown`, for each C function a scenario reaches, with a
bounded number of crashes.

Order of evidence, cheapest and safest first:

1. **Static first.** A C function with an ED call site (1.2) gets its arity and literal types
   from the sites and is probed only to confirm the return type.
2. **Cited arguments.** A probe's arguments are copied from a cited call site, never invented.
   The call runs in its owning state, one call per chunk, with the sim paused.
3. **Bare call for the error text.** A C function with no site and no cite is called with no
   arguments, once, to read the argument-check error. This is the riskiest shape (1.2, about
   1.6% crashes), so it comes last and is bounded by the restart budget.
4. **Unknown.** A function the budget does not reach, or a killer, ships as
   `signature unknown`, which is a valid outcome.

Rules, each one measured in the predecessor's records:

- One call per chunk. The executor writes `B|<id>` before the chunk and `O|<id>` after; a
  crash leaves `B|` unbalanced and names the killer.
- A killer is recorded under `observations/killers.tsv` and never retried, in any build.
- Every candidate carries an effect class (`read`, `sim-write`, `barred`), and the deny
  classes (write, exit, network, state-mutating) are refused by `probe-plan` before anything
  runs. The predecessor's `barred` list and killer list are the deny list's seed.
- A string parameter gets a string argument; a bare call is never sent where the cited sites
  show a string at any position.
- Nothing returns a nested table across states; a probe returns one string.
- No cross-state call. `land.*` is probed only with a mission loaded.
- At most two restarts per sitting. When the second restart is spent, the remaining
  candidates are `unknown`.

Techniques. The marker discipline is crash triage by last-known-good record, the same shape as
a write-ahead log; the executor already implements it. Ordering candidates safest first and
stopping at a budget is the standard triage order for crash buckets (Glerum et al., Windows
Error Reporting, SOSP 2009). Delta debugging (Zeller and Hildebrandt, 2002) applies only when
a chunk holds more than one call; this plan sends one call per chunk, so a crash needs no
minimisation. Fuzzing is not used: the argument space is taken from cited sites, not generated.

Expected cost, from 1.2: the predecessor's bare-call run over the whole mission-scripting surface (1.2)
crashed at about 1.6%, which is more restarts than the budget holds. The two-restart budget therefore covers a reviewed subset, with the scenario
namespaces (`trigger`, `Group`, `Unit`, `coalition`, `world`, `timer`, `land`, `Airbase`,
`Warehouse`, `StaticObject`, `Controller`) first, and the rest `unknown`.

---

## 5. Descriptions

An agent writes the descriptions in 4.2 under these rules:

- The input is the evidence the pipeline holds for the symbol: its definition source and
  comment (1.1), its call sites with the surrounding lines (1.2), the vendor text (1.3), the
  walk's type and source span (2.2, 3.1), the probe's error text and return shape (3.2), and
  the `db` rows it names (2.3).
- Nothing else. No memory of DCS, no web, no community source. The agent runs with the tools
  it needs to read those files and no other.
- Each description states what the function does and what each argument is, and ends with
  `evidence:` followed by the file and span of each piece it used.
- Where the evidence cannot support a statement, the description says
  `no description: evidence insufficient` and names what is known, such as the arity alone.
- A description carries grade `A`; a vendor-text description carries `D`; both grades survive
  into the LuaLS text as `[A]` and `[D]`.

The maintainer's spot check: `describe --audit N` prints N descriptions chosen by a seeded
random draw, each beside its cited evidence lines, so a wrong description is visible without
opening anything. A description the maintainer rejects is deleted and the symbol falls back
to `insufficient`.

---

## 6. Rules this plan keeps

| rule | where it holds |
|---|---|
| The install is read-only, with no write probe | 0.2 |
| The scrub runs in the walker from its first line, never writes `nil`, and is backed up at ingest | 2.1, 2.2 |
| Raw executor replies live outside the repository; `observations/` holds scrubbed rows and is append-only | 2.2, 2.3, 3.1, 3.2 |
| `release/` is generated; a hand edit is refused | 4.1 |
| No cross-state call; a probe returns a string | 3.2 |
| A probe cites a call site or is a bare call; every candidate carries an effect class; the deny classes are refused | 3.2 |
| A killer is never retried | 3.2 |
| A fact nobody measured is `unknown`; no description without cited evidence | 4.1, 4.2 |
| Lua is 5.1.5 PUC-Rio for the harness; `tools/check-lua.sh` proves it | 2.1 |
| Conventional Commits, one pull request per row, landing is the maintainer's call | `CLAUDE.md` |

---

## 7. What the earlier plan had, and what this one does with it

Keep means folded in as above; shrink means kept in a smaller form; drop means not built. The
last column says what a drop costs in coverage or in correctness.

| idea | from | verdict | reasoning, and the cost of a drop |
|---|---|---|---|
| The scrub in the walker, typed placeholders, planted-PII control | old 1.3, model §10 | keep | the one control that prevents a leak; small Lua |
| `B\|`/`O\|` marker discipline, killer named from the unbalanced marker | old 1.6, 3.5, model §9.4 | keep, as the executor's own `events.log` | nothing to build |
| Killers carried forward, never re-probed | old D010 | keep | one TSV |
| Effect classes and the deny list on probes | old C.1, D009 | keep | a column and a filter in `probe-plan` |
| A probe cites a call site; no dictionary sweep | old D009, model §9.2 | shrink: cited first, then one bare call per function under a restart budget | a strict ban leaves most of the mission-scripting surface unprobed, because almost nothing cites it (1.1) |
| The cites collector over ED's Lua and the shipped `.miz` scripts | old 5.5 | keep | the main offline signal for the hook surface |
| Measured absence as a written fact | model §5 | shrink: one `unknown` spelling instead of four | the distinction between "not reached" and "measured absent" is lost; the index still never invents a symbol |
| The index row and the one-grep-one-read query | model §8, the predecessor's skill | keep, shorter row | the vantage and release columns go |
| Scenario-driven ranking of what gets described | `docs/SCENARIOS.md` | shrink: the scenario namespaces order the probe and the descriptions; no cut rule, no coverage denominator per scenario | everything reached ships; most GUI rows ship undescribed |
| The two-map comparison for terrain-specific globals | new | keep | one extra walk in sitting A |
| The two-module cross-check for the shared modding API | new | keep | a column and a filter in 1.4 and 1.6; no sitting |
| The fixture mission, matched by name and hash | old 3.2, captures §3 | shrink: any mission, its name recorded on the run | a probe outcome that depends on the mission is not detected; the probe surface here is small |
| Park and restore of Saved Games | old 3.1, 3.7 | drop | the walker and the probes write nothing under Saved Games; the executor's own files are its concern |
| The crash supervisor that relaunches DCS | old 3.5 | drop | the operator relaunches; two restarts per sitting |
| The driver, the plan verb, the session vocabulary | old 3.3, 3.4, D006 | drop | the operator is the driver |
| The run ledger, the collector manifests, ingest validation | old 2.2 to 2.4, model §4.1 | drop | provenance is the observation file's name and each row's source span |
| Merge with a precedence table, grades on every slot, conflicts file | old 6.2, model §4.3 to §4.5 | shrink: join by id, `unknown` where sources disagree, two grades `A` and `D` on descriptions only | a disagreement between a cite and a probe is not ranked; it is printed as `unknown` and listed by `emit` |
| The name ledger, aliases, renames gate | model §2.3, old 2.5, 6.4 | drop | a symbol's id is its `state:path`; a rename between builds is a new row |
| The 500-record chunk ceiling and `model/` as records | old 6.3, model §7 | drop | the release files are the model |
| The authored layer's entries, guides, examples runner, claims | old Stage 8, `docs/AUTHORED.md` | shrink: descriptions only, written by an agent from evidence, cited and graded | no guides; a guide was never finished in the predecessor either |
| The benchmark, the sealed set, the finish line N | old Stage 9, `docs/specs/benchmark.md` | drop | nothing measures whether an agent answers better with the docs; 4.3's one fixed question stands in |
| The mutation ritual for every control, the sweep | old §9, `docs/mutations.md`, `tools/sweep*.sh` | shrink: one control, the scrub, is broken on purpose once | a gate that stops reddening is not detected; the gates here print counts an agent reads |
| Multiplayer client and server releases | old Releases 2 and 3 | drop | the `mp-client` and `mp-server` columns do not exist; a symbol's presence on a server is not stated |
| The `export` walk from both vantages | old 4.5 | shrink: `export` walked once from the slot | the same-object report between the two vantages is not produced |
| The decision-record rule, the specification freeze | `CLAUDE.md` | shrink: the specifications are edited in place until the first build commit as before; after it, a record only where the reasoning is not in this file | nothing lost for a plan this size |
| The Rust workspace with crates per collector | old 0.7 | shrink: one crate | nothing lost |
| The reference-data emitter with a disagreement column | old 7.7 | shrink: rows from the runtime `db` only, the declaring module as a column | the on-disk declaration is not compared with the runtime row |
| The external-cites collector over MOOSE and MIST | old 5.5b | drop, by the maintainer's rule | no community call sites rank anything |
| The root gate against `docs/SCENARIOS.md`'s hypothesised roots | old 5.12 | drop | a root the scenarios name and nothing measures is simply absent from the index |

---

## 8. Open questions for the maintainer

- Whether to filter the `db` rows a module declares, or ship them with the module column.
- Which mission to load for sitting B.
- Whether the predecessor's killer and barred lists may seed the deny list (section 4 assumes
  yes, as a safety input, not as a fact).
