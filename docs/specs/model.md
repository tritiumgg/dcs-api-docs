# The model and its collectors

The settled model design for the rewrite. Every decision below is justified on its own evidence, in
the section where it is made.

**Citation convention.** A path written `prior:<path>` is a file in the superseded repository
this project replaces, cited as evidence and readable there on demand. **Nothing in the new
repository reads one at build time.** An unprefixed path is a file in the new repository — one this
document expects to exist, or tells you to create.

---

## 1. The commitments

1. **The walker names the graph; the cut names the model.** A locator grammar that addresses every
   node a census reaches, or accounts for it on its parent's `index` signature, is a requirement
   of the *evidence*, so two runs diff node for node. It
   is not a requirement that every node become a record. Addressability and record count are
   decoupled.
2. **A run is an entity.** Every fact points at a run. A run row is written before the run and never
   edited. Provenance is a foreign key, not a copied tuple.
3. **An id is pinned once and never recomputed.** A shorter path found later is an alias, not a
   rename. A retired id is never reused.
4. **A fact is a slot holding a winner, its proof, and the losing evidence.** An empty slot says
   which kind of empty it is, and some shapes that look empty are not absences at all.
5. **Runtime graph, source text and derived definitions are separate entity families**, joined by
   measured edges.
6. **What ED's shipped text asserts is admitted as a fact about the text**, in its own namespace,
   fenced and graded so no consumer can mistake it for a measurement. That rule, with its fences and
   its revisit condition, is §14.
7. **Scrubbing happens where the value is produced**, not where it is merged, and it is controlled by
   a planted-PII fixture verified by mutation.

---

## 2. Addressing and identity

### 2.1 The entity families

| Family | Prefix | Identity | Example |
|---|---|---|---|
| runtime graph node | `sym` | `state` `:` `root` `path` | `sym gui:.Bkg<meta>.__index` |
| source unit or span | `src` | install-relative file, optional line range | `src Scripts/Common/LuaClass.lua:1-81` |
| derived definition | `def` | `def` `kind` `/`-joined scoped name | `def enum wsType/Weapon/Torpedo` |

The prefix is part of the id, so one index holds every family and the consumer's grep stays one
grep. A runtime global `wsTypes` and a derived enum `wsType` can never be confused.

**Rejected: one family with `tree` distinguishing source from runtime.** A search path is not an
identity. A file on disk is not a location in a Lua state; it is a thing a state loaded, and that
relation is a measured edge (`declares`, §2.6).

**Rejected: an identity keyed on `(place, key)` alone.** It implies a rule that every id renders as
paste-able Lua syntax, and scoped enums, mechanism and dispatcher-mediated members each hold a fact
that is not a Lua path. `def enum wsType/Ground/Moving` is paste-able nowhere and is still the right
id.

### 2.2 The `sym` locator grammar

```
sym-id  := "sym " state ":" root path
state   := one of a closed vocabulary, declared once in this
           project's own type definitions and nowhere else:
             mission, hook, gui, scripting, missionscripting, config, export
             unplaced  -- reached by a container load, held by no state (2.4)
root    := ""            the state's _G
         | "@registry"   debug.getregistry(), where debug exists
         | "@loaded"     package.loaded
path    := step*
step    := "." ident                 string key that is a Lua identifier and not a reserved word
         | "[" json-string "]"       any other string key, JSON-quoted, so " + " and newlines survive
         | "[" integer "]"           integer key; -0 and 1e3 normalised to canonical decimal
         | "[" number "]"            non-integer number key, shortest round-trip repr
         | "[true]" | "[false]"
         | "[@" path "]"             a key that is itself a table/function/userdata holding a pinned
                                     name in the same state; the name is the key
         | "<meta>"                  the metatable of the node to the left
         | "<env>"                   the environment of the function to the left (reserved, §13)
```

Every step begins with `.`, `[` or `<`, so the grammar tokenises without lookahead and needs no
separator. The id is one line with no whitespace outside the family prefix and JSON strings, so
`grep -F` on any fragment works and the whole id sorts bytewise.

**Rejected: a dotted path with an escape hatch for weird keys.** A dot path addresses a fraction of
the `gui` graph; bolting brackets onto it keeps the identifier case privileged and leaves metatables
and object keys with nowhere to go. A grammar where the identifier step is one step class among the
rest has no privileged case to outgrow.

**Rejected: a content hash as identity.** A consumer types a name; the name must be the key.

### 2.3 The name ledger

A canonical path taken as the minimum over a *budgeted* walk's edge list lets a longer later walk
rename a record and dangle every `also_at`, `owner`, `inherits` and `def → sym` pointer. **The fix:
an id is pinned once and a later shorter path is an alias.**

`names/<chunk>.jsonl` is append-only, one row per path ever pinned or aliased:

```json
{"path":"gui:.Widget","id":"sym gui:.Widget","pin":"r15"}
{"path":"gui:.Button<meta>","id":"sym gui:.Widget","by":"r15"}
{"path":"gui:.A","id":"sym gui:.Widget","by":"r52"}
```

`canonicalise` runs offline over the run's capture edge list — the `node` and `key` rows of §9.6's
body, read straight from the capture — and, per object:

1. compute the run's own minimum path under the total order below;
2. look up **every** path that reached the object, including that minimum, in the ledger;
3. if any is already pinned, that pin is the id and the rest are appended as aliases;
4. if none is, the run's minimum is pinned and written with `pin: <run>`.

The total order, used only when nothing is pinned yet:

1. fewest steps;
2. then by step-class sequence, `.ident` < `["str"]` < `[int]` < `[num]` < `[bool]` < `[@ref]` <
   `<meta>` < `<env>`, position by position;
3. then bytewise on the rendered text.

A shared metatable shows why order 2 matters: `gui:.Button<meta>` and `gui:.Widget` are one table, so
rule 2 pins `gui:.Widget` and the metatable is named by what it is rather than by who reached it.

The ledger is an **input** to merge, not an output of it, so merge stays pure (§4.3). It is produced
by `canonicalise` from `(previous names, the run's capture edge list)` — append-only, therefore
deterministic and re-derivable. It reads the capture and not `observations/`, because ingest writes
observations under pinned ids and so runs *after* `canonicalise`.

**Rejected: recompute the canonical name every run.** It makes every pointer in the model a function
of walk budget. **Rejected: pin in the record itself.** `canonicalise` runs before merge writes
records and would have to read `model/` back, which is the defect §4.3 removes.

Cost: a pin row is ~48 bytes. The alias rows are measured at the first build, not predicted here.

### 2.4 `unplaced`, for records with no state

A container load reaches symbols that no running state holds. `sym` requires a state; `src` names a
file span, not a symbol. So the state axis carries a value for having no state:

```
sym unplaced:.me_db_api.templates
```

`unplaced` means: found in ED's shipped code by a container load, never observed in any running
state. It is a **measured** place, not a missing one — `dcs-api-docs coverage` can ask which runs had a
population that would have seen it. A record moves off `unplaced` the day a census reaches it, and
that move is a pinned-id change handled by §2.7.

The tree that reached an unplaced record is not lost: it becomes the `declares` edge from the `src`
span, which is where it was always a measurement rather than an address.

### 2.5 Worked examples — every awkward case in the findings

| Case | Id | Note |
|---|---|---|
| identifier key | `sym gui:.Widget.new` | the plain identifier case |
| integer key (findings §2.7) | `sym gui:.FULCRUM_INBOARD[7]` | a record only if the cut keeps it; otherwise summarised on the parent by an index signature, §3.6 |
| composite string key (findings §1.6) | `src Config/View/GroundCockpitQuake.lua` | the file loads into no Lua state, so the table is a `src data-table` and its rows have no `sym` id; the composite key structure — `"flak38 + genericAAA + 20x138B_HE + 20_00mm"` — is a `key_shape` fact on that record, §6.4 |
| metatable (findings §2.1) | `sym gui:.Bkg<meta>` | its `__index` is `sym gui:.Bkg<meta>.__index`; if the metatable is also `gui:.Widget`, §2.3 pins that and this is an alias |
| dispatcher-mediated member (findings §2.1) | `sym mission:.Group.getByName` | **the same id whether reached by walk, tier-2 index, or citation.** Reach is provenance, not identity |
| userdata key (findings §2.7) | none per key | an address does not survive the run. The parent carries `index: {key: userdata, n: …, values: <shape>}`. Naming things that cannot be re-found is identity by fiction — collapsing them into one `opaque` segment collides all of them into one record, and every descendant inherits the collision |
| table used as a key | `sym gui:.handlers[@.Widget]` | the key is the object pinned `gui:.Widget`; an unpinned key falls under the userdata rule |
| descendant of an unaddressable node | `sym gui:.FULCRUM_INBOARD[7].x` | addressable once integers are steps. The residue is descendants of unnamed object keys, covered by the parent's index signature carrying the value shape |
| registry root | `sym hook:@registry["_LOADED"]` | `debug` exists in `hook` (carried, findings §2.1); the root is a ceiling in `mission` |
| phase-conditional global (findings §2.6) | `sym mission:.AI` | identity is never conditional; the `exists` fact is scoped by role and phase, §5 |
| never in a state (§2.4) | `sym unplaced:.me_db_api.templates` | `me_db_api` is reached only by a container load (`prior:model/editor/`), in no state |
| source span | `src Scripts/Database/wsTypes.lua:1-70` | file spelling normalised to the install's own casing once, at collection |
| scoped enum member (findings §1.2) | `def enum wsType/Ground/Moving` and `def enum wsType/Weapon/Torpedo` | two definitions, wire value 8 each, §6.2 |
| cross-state value space (findings §2.3) | `def alias-class S_EVENT` | an equivalence class over `sym hook:.DCS.S_EVENT_*` and `sym mission:.world.event.S_EVENT_*`, basis measured |
| a `CoreMods/` table that loads into no state (findings §1.9) | `src CoreMods/aircraft/A-10/A-10C.lua:37` | A Lua-path identity has no address for these at all; they never enter a Lua state |

### 2.6 Edges

**An edge is not a kind.** A relationship is a field on its *source* record — `declares`, `cites`,
`edges`, `inherits`, `members`, `sym` — so it is stored in the source entity's own file and diffs
with it. The emitter builds `edges_in` as a derived index by inverting those fields at emit; no
record ever carries an `edges_in` field. Closed vocabulary:

| Edge | From → to | Measured by |
|---|---|---|
| `declares` | `src` span → `sym` | span join (file, first, last) between a container load and a census `debug.getinfo` |
| `cites` | `src` site → `sym` | the call-site collector |
| `inherits` | `sym` → `sym`, with `via` and `hop` | the mechanism collector, §6.1 |
| `same-object` | `sym` ↔ `sym` within one state | address equality in one run; folded into `also_at` by `canonicalise` |
| `same-value-space` | `def alias-class` → members | equal (suffix, value) pairs across states, measured |
| `member-of` | `def enum` node → `sym` | the banner-structure collector, §6.2 |
| `resolves-to` | `src` value → `src` file | foreign-key-by-filename, checked by the file existing, §6.8 |

### 2.7 When a record's identity changes

`model/` is tracked so its diff exposes a collector regression; id churn makes that diff unreadable
in exactly the situation it exists for. The rules:

1. **A pin is never recomputed.** §2.3. This removes the common case entirely — a shorter path,
   a different walk order, a larger budget all produce aliases, and the diff shows one appended
   ledger line and one `also_at` entry.
2. **An id changes only when the underlying fact changes**, and the changes that qualify are these:
   a symbol moves off `unplaced` because a census reached it; ED moves a symbol to a new
   path; a collector defect assigned the wrong id. Each is an event, not noise.
3. **The old id is retired, never deleted and never reused** — protobuf's `reserved`, which the
   findings recommend over `deprecated`. A retired row stays in `names/`:

   ```json
   {"path":"unplaced:.me_db_api.templates","id":"sym unplaced:.me_db_api.templates",
    "retired":"r61","reason":"observed-in-state","now":"sym gui:.me_db_api.templates"}
   ```

   A consumer following an old pointer lands on a row that says where the symbol went. A future run
   that computes the retired id as a candidate is refused by ingest.
4. **A rename is a reviewed event with a gate.** `dcs-api-docs merge` writes `RENAMES.md` — one row per
   id change with the old id, the new id, the reason and the run. `mise run verify` fails when the
   rename count exceeds a committed threshold and no `RENAMES.md` entry explains it. A collector
   regression that re-pins a thousand records fails the build instead of producing a thousand-file
   diff nobody can read.

**Rejected: silently re-filing** — colliding distinct symbols into one id, or recomputing the id
every run. Both make the tracked diff — the only reason `model/` is in git — worthless in the one
case it is for.

---

## 3. The record

### 3.1 Kind-tagged variants

A record's `kind` selects which fields are legal; the schema validator rejects a field outside its
variant (rustdoc's `ItemEnum`, findings §3). A malformed merge is caught structurally rather than
producing an all-optional record where anything is legal.

| Family | Kinds |
|---|---|
| `sym` | `function`, `table`, `scalar`, `userdata`, `thread`, `nil-slot` (a name observed absent) |
| `src` | `file`, `declaration`, `site`, `data-table` |
| `def` | `enum`, `alias-class`, `shape`, `union`, `bitmask`, `ceiling` |

**The kind list is closed**, and §3.6 states the legal fields of each.

**`class` is not a kind, and neither is `enum` as a category** — §6.1. A derived category kind
collapses idioms that differ, and is never earned by a measurement. Both are replaced by a measured
`mechanism` slot and a tree of `def enum` nodes.

**`edge` is not a kind and neither is `tree`.** An edge is a field on its source record (§2.6). A
tree is a set of `def enum` records carrying `scoped: true`, `levels` and `member-of` edges (§6.2);
there is nothing a `def tree` record would hold that those do not.

### 3.2 The slot, and its encoding

Every fact is a slot. A slot is either one of §5's absences or:

```yaml
luatype: {v: function, by: [r15, r41/index]}
```

`v` is the answer and `by` is the proof. **`kind` is not a slot**: it is the bare discriminator of
§3.1, written as a plain scalar on every record, and on a `sym` it is derived from the measured
`luatype` slot — `luatype: {v: function}` gives `kind: function`. A discriminator that carried its
own evidence would make the variant a function of provenance.

**The `by` suffix grammar.**

```
by-entry := run-id [ "/" reach ]
reach    := walk | inspect | index | cite | call | survey
```

Nothing else is a legal suffix: the suffix names how the fact was *reached* (§4.2), not the run's
`origin` or `method`, both of which the run row already carries. A run-less `r/` is a typo and
ingest refuses it. The suffix is omitted where the run's manifest declares a single reach, because
the run row then says it once.

Where another value was observed, the slot takes block form and keeps it:

```yaml
impl:
  v: lua
  by: [r03]
  scope: {role: sp, phase: mission}     # only where the fact is conditional
  also:
    - {v: c, by: [r41], lost: rank}     # rank | build | version | tie
```

`lost: tie` means unresolved: both stand, and the pair is a row in `CONFLICTS.md`. Merge never picks.

**The canonical serialisation is the flow mapping for a scalar `v` with no `also` and no `scope`, and
block form otherwise.** This is a size decision: always-block form makes every record three times
taller in the diff `model/` is tracked for.

**Rejected: a record-level `evidence[]` plus a field-level `superseded[]`.** The first cannot say
which field a row supports, so it is repeated for all of them; the second degenerates into restating
that the symbol was seen again on the next build, which the run's build in `by` already says. One
slot shape does both jobs.

### 3.3 Worked records

A function reached by tier-2 indexing and by citation:

```yaml
- id: "sym mission:.Group.getByName"
  kind: function
  luatype: {v: function, by: [r41/index]}
  exists:
    v: true
    by: [r41/index, r07/cite]
    scope: {role: sp, phase: mission}
  # impl carries no key here: the ceiling that covers it is state-scoped and is held
  # once on `def ceiling impl-untagged/mission` (§4.4). The emitter joins the scopes.
  owner: "sym mission:.Group"
  reach: index                    # how the record was first established
  signature:
    overloads:
      - params: [{name: name, t: string, optional: false, by: [r07]}]
        returns: [{t: "Group?", by: [r07]}]
        min_arity: 1
        by: [r07]
  cites:
    n: {v: 14, by: [r07]}
    sample: ["src Scripts/AI/x.lua:120"]   # up to 5, lowest file then lowest line
```

A table whose members are dispatcher-mediated:

```yaml
- id: "sym gui:.Bkg"
  kind: table
  luatype: {v: table, by: [r15]}
  exists: {v: true, by: [r15], scope: {role: sp, phase: menu-or-editor}}
  meta: {v: "sym gui:.Bkg<meta>", by: [r15]}
  dispatch:
    v: {index: function, src: "src Scripts/Common/LuaClass.lua:23-31"}
    by: [r15/inspect]
  mechanism: {v: LuaClass, by: [r15/inspect, r03]}
  mutability: {v: frozen, by: [r15/inspect]}      # __newindex errors on any write 
  members:
    enumerable: {absent: unenumerable, ref: dispatch}
    known:
      - {id: "sym gui:.Bkg.new", reach: cite}
      - {id: "sym gui:.Bkg.setSize", reach: index, from: "sym gui:.Widget", hop: 1}
    tried: {n: 23, found: 19, by: [r41]}          # tier-2 candidates, both outcomes
```

A plain data table carries an index signature with per-field counts — the findings' "seen in N of M",
whose documented failure mode is silent under-generalisation:

```yaml
  index:
    v: {key: integer, n: 30, contiguous: true, values: {shape: "def shape FULCRUM_INBOARD.item"}}
    by: [r15]
```

```yaml
- id: "def shape FULCRUM_INBOARD.item"
  kind: shape
  of: 30                                # the population the shape was inferred over
  fields:
    x:    {t: number, seen: 30}
    y:    {t: number, seen: 30}
    name: {t: string, seen: 27}         # optional by measurement, not by inference
  variants: []                          # non-empty only where field sets are incompatible, §6.7
  by: [r15]
```

A `src` record:

```yaml
- id: "src Scripts/Common/LuaClass.lua:1-81"
  kind: declaration
  declares: [{to: "sym gui:.LuaClass", by: [r15, r03]}]
  edges: [{e: cites, to: "sym gui:.setmetatable", at: 40, by: [r07]}]
  mechanism_site: {v: LuaClass, by: [r03]}
```

### 3.4 Type expressions

Wrappers compose; flags do not multiply (GraphQL's `NON_NULL`/`LIST`, findings §3).

```
T   := lua-primitive | "sym …" | "def …" | def-path | "self"
     | T "?"                 nullable
     | T "[]"                list (integer-keyed, contiguous)
     | "{" fields "}"        inline shape, in observations only; merge lifts it to a def shape
     | T "|" T               union — only where a probe or a site observed distinct call shapes

def-path := "def enum " name ".path"
                             an ordered tuple of members from one scoped enum whose
                             `parent` chain is contiguous, §6.2
self     := "self"           the table under construction: the record the type is written
                             on, measured by the identifier matching the declaration's own
                             name, §6.6. Legal only inside a `src data-table` record.
```

A primitive may carry facets — `{t: number, min: 108, max: 174, unit: MHz}` (OpenAPI's `format`,
findings §3). A string may carry a **value-class histogram** measured over a population, never a
classification rule: `{t: string, classes: {guid: 412, bare: 37, braced-non-guid: 3}}`. That is the
payload `CLSID` case, where `"{CBU-87}"` is GUID-shaped and is not one, so a "looks like a GUID" rule
misclassifies it and a histogram does not.

**Overloads are a list, never a unioned parameter** (TypeScript, findings §3). Probing discovers "this
accepts a number *or* a table" as two call shapes; collapsing them loses which returns what.

### 3.5 Qualifiers that invalidate rather than overwrite

Each says the value cannot be taken as read, and why:

- **`machineLocal`** — the value was a rooted path or one person's, withheld, and the record says so.
  Under §5 this is spelled `{absent: withheld, why: …}`.
- **`varies`** — two readings of one build disagreed, so the value is a sample. **Sticky and
  one-directional**: disagreement disproves constancy, agreement proves nothing. Derived, not
  written: two `observed` readings at one build that disagree.
- **`min_arity`** — a lower bound, deliberately **not** folded into `optional`, which is an upper
  bound. They are different measurements and a merge that folds them loses one.

**`optional` is tri-state — `true | false | unknown`**. Where it is written from inference, an
inferred `false` is otherwise indistinguishable from a parameter no run read. The default is
`unknown`, and `unknown` is written, because here the missing key would mean "no run measured this
parameter at all", which is a different fact.

### 3.6 Fields by kind

§3.1 says a record's `kind` selects which fields are legal. This is that list: for each kind, every
field the schema validator admits, whether it is a **slot** (`{v, by}`, §3.2,
and therefore gradeable and absence-spellable) or a **bare structural field** (a plain value, no
evidence of its own), and what it holds. A field outside its variant is refused at ingest, as is a
slot a collector's manifest does not declare in `writes` (§9.1).

**Reading rules.**

- Every slot may take any of §5's absence spellings, with the standing exception that "not yet
  measured" is the missing key and is never written (§4.4). A row states an absence only where the
  field's absence is special.
- A bare structural field is present or it is not; there is nothing to grade and no absence to
  spell.
- `by` at **record level** is legal on `def` records only, where the record as a whole is one
  assertion; it grades that record's bare fields. A `sym` or `src` record has no record-level `by`.
- A slot may additionally carry `scope`, `also`, `lost` and `varies` (§3.2, §3.5). `varies` is
  derived at merge from two `observed` readings at one build that disagree; it is never written by a
  collector.
- A value inside `v` may be a **typed value** rather than a plain one. The kinds are closed:
  `{msgid: "No weapon"}` (§11) and `{redacted: "path" | "user" | "host"}` (§10). Any other is a
  schema error.

#### Common to every kind

| Field | Form | Holds |
|---|---|---|
| `id` | bare | the id, §2.1. The only mandatory field besides `kind` |
| `kind` | bare | the discriminator, §3.1. Never a slot (§3.2) |
| `also_at` | bare list of ids | alias paths pinned to this id in `names/`, plus `same-object` edges folded in by `canonicalise` (§2.3). Missing where there are none; never `[]` |

`ship` is **not** a record field. The cut computes it at emit (§7) and it exists only in the index
row.

#### `sym` — `function` `table` `scalar` `userdata` `thread` `nil-slot`

| Field | Form | Kinds | Holds |
|---|---|---|---|
| `luatype` | slot | all but `nil-slot` | the measured Lua type: `function \| table \| number \| string \| boolean \| userdata \| thread`. `kind` derives from it. On a `nil-slot` the key is missing, because there was no value to type |
| `exists` | slot | all | boolean. Carries `scope: {role, phase}` where the fact is phase-conditional (§6.8). A `nil-slot` is the record whose `exists` is `{v: false}` |
| `owner` | bare id | all | the record this name hangs off — `sym mission:.Group` for `sym mission:.Group.getByName`. Missing on a root |
| `reach` | bare | all | how the record was **first** established: `walk \| inspect \| index \| cite \| call \| survey`. Written once and never revised; later reaches show up as `by` suffixes |
| `cites` | slot | all | `{n: <slot>, sample: [src ids]}` — the call- and reference-site count, with a bounded sample taken lowest file then lowest line. `uses/` carries every site (§8) |
| `hazards` | slot | all | a list of `{call, key, fault}`. `fault` is closed: `process-exit \| hang \| corruption \| error`. Absence is never a clearance (§12.1) |
| `requires_before` | slot | `function` | the id of the call that must precede this one for it to succeed — `{v: "sym mission:.world.addEventHandler", by: [r58/call]}`. Measured by a supervised probe (§9.2 tier 3 carve-out) that calls it in both orders and classes the failure; nothing else may write it |
| `meta` | slot | `table`, `userdata` | the id of the metatable node, `sym gui:.Bkg<meta>` |
| `dispatch` | slot | `table` | `{index: function \| table, src: "src …"}` — the structural fact that reads are mediated, §6.5 |
| `mechanism` | slot | `table`, `userdata` | the closed vocabulary of §6.1. An idiom outside it is `{absent: measured}` and a report row |
| `mutability` | slot | `table` | `frozen \| mutable`. `frozen` where `__newindex` errors on any write |
| `role` | slot | `table` | derived, closed vocabulary: `module-boilerplate` (from `mechanism: dxgui-module`, §6.1). The emitter filters on it; the model keeps the fact |
| `members` | bare block | `table` | `{enumerable, known, tried}`. `enumerable` is a slot whose absence may be the **non-absence** `{absent: unenumerable, ref: dispatch}` (§5). `known` is a list of `{id, reach}` with `from` and `hop` on inherited rows. `tried` is `{n, found, by}`: tier-2 candidates with both outcomes, a measured absence per miss (§6.5) |
| `index` | slot | `table` | the index signature: `{key, n, contiguous?, values: {shape: "def shape …"}}`. `{v: {n: 0}}` is a count at one instant and is never lifted (§5) |
| `key_shape` | slot | `table` | `{delimiter, arity, parts: [{distinct, sample}]}`, §6.4 |
| `signature` | bare block | `function` | `overloads: [...]`, a list and never a unioned parameter (§3.4). Each overload is `{params, returns, min_arity, by}`; each param is `{name, t, optional, by}` with `optional` tri-state (§3.5) and `t` a §3.4 type expression; `min_arity` is a lower bound and is never folded into `optional`. The index's `arity` column renders `min_arity` |
| `impl` | slot | `function` | `lua \| c`. `{absent: ceiling, ref}` is legal here **only where the ceiling's scope is this symbol**; a state-scoped ceiling is held once on its `def` and joined at emit (§4.4) |
| `value` | slot | `scalar` | split into `value.declared` and `value.observed` by §4.3. May hold a typed value |

`inherits` is an edge and therefore a member row's `from`/`hop` plus the `via` the mechanism
collector measured (§2.6, §6.1); it is not a field of its own.

#### `src` — `file` `declaration` `site` `data-table`

| Field | Form | Kinds | Holds |
|---|---|---|---|
| `declares` | bare list | `file`, `declaration`, `data-table` | `[{to: "sym …", by: [...]}]` — the span join of §2.6 |
| `edges` | bare list | all `src` kinds | `[{e: cites \| resolves-to, to: <id>, at: <line>, via?, by: [...]}]`. The emitter inverts these into `edges_in`; no record carries `edges_in` |
| `mechanism_site` | slot | `declaration` | the idiom recognised at the declaration, same vocabulary as `sym.mechanism` |
| `fields` | bare map | `data-table` | name → `{t, seen}`, with `resolves` and `checked: {ok, missing}` on a foreign-key-by-filename field (§6.6) |
| `index` | slot | `data-table` | as the `sym table` index signature |
| `key_shape` | slot | `data-table` | as above; this is where `Config/View/GroundCockpitQuake.lua` carries its composite keys (§2.5, §6.4) |
| `luatype` | — | — | never legal on a `src` record. A file is not a value in a state |

#### `def` — `enum` `alias-class` `shape` `union` `bitmask` `ceiling`

| Field | Form | Kinds | Holds |
|---|---|---|---|
| `from` | bare id | `enum`, `union`, `bitmask` | the `src` span the definition was read at. Required where the record's origin is `vendor-text` (§14) |
| `parent` | bare id | `enum` | the enclosing node; absent on the root |
| `scoped` | bare bool | `enum` | root node only: the members are a tree and identity is the path (§6.2) |
| `levels` | bare int | `enum` | root node only |
| `value` | slot | `enum` | the wire value. Collides freely across branches; identity is the path |
| `sym` | bare list of ids | `enum` | the `sym` records holding this member, across states. The `member-of` edge, read from the definition side |
| `members` | bare list | `union`, `bitmask`, `alias-class` | on a `union` or `bitmask`, `[{name, v, by}]` — tokens and values, never prose (§14); on an `alias-class`, the `sym` ids of the equivalence class (§6.8) |
| `reserved` | bare list | `bitmask` | documented gaps, recorded and never guessed |
| `probe_verified` | slot | `union`, `bitmask` | fills with the run when a probe reads one of these values off a live field (§6.3). The key is missing until then. **`verified` is the authored layer's field on an entry (`AUTHORED.md`) and is never a model field**; the two are separate measurements and sharing a name would make one look like the other |
| `basis` | bare block | `alias-class`, `ceiling` | `{by, observed, coverage}` — what was measured, and over what population. An `alias-class` basis is every equal `(suffix, value)` pair (§6.8); a `ceiling` basis is the totality count of §4.4 |
| `of` | bare int | `shape` | the population the shape was inferred over |
| `fields` | bare map | `shape` | name → `{t, seen}`; `seen: N` against `of: M` is "seen in N of M" |
| `variants` | bare list | `shape` | non-empty only at a real type boundary (§6.7); the discriminator is the field set |
| `field` | bare | `ceiling` | the field name the ceiling covers |
| `scope` | bare block | `ceiling` | `{state: …}` for a state-scoped ceiling, `{id: …}` for a per-symbol one. The emitter joins record scope against it (§4.4) |
| `revisit` | bare string | `ceiling` | the condition under which the ceiling is recomputed. A ceiling is never carried: it is re-earned by totality within its scope or it is gone |

#### `scope`, and the phase vocabulary

`scope` on a **slot** is `{role, phase}` and says the fact is conditional on them:

```
role  := sp | mp-client | mp-server
phase := menu-or-editor | mission | mission-paused | sim-paused | loading
```

`multiplayer` is a **role**, never a phase. The executor reports the game's state as axes, with the
mission editor and the main menu one value; the driver projects those axes onto this pair and
stamps the run row (§4.1) and the slot. Two readings under different scopes that agree stay under
one `v`; where they disagree they are `also` rows carrying their own `scope` (§6.8).

`scope` on a **run row** is what the run enumerated (§4.1); `scope` on a `def ceiling` is the
population the ceiling claims (§4.4). They are different shapes on different entities and the
name is the same because the question is: *over what*.

#### State spellings the transport accepts

The state axis of `sym` ids is the closed vocabulary of §2.2 and nothing else. The
executor's own spellings are aliased into it once, at collection, and never enter an id:

| Spelling | Resolves to |
|---|---|
| `server` | `scripting` — one state under two names, measured equal by address |
| `scripting` | itself |
| `userhooks`, `userhook` | `{absent: measured}` — asked for, not a state in this build |
| `zone`, `zones` | `{absent: measured}` — asked for, not a state in this build |

A spelling that resolves to a measured absence is a run row's negative result, not a silent drop: a
run that asked is evidence that the name is not there.

---

## 4. Provenance and merge

### 4.1 The run ledger

`runs.yaml`, one row per run, written **before** the run begins and closed after. Every fact carries
a short reference into it rather than a copy of it.

```yaml
- id: r15
  method: runtime-reflect
  origin: runtime               # runtime | source | inference | vendor-text | external | authored
  collector: census@3
  build: 2.9.29.27278           # read from autoupdate.cfg, never typed
  role: sp
  vantage: hook
  config: parked-standin-sp
  phase: mission-paused
  date: 2026-09-05
  capture: {path: 2.9.29.27278/census-gui-sp, sha256: …}
  scope:                        # what the run enumerated
    states: [gui]
    roots: ["", "@registry"]
    budget: 500000
    reached: 445960
  controls: {positive: pass, mutation: pass}
  status: complete              # planned | running | complete | crashed | aborted
  supersedes: r12
```

**One spelling, `scope`, and it is derived rather than typed.** The driver computes it per
collector when it closes the row:

| Collector reach | `scope` comes from |
|---|---|
| `walk` | the capture's `end` record (§9.6) — states, roots, budget, reached. Nothing is lifted into a transport header |
| `index`, `call` | the balanced `O\|` entries of the progress file (§9.4): the candidate list minus the entries that never completed |
| `survey` | the file list the container load was given, after the install facade resolved it |
| `inspect` | the walk it rode; an `inspect` run has no scope of its own |

**A run must record its own scope.** Without a statement of what a run enumerated,
"r41 walked `gui` and did not find it" is indistinguishable from "r41 walked `export`". With it, a
symbol inside an old run's scope and outside a new one is a **retirement**, which nothing today can
state, and the scope is what makes "not yet measured" a query rather than a belief (§5).

**Rejected: stamping the provenance tuple on every observation.** It dominates the model's bytes and
makes superseding a run an edit of every row that carries the tuple. Named graphs and Datomic
converged on run-as-entity for this reason.

### 4.2 Observations

A run's output is one immutable JSONL file, `observations/<run-id>.jsonl`, tracked in git, gzipped
above 8 MB. Immutability is the concurrency story: two branches never edit one run file, so the
evidence side has no merge conflicts by construction.

```json
{"id":"sym mission:.Group.getByName","f":"exists","v":true,"reach":"index","cand":"cands-7f3a"}
{"id":"sym mission:.Group.getFoo","f":"exists","v":false,"reach":"index","cand":"cands-7f3a"}
{"id":"sym gui:.Bkg","f":"dispatch","v":{"index":"function"},"reach":"inspect"}
```

`reach` is `walk | inspect | index | cite | call | survey` — the tier vocabulary of §9.2 plus the
offline container load, closed, and the same tokens the `by` suffix admits (§3.2). It is
provenance and it travels into `by` as a suffix, so a member established by indexing is visibly not
the same fact as one established by walking, on the same record, under the same id. `call` is legal
only under the supervised carve-out of §9.2.

**`cand` is a candidate-set id, not a per-candidate one.** `cands-7f3a` names the list a tier-2 run
was given, so every row of that run points at one ledger entry rather than carrying its own. The
ledger is `candidates/<id>.tsv` — one row per candidate with the `from` citation §6.5 requires — and
the set's hash is on the run row, which is what makes "we asked about 23 names, 19 existed"
reproducible.

Tracking observations rather than raw replies is `captures.md`'s recommendation and its arithmetic:
the observation tier gzips to a small fraction of the raw `.res` bytes, and the raw tier is the one
holding unstructured PII. **The raw replies stay outside the repository**, in a configured directory
defaulting to `../dcs-api-docs-captures`, and are never committed (§10).

### 4.3 Merge is a pure function

```
merge : (runs.yaml, observations/*, names/*, authored/*, precedence) → model/
```

It reads nothing back from `model/`. Idempotency is a consequence of purity, not of a fixpoint.

**Rejected: merge reading the committed model back as its own first input**, on the argument that
the model holds every tie so merging twice changes nothing. It makes a hand edit permanent and
unattributed, and it makes `model/` simultaneously input and output. The price of purity is that
observations must be kept, and §4.2 keeps them.

**Precedence ranks `origin`, never `method`.** `origin` is the closed vocabulary of §4.1 —
`runtime`, `source`, `inference`, `vendor-text`, `external`, `authored`. `method` is a free label
naming how a run worked (`runtime-reflect`, `constructor-shape`); it is ranked by nothing and merge
never reads it. `vendor-text` is an origin like any other, fenced by what it may write (§14) rather
than by being a special case in the ranking.

Resolution is per field group, and `value` splits into `declared` (a source literal,
`origin: source`) and `observed` (a runtime reading, `origin: runtime`), because they are different
facts and must not compete for one slot. The orderings, highest first:

| Group | Ordering | Why |
|---|---|---|
| `existence` | authored · runtime · source · inference | Whether a name is there is a measurement or a reading of ED's own code. `vendor-text` and `external` are excluded outright: **text may not create a name**, and a group that ranks them low still lets them win where nothing else spoke. |
| `types` | authored · runtime · source · inference | The same exclusion, for the same reason: a documentary source may never set a type (§12.3). Inference ranks last because its one producer is a bound, not a reading (§3.5). |
| `value.declared` | authored · source · vendor-text | A declared value is a literal in a file ED ships: the assignment outranks the comment that describes it. A runtime reading is not a declaration and belongs in the other half of the split. |
| `value.observed` | authored · runtime | A reading is a run or it is nothing. No other origin has read anything. |
| `signature` | authored · runtime · source · inference · vendor-text · external | A probe or an index beats a call site, a call site beats a bound, a bound beats ED's prose, and community text is the last word only where the project has none. |
| `receiver` | authored · runtime · source · inference · vendor-text · external | Who a method hangs off is measured the same ways in the same order; the group is separate so a receiver correction does not disturb the signature. |
| `usage` | source | A use is a site in a file, and the cites collectors are the only thing that can see one. Nothing else may write the group — an authored claim about where a symbol is used ranks a candidate (§6.5) and never becomes a fact. |
| `source` | authored · source · runtime · inference · vendor-text · external | The only group where `source` leads: a fact *about a file span* is read from the file, and a runtime `debug.getinfo` corroborates it rather than overriding it. |
| `semantics` | authored · vendor-text | No method measures meaning (§13), so the group is authored content graded `A`, with ED's own shipped text below it. `runtime` and `source` are absent because neither produces a semantic claim; a behavioural fact they *can* produce — `mutability`, `hazards`, `requires_before` — is not in this group. |

`authored` sits at rank 100 wherever it appears and `external` at rank 0. An origin a group does not
name may not write that group at all, and ingest refuses the row rather than ranking it last.

`precedence` is the input of that name in merge's signature above, and it lives in
`precedence.yaml` beside `runs.yaml` (§7), stating
exactly these orderings. `mise run verify` refuses a merge whose precedence file names a group or an
origin outside these vocabularies, or whose orderings differ from the ones above.

**`authored/` lives outside `model/`**, never inside the derived tree. An authored entry must cite a
basis — a run id or a decision number — may set `hazards`, declare a ceiling, exclude a name or
override a slot, and **may not create a `sym`.** It may create a `def` with a basis. Rank 100 stands
because its job is to correct a measurement the project has examined; the basis requirement is what
stops it becoming a way to write facts.

### 4.4 Rules the encoding forces

**Per-slot provenance is smaller than record-level provenance, not larger.** This is the opposite of
the intuition and it is why the rule survives contact with a size review. A record-level evidence
tuple cannot say *which field* it supports, so it is repeated for all of them: measured on a model
of this shape, those tuples and their superseded rows came to **most of the stored bytes**. A `by`
list on the slot says the same thing once. **Anyone who proposes collapsing
provenance back to the record to save space has the sign wrong.**

- **The "not yet measured" absence is never written.** It is the missing key (§5). Writing
  `hazards: {absent: unmeasured}` and `also_at: []` on every record spends bytes to say nothing, and
  it destroys the property that a present key means somebody measured something.
- **A state-scoped ceiling is stored once on its `def`, not referenced from every record it covers.**
  A ceiling is earned by **totality within its scope**: `impl` untagged on every `mission` record in
  scope is a state-scoped ceiling; untagged on a bit over half of `scripting`'s is not one, and no
  ceiling is ever carried from a previous release — each is re-earned by a check that recomputes the
  totality. Writing `impl: {absent: ceiling, ref: …}` on every record a ceiling covers denormalises a
  single fact, which is the defect §4.1 removes from evidence. The emitter and `dcs-api-docs coverage`
  join record scope against ceiling scope; the record omits the slot. **A per-symbol ceiling — one
  whose scope is the symbol itself — is written on the record**, because there it is not a
  repetition, and that is the only case in which `{absent: ceiling, ref}` appears on a record.

### 4.5 What the consumer sees, and how a grade survives

A `vendor-text` fence is easy to assert and easy to leave unimplemented, which matters because it is
what `external: 0` was protecting. The mechanisms, all required:

1. **Merge computes a grade per slot** from the highest-ranked run in `by`: `M` runtime-measured,
   `S` source-read, `I` inferred, `D` vendor-text, `A` authored, `!` conflict, `x` ceiling,
   `-` unmeasured.

   `I` has exactly one producer — the tri-state `optional` derived from call-site evidence (§3.5).
   No collector declares `origin: inference` for anything else, so an `I` on any other slot is a
   defect and ingest refuses it. `D` is vendor text at a `src` id inside the install and nothing
   else; an `external` basis grades `A` over a rank-0 citation.

   **`!` is computed at merge** — it is `lost: tie` on both values, the pair also being a row in
   `CONFLICTS.md`. **`x` is computed at emit**, by joining the record's scope against the scopes of
   the `def ceiling` records (§4.4); it cannot be read off a record, because a state-scoped ceiling
   is deliberately not written there. **Both must survive into the emitted text** as `[!]` and
   `[x]` beside the annotation, under the same gate as `[D]` below.
2. **The index carries the grade.** `sig` and `ret` become columns (§8).
3. **The LuaLS emitter renders the grade on the annotation itself**, not only on note lines: a grade
   that reaches only a note ships a `D`-graded type identically to a measured one. A `D`-graded
   `@class`, `@enum`, `@field`, `@param` or `@return` carries `[D]` inline:

   ```lua
   ---@enum whTarget [D] Scripts/Export.lua:666-675
   ---| 0x0002 # whTargetRadarView [D]
   ---| 0x0010 # whTargetEOSLock [D]
   ---| reserved 0x0080, 0x0100
   ```
4. **A gate in `mise run verify`.** For every slot graded `D`, `!` or `x`, the emitted defs text for
   that symbol must contain the marker. Positive control: a fixture def graded `D`. Mutation: remove the grade
   renderer, and the gate must fail. A grade that stops surviving is exactly the silent failure §10
   guards against elsewhere.

**There is no `.proto` projection.** Not because downstream generation is abandoned, but because a
projection is not what serves it: `model/` is the typed record, it is tracked, and anyone generating
bindings for another language reads it directly rather than through a lossy intermediate that has to
be kept in step.

**The obligation such a projection carries does survive: a loss report.** "Which facts does this
emitter drop?" is a question every emitter owes, and §4.5's grade gate is the LuaLS answer to it. A
future generator answers it for itself, against `model/`.

---

## 5. Absence: its spellings, and the shapes that are not absences

A slot with no `v` says which kind of empty it is. A plain missing key is exactly one of them.

| Spelling | Meaning | Who writes it |
|---|---|---|
| key missing | **not yet measured** — no run whose scope covers this id has a row for this field | nobody; it is the default, and §4.4 forbids spelling it |
| `{absent: measured, by: [r41]}` | **measured absent** — a run that could have seen it did not, or a tier-2 index returned `nil` | the merge, from a `v: false` existence row or from scope coverage |
| `{absent: ceiling, ref: "def ceiling …"}` | **no method reaches it** in this scope | the authored layer, with a basis that is itself a measurement |
| `{absent: withheld, why: machine-local}` | measured, known, not published | the scrub filter, §10 |

Some shapes are **not** absences and must never be spelled as one:

- **`unenumerable`** — `members.enumerable: {absent: unenumerable, ref: dispatch}`. A structural fact
  about the table: its `__index` is a function, so a walk cannot list its members. It converts every
  "the walk did not find it" under that table from *measured absent* into *not measured by walk*,
  which is the difference between a wrong answer and no answer. Tier 2 then measures per candidate.
- **empty at one instant** — `index: {v: {n: 0}, by: [r15]}` is a count of zero in one run. The merge
  never lifts it to "structurally empty". A second run at another phase makes it an `also`, and the
  consumer sees two counts with their phases. `warehouses.warehouses` is the case: one capture cannot
  tell empty-now from empty-by-construction.

A `def ceiling` is **scoped**, and earned by totality within that scope (§4.4):

```yaml
- id: "def ceiling impl-untagged/mission"
  kind: ceiling
  field: impl
  scope: {state: mission}
  basis:
    by: [r05]
    observed: "debug == nil in mission; type(f) yields an untagged 'function'"
    coverage: {records: N, untagged: N}   # the two must be equal: a ceiling is
                                          # earned by totality within its scope, §4.4
  revisit: "a build where reflection in mission returns a tagged function, or where debug is present"
```

**Rejected: `null` or a sentinel string in `v`.** A Lua `nil` value, a measured absence and an
unmeasured field would share one spelling, which is the confusion specified absence exists to
prevent.

`scope` on a run is what makes the first row computable. **"Not yet measured" is a query,
`dcs-api-docs coverage`, not a belief**: an id is unmeasured for a field when no run declaring that field in
its manifest has a scope covering the id. That query also produces the denominators nobody has today
— the fraction of reached nodes with a record, and the fraction of the install's Lua in any run's
file list.

---

## 6. The hard shapes

### 6.1 The class idioms, and native userdata

`class` is not a kind. Findings §1.1 measured several mechanisms sharing only `setmetatable`, one of
which — `class.lua` — answers `is_a` from a `_base` pointer the metatable chain does not follow. A
single derived `class` category would misrepresent the others. **The mechanism is recorded, not the
resolved category.**

- a **`mechanism`** slot on the `sym table`, closed vocabulary
  `class.lua | LuaClass | dxgui-module | native-userdata | plain-metatable`. Each value has a named
  producer:

  | Value | Measured by |
  |---|---|
  | `class.lua` | tier 1 resolves the `__index` function to a span and matches `src Scripts/class.lua:1-44`; the source collector sees `class(...)` at the declaration |
  | `LuaClass` | the same resolution against `src Scripts/Common/LuaClass.lua:1-81` |
  | `dxgui-module` | the source collector sees `module('Button')` + `Factory.setBaseClass` |
  | `native-userdata` | **the census walk**, from `type(v)` — it is a Lua type, not a fingerprint, so the walk that reads the type owns it and the mechanism collector never sees one |
  | `plain-metatable` | the residual: a metatable is present and no fingerprint above matched |

  **An idiom whose fingerprint is none of these produces `mechanism: {absent: measured}` and a
  report row, never a guess.**
- **`inherits` edges** carrying `via: metatable-chain | base-pointer | key-copy | module-factory` and
  `hop`. **`class.lua` yields two edges from one relationship** — `key-copy` for the members and
  `base-pointer` for `is_a` — because those are two different measured facts and a consumer asking
  "what does `is_a` say" needs the second.
- **the resolved member set flat on every record**, inherited rows carrying `from` and `hop`. Findings
  §2.4: `Button` carries most of its members tagged `[inherited:1]` from `Widget`, and every widget class
  repeats it. `Button.getPosition` is a member row on `Button` pointing at the definition
  `sym gui:.Widget.getPosition`; the definition record is owned by the hop-0 table and emitted once.
  **A consumer never walks `__index`** — findings §3 "avoid", with Luau's own checker as the evidence.
- **module boilerplate** (`_M`, `_NAME`, `_PACKAGE`, findings §2.5) stays measured and gains
  `role: module-boilerplate`, derived from `mechanism: dxgui-module`. The emitter filters on the role;
  the model keeps the fact, because "this table has `_NAME`" is how the mechanism was recognised.
- **`mutability: {v: frozen, by: [r15/inspect]}`** where `__newindex` errors on any write, as
  `LuaClass.lua` does. That behavioural fact finally has a field.

### 6.2 `wsTypes` — one integer, unrelated meanings, different branches

The riskiest shape the findings name: `wsType_Moving` and `wsType_Torpedo` both hold `value: 8`, and
each exists as a separate symbol in `gui`, `hook` and `scripting`
(`prior:model/scripting/wstype.yaml:2629` and `:3613`).

The `sym` records are untouched and never collided — they are two globals that hold 8. The enum is a
tree of `def enum` records, protobuf-style, scoped to the hierarchy node — `scoped: true` and
`levels` on the root, `parent` on every other node, `member-of` edges to the `sym`s. There is no
`def tree` kind (§3.1):

```yaml
- id: "def enum wsType"
  kind: enum
  scoped: true
  levels: 4
  from: "src Scripts/Database/wsTypes.lua:1-70"
  by: [r03]                            # the banners are comments: the run's origin is vendor-text,
                                       # so the grouping grades D (§4.5)
- id: "def enum wsType/Ground"
  kind: enum
  parent: "def enum wsType"
  value: {v: 1, by: [r03]}             # source grade: the assignment is Lua, not a comment
  sym: ["sym scripting:.wsType_Ground", "sym gui:.wsType_Ground", "sym hook:.wsType_Ground"]
- id: "def enum wsType/Ground/Moving"
  parent: "def enum wsType/Ground"
  value: {v: 8, by: [r03]}
  sym: ["sym scripting:.wsType_Moving", "sym gui:.wsType_Moving", "sym hook:.wsType_Moving"]
- id: "def enum wsType/Weapon/Torpedo"
  parent: "def enum wsType/Weapon"
  value: {v: 8, by: [r03]}
  sym: ["sym scripting:.wsType_Torpedo", "sym gui:.wsType_Torpedo", "sym hook:.wsType_Torpedo"]
```

**Member identity is the path in the tree; the wire value is a slot and may collide freely.** The
`Export.lua:653` tuple `type = {level1, level2, level3, level4}` gets the type
`def enum wsType.path` — members whose `parent` chain is contiguous — so the consumer learns that
position 2 is meaningful only under position 1.

**The grading is within one entity**, and this is the case that shows why grade must be per slot: the
level banners are comments and grade `D`; the member values are Lua assignments and grade `S`. A
record-level grade cannot say that.

**Rejected: a flat level number on each member.** A level is not enough. Two members at one level with
one value mean different things depending on branch, so a flat member list plus a level is undecodable
exactly where `wsTypes` needs decoding. This is structural, not additive: it cannot be added to a
design whose ids must render as paste-able Lua.

### 6.3 Facts that exist only in comments

Held by the `vendor-text` origin, fenced by §14 and graded through to the defs by
§4.5. The bitmask at `Scripts/Export.lua:666-675` becomes:

```yaml
- id: "def bitmask whTarget"
  kind: bitmask
  from: "src Scripts/Export.lua:666-675"
  members:
    - {name: whTargetRadarView, v: 2, by: [r22]}
    - {name: whTargetEOSLock,   v: 16, by: [r22]}
  reserved: [128, 256]            # the unexplained gaps, recorded as reserved, never guessed
```

The record carries no `probe_verified` key at all until a probe reads one of these values off a live
field: "not yet measured" is the missing key (§4.4), never a written absence. The slot is
`probe_verified` and not `verified` because `verified` is the authored layer's field on an entry
(`AUTHORED.md`) and the two measure different things (§3.6).

`Manufacturer = "RUS"/"USA"` and `LaunchAuthorized = true/false` become `def union` records the same
way. Tokens and values only; never prose.

### 6.4 Composite string keys

The bracket step names the row. The **parent** gains a `key_shape` slot measured over its keys:

```yaml
  key_shape:
    v:
      delimiter: " + "
      arity: 4
      parts:
        - {distinct: 41, sample: [flak38]}
        - {distinct: 12, sample: [genericAAA]}
        - {distinct: 87, sample: [20x138B_HE]}
        - {distinct: 9,  sample: [20_00mm]}
    by: [r08]
```

What each position *means* is not measurable and is not written. The delimiter, the arity and the
vocabulary per position are enough for a consumer to construct a valid key, which is the question they
had. Note that `GroundCockpitQuake` is in `Config/` and loads into no Lua state, so it is a
`src data-table` — an address a Lua-path identity does not have.

### 6.5 Dispatcher-mediated members

The mechanisms, all already shown: the `dispatch` structural slot (§3.6, tier 1), the
`members.enumerable: unenumerable` non-absence (§5), member rows with `reach: index | cite`, and
`tried: {n, found}` making the candidate list's negatives first-class **measured absences** — a fact
no other method reaches.

The candidate list is a run input, held as `candidates/<id>.tsv` with its id in the observations'
`cand` field and its hash in `runs.yaml` (§4.2), so "we asked about these names, these existed" is
reproducible and **"never a dictionary sweep" is auditable**: every candidate cites the row that
proposed it, and ingest refuses a candidate with no citation. The `from` vocabulary is closed:

| `from` | What proposed the candidate |
|---|---|
| `cite` | a call site in ED's own Lua under the install — including the trigger scripts inside ED's shipped `.miz` files under `Mods/campaigns/` and the training missions, which are ED's and inside the install |
| `text` | vendor text at a `src` id (§14) |
| `external-cite` | a community library named in `docs/SCENARIOS.md`, **ranked below `cite`**: it is evidence that somebody calls the name, not evidence from the product |
| `prior-run` | a capture this project took earlier |

An authored claim **ranks** a candidate and never authorises one: a candidate derived from a claim
carries a `cite`, `text` or `external-cite` row of its own, or it is refused.

### 6.6 Declaration data in `CoreMods/` and `Config/`

`src data-table` records with shape facts, not one `sym` per payload:

- **self-reference and heterogeneous arrays** (findings §1.7): a union measured over the population —
  `attribute: {t: "def enum wsType | self | string", seen: {enum: 3, self: 1, string: 2}}`. `self` is
  a type expression meaning "the table under construction", measured by the identifier matching the
  declaration's own name. `A-10C.lua:23`'s `index = A_10C` inside the literal defining `A_10C` is the
  case.
- **constructor calls** (findings §1.8): a `constructor-shape` collector records
  `troop(string, msgid, string)`
  as an overload with positional types and a call count. The call-site machinery already reads calls,
  so this is a permitted-field change, not a new parser. ~60 country files a literal-only parser sees
  nothing in.
- **functions as data** (findings §1.10): `fun: {t: function, seen: 3 of 3}`.
- **foreign key by filename** (findings §1.9):
  `radios: {t: "string[]", resolves: "src Config/DynamicRadios/Presets/<v>.lua", checked: {ok: 14, missing: 0}}`,
  with a `resolves-to` edge per value measured by the target file existing.
- **bounded ranges with units** (findings §1.9 radios): facets on the primitive, §3.4.
- **`external_profile(path)`** (findings §1.9 input bindings): an extends mechanism that is not
  `require`,
  recorded as a `resolves-to` edge with `via: external_profile`.

### 6.7 Kind-dependent field sets

A shape whose rows have incompatible field sets gets `variants`, merged only at a real type boundary
(GenSON, findings §3): `{down, up}`, `{pressed, up}`, `{down}` with counts. **The discriminator is the
field set itself**, because the data announces no tag — findings §3 "avoid discriminator-tag unions",
whose failure is pushing classification onto every consumer instead of solving it once at merge.

### 6.8 The remaining findings

- **Two namespaces, one value space** (findings §2.3): `def alias-class S_EVENT`, with a basis that
  is every
  (suffix, value) pair measured equal across `hook:.DCS.S_EVENT_*` and `mission:.world.event.S_EVENT_*`,
  and `members` listing both `sym`s. Several of §15's schema gaps close on this one kind.
- **Existence is phase-conditional** (findings §2.6): `exists.scope` carries `{role, phase}` in the
  vocabulary of §3.6. `mission:.AI`
  reflects absent at the `mission` root and present inside the sandbox; a walk at `menu-or-editor`
  and a walk at
  `mission-paused` produce two rows, kept under one `v` when they agree and as `also` when they do
  not. **Two phases of one state are censused separately and this rule is what joins them**; it is
  not an excuse to census a state once and assume the other phase.
- **Same identifier, different member sets across states** (findings §2.7): the id's state is what
  separates
  them; whether the two are one symbol is a `same-value-space` measurement, never a name match.
- **The reference surface**: stock Lua 5.1 plus LuaFileSystem, LuaSocket and ED's known
  additions are declared once in `authored/reference-surface.yaml`, and the census records
  **deviations**. Where DCS differs from stock Lua is the interesting fact, and undifferentiated
  records duplicated across every state bury it.

---

## 7. Storage

```
runs.yaml                       the run ledger, one row per run
precedence.yaml                 merge's ordering per field group, §4.3
candidates/<id>.tsv             a tier-2 candidate set with its citations, §6.5
captures/<build>/<run>/         the capture bodies a run produced, including the walk's
                                edge list — canonicalise's input, §2.3
observations/<run>.jsonl        immutable, tracked, gzipped above 8 MB
names/<chunk>.jsonl             the name ledger — path → pinned id, append-only
authored/                       outside model/ — descriptions, hazards, exclusions,
                                reference-surface.yaml, ceilings, overrides, guides
model/sym/<chunk>[.<n>].yaml    derived, flat, chunked by case-folded first path segment
model/src/<chunk>[.<n>].yaml
model/def/<chunk>[.<n>].yaml
generated/                      index/ defs/ uses/ data/ guides/ coverage — gitignored
COVERAGE.md                     committed derived artefacts: coverage, and what
RENAMES.md                        merge writes for review — a rename needs an entry
CONFLICTS.md                      before the gate passes, a tie is a row here
```

**Emitters write under `generated/`, which is gitignored, and a release ships that tree** as
`index/ defs/ uses/ data/ guides/` at its root (§8). Nothing under `generated/` is committed; the
committed derived artefacts are the summaries above, which are the ones a reviewer reads rather than
regenerates.

**`<group>` is the record's own state** — the state axis of §2.2, with `unplaced` a group like any
other — and it partitions every emitted artefact (§8). It is not a directory in `model/`.

**Flat, with no group directory *inside `model/`*.** There the group restates the place, and flat
filing is what makes a cross-state disagreement visible as a diff; in `generated/` the same group is
what keeps a consumer's grep bounded to the state they asked about.

**The cut.** Everything a census reaches is measured and every measurement is kept in
`observations/` and `model/`. The cut decides only what a release *ships*:

- A scenario in `docs/SCENARIOS.md` has a **measured root set**: the roots the cites collectors
  produced for it. The lists in `SCENARIOS.md` are hypotheses, and a root gate checks each against
  the measured set and prints added / unconfirmed / absent.
- A record ships when a scenario's measured root set **reaches** it — transitively, along `owner`,
  `members`, `declares`, `member-of` and the type expressions of §3.4.
- **`ship` holds the lowest-numbered scenario id that reaches the record**, or the name of the
  exclusion rule that dropped it (§13's rules, and the authored exclusions). `defs` is `-` exactly
  when `ship` names a rule, and never otherwise: that pair is what lets a reader holding only a
  release tell an exclusion somebody authored from a symbol nobody measured (§8).
- The cut is a **pure function** of the merged model, the measured root sets and the exclusion
  rules. It reads no wall clock and no previous release. `mise run verify` prints the dropped count
  and requires it byte-identical across two builds of one model state.

Sized against a post-cut population of this shape: chunking by case-folded first path segment
spreads the records over many small files and a few large ones, a sizeable minority of paths appear
in more than one state, and the cross-state disagreements between them fall on `impl` and on
parameter count — **never on `kind`**, which is what makes flat filing worth its cost.

**A chunk ceiling: 500 records per file.** Only a handful of chunks exceed it; splitting those into
ordinal parts leaves every file under the ceiling at the cost of a few extra files. A higher ceiling
splits fewer chunks and buys nothing: 500 is chosen because it bounds the largest file at a size a
reader and a diff can hold.

**Splitting is by ordinal part of the chunk's own sorted record order** — `skin.0.yaml`,
`skin.1.yaml` — so adjacency and determinism survive.

**Rejected: split an oversized chunk by second segment.** It multiplies files without bounding
them: `message` shatters into sub-chunks holding a handful of records each, and `db` still leaves a
part over the ceiling.

**Rejected: per-state directories.** They put the cross-state paths where nobody would compare
them, and hide their disagreements from the diff. The family directories are not the same thing: the family is part of the id, not a
restatement of a field, and cross-state adjacency is preserved inside `model/sym/`.

**`model/` stays tracked even though derived**, because the diff is how a collector regression becomes
visible — which is also why §2.7 exists.

---

## 8. The consumer surface

A release ships the tree the emitters wrote under `generated/` (§7), at its root. **The query stays
one grep and one bounded read**: grep the index, follow the `defs` pointer, `sed` that line range.

| Artefact | Holds |
|---|---|
| `index/<group>.tsv` | one row per record |
| `defs/<group>/<chunk>.lua` | LuaLS definitions, with the declaration span and a short call-site sample as a comment block |
| `uses/<group>.tsv` | **every** site: id, file, first, last, `call` or `read` — call sites and reference sites alike |
| `data/<table>.tsv` | the reference data as rows — units, weapons, countries, airbases, liveries — with a `---@class` shape per table in `defs/` |
| `coverage` | both denominators: against ED's `package.path`, and against the install's `.lua` files |

`<group>` is the record's state (§7), `unplaced` included, so a consumer who knows which state they
are writing for greps one file.

**`data/<table>.tsv` column contract.** The table's own columns first, in the order the source
declares them, then the columns every reference table carries:

| Column | Holds |
|---|---|
| `src` | the `src` id the row was read from — file and line range, so the row is re-readable |
| `by` | the run that read it, as a `by` entry (§3.2), which is what grades the row |
| `disagrees` | `-` where every source that states this row agrees; otherwise the other sources' values, so a disagreement ships rather than being resolved (§12.4) |

A row is never invented to fill a table, and a table whose sources disagree ships both readings with
the disagreement column populated; merge does not pick here either.

The index row:

```
id  kind  impl  arity  sig  ret  ship  states  trees  sp  mp-server  mp-client  also  hazard  defs
```

- **`sig` and `ret` carry the one-letter grades of §4.5**, so nobody needs `runs.yaml` at query
  time.
- **`ship` is not an alternative to `defs`.** **`defs` is the address** — `$NF`, the pointer a
  consumer follows with `sed` — and **`ship` is either the lowest-numbered scenario id that reaches
  the record or the selection rule that excluded it** (§7), where `defs` then holds `-`. That pair
  is what lets a reader holding only a release tell an exclusion somebody authored from a symbol
  nobody measured.
- **`also` is the alias count.**
- **`hazard` stays immediately before `defs`**, and `defs` stays last, because the consuming skill
  reads the pointer as `$NF`. Nothing is appended past it.
- **`states` must be defined afresh in the release documentation.** The id carries
  the record's own state, so the column holds the states in which an equivalent object was *measured*
  — populated from `def alias-class` membership and `same-object` edges, `-` where no equivalence was
  measured. `trees` is populated from `declares` edges, and a **tree label is minted by the survey**
  from the search path a file was loaded under (`editor`, `dxgui`, …); the set is closed per release
  and listed in `COVERAGE.md`, so a consumer can read the axis rather than infer it. Both keep their
  cross-file alignment purpose: a
  consumer greps `index/*.tsv` and rows from different files must line up.
- **A multi-valued cell is comma-separated with no spaces, sorted bytewise** — `states`, `trees`,
  and any other column holding a set. Sorting is what makes two releases diffable; the separator is
  a comma because no id, state or tree label contains one. An empty set is `-`, never an empty cell.
- **The role columns hold a grade where the role was measured and `-` where it was not tested.**
  `-` is not a negative result: a measured absence under a role is a grade like any other.

**Declaration spans and call sites both ship**, and every call site ships, not a sample.
Field feedback rates these the highest-value content in the model. **Spans ship with the build they
were read at** — a span pointing at moved lines is worse than no span, because the reader follows it
and believes what they find.

**`uses` records reads as well as calls.** An enum member's whole meaning is where it gets passed,
and that is a read; a surface where only functions carry cited uses cannot say it.

---

## 9. Collection

### 9.1 The layers

```
instruments   Lua 5.1.5, one source, host-parametrised   walk · inspect · index · call · survey
collectors    Rust, pure, manifest-declared              capture or install → observations/<run>.jsonl
driver        Rust, plan-shaped                          plan → session → runs → rederive → merge → emit
```

**Instruments** expose these primitives and nothing else. `walk(state, roots, budget, ceiling)` reads
and emits edges, and owns its own wire contract — record grammar, budgets, session and
self-exclusion — because the executor carries bytes and knows nothing about a census (§9.6).
`inspect(locator)` reads a metatable's `__index` identity and, where `debug` exists, its span.
`index(locator, candidate)` performs one metamethod-mediated read on the progress-file path. `call` is
the supervised probe path. `survey` is the offline container load.

**One resident source, `DcsApiDocsCensus.lua`, built for `hook` or `export` by a `HOST` constant**, and
the harness tests both builds. Separate per-host instrument files duplicate each other almost
verbatim (`prior:tools/hooks/DcsApiEval.lua`, `prior:tools/export/DcsApiExport.lua`) and drift apart
one fix at a time. `DcsApiDocsCensus.lua` is this project's own instrument and is not the executor's
`DcsEvalExecutor.lua`, which `../dcs-eval` installs and owns.

**The tooling is Rust**, with `full_moon` as the Lua parser — it keeps comment trivia and byte spans
and targets Lua 5.1, which is what the cites, fingerprint, comment-span and banner collectors need —
and the `dcs-eval` client crate for the executor protocol. Everything ships as one binary,
`dcs-api-docs <verb>`, and every command in this project is run as `mise run <task>`.

**Collectors** are pure functions with a manifest:

```yaml
name: census
version: 3
method: runtime-reflect
origin: runtime
needs: {capture: census}
reach: [walk, inspect]
writes: [exists, luatype, meta, dispatch, index, members, also_at]
scope: from-capture-end-record   # the derivation, §4.1; nothing is lifted into a header (§9.6)
msgid_aware: true                 # §11
controls:
  positive: "sym gui:.Widget exists"
  mutation: "drop one edge from the fixture; the run must report one fewer node"
```

**The manifest states which slots the collector may write, and ingest refuses any other.** It is also
what makes §5's "not yet measured" computable: a field is unmeasured for an id when no run whose
manifest declares that field has a scope covering the id.

**Every collector has a positive control and a mutation check, and the driver refuses to ledger a run
whose controls did not pass.** A clean run that exercised nothing is a failure, and a harness defect
presents as one.

### 9.2 The reach tiers

Findings §2.1's tiers, by what each executes. Indexing is not calling: `Group.getByName` runs
ED's dispatcher and returns a function value; `Group.getByName("x")` invokes DCS.

| Tier | What it does | Risk | Where it runs |
|---|---|---|---|
| **0 — `cite`** | ED's own shipped Lua names the member at a call site | none; no game | offline |
| **1 — `inspect`** | `getmetatable(T)` and examine the `__index` **function itself**; `tostring` for identity, `debug.getinfo` where `debug` exists, then read that source offline | none; nothing is indexed or called | **rides the census walk** |
| **2 — `index`** | index `T[candidate]` and record `type()` of the result. **Never call the result.** | executes ED's dispatcher on an unknown key | **the crash-tolerant probe path only, never the walk** |
| **3 — `call`** | call the value that comes back | kills DCS where `pcall` does not stop it | **barred** |

Tier 2's rules, which are what make it safe, and all of which are enforced by the plan rather than by
prose:

- **Candidates come from evidence, never from guessing** — a call site, a vendor document, a prior
  capture. Never a dictionary sweep. Enforced by the citation requirement of §6.5.
- **One candidate per round trip on the progress-file path**, so an unbalanced `B|` names the key that
  killed the process.
- **`pcall` is expected not to help.** The project has measured that these faults are not catchable.
- **Never on the census walk.** A crash mid-tier-2 must not cost the census.
- **The negative is a measurement.** Indexing a candidate and getting `nil` is a measured absence,
  valuable and unobtainable by any other method.

Tier 1 is the cheapest. **Caveat before relying on it:** `debug` is present in `hook` and absent
from `mission` (findings §2.1) — which is where `Group`, `Airbase` and `Controller` live — so tier 0
and tier 2 carry the load in the state that needs tier 1 most.

Tier 3 is barred: **never call across a state boundary, and never let a walk call at all.** The
supervised in-state probe path is a separate population, reproduced unchanged.

### 9.3 The agent and human split

The driver turns a request into a **plan**: an ordered list of steps, each `machine` or `human`,
grouped into sessions by launch configuration. The irreducible configurations are the session
vocabulary:

| Config | What it carries |
|---|---|
| `unparked-sp` | mission loaded and paused; probes and tier 2, which are the only things that need an unparked install |
| `parked-standin-sp` | the clean census of every state, `missionscripting` through `a_do_script` included; `export` from both sides |
| `parked-standin-mp-client` | the export-resident instrument alone, from a connected client |
| `parked-standin-mp-server` | the same vantage from the server side, where `scripting` is resident |

A session, as the `dcs-api-docs` CLI presents it — `dcs-api-docs plan`, `next`, `done` and `status` are verbs
of the one binary a human runs, and the agent path is a Claude Code skill over those same verbs, not
a second MCP server:

```
session parked-standin-sp
  [machine] register the park (state: parked)                   before anything moves
  [machine] park third-party scripts
  [human]   launch DCS                                          confirmed by executor handshake
  [machine] census gui, hook, config, scripting                 from the main menu
  [human]   load census-fixture.miz                             confirmed by executor phase change
  [human]   press Escape to pause                               NOT confirmable — ack required
  [machine] census mission, and missionscripting via a_do_script; export in-state
  [machine] close the run rows; restore parks
  [machine] register the park (state: restored)                 confirmed by the tree being back
```

The `a_do_script` walk of `missionscripting` is **read-only**, which is why it belongs in the parked
census session rather than beside the probes.

**Where a human step is confirmable by measurement, the driver waits on the measurement; where it is
not, it waits on an explicit ack and records in the run row that the step was human-attested.** Mission
load and pause are a person's step: `DCS.exe` exposes no mission argument and `net.load_mission` would
be a cross-state call from `hook`, which is barred.

The run row is written `status: planned` before the step and closed after — the same discipline as the
parks register, so a session that dies leaves a row saying what it was doing. **A session must not end
parked**; the plan ends with the restore and the register row, and `dcs-api-docs status` reports
an outstanding park at the start of the next session.

### 9.4 Crash tolerance

Tier 2 runs only on the progress-file path: `B|<id>` before, `O|<id>|<outcome>` after, one candidate
per round trip. On a crash:

1. the supervisor names the killer from the unbalanced `B|`, archives `dcs.log`, restarts —
   reproducing the behaviour of `prior:tools/probes/Invoke-ProbeSupervisor.ps1`;
2. the run row moves to `status: crashed` and its `scope` is derived from the balanced
   entries. **The run is still a run and its partial observations are still evidence**; the killer is
   written as `hazards: {v: [{call: index, key: getFoo, fault: process-exit}]}` on the parent record,
   graded `M`;
3. resumption starts a **new run** whose candidate list is the old list minus the covered entries minus
   the killer, with `supersedes: r41` on its row in the ledger. **Runs are never reopened.**

A crash on tier 2 costs at most one candidate, and the census never shares a process with tier 2.

### 9.5 Offline rederive and the golden corpus

`captures → observations` is deterministic and runs without DCS. A golden subset of captures is
committed under `corpus/golden/` and `mise run verify` runs `rederive` on it, then `merge`, then the
byte-for-byte determinism check on two builds of one model state. **CI runs** — GitHub Actions on
`windows-latest` — and `mise run check` mirrors it locally, so the recovery path is a gate rather
than an assumption whichever side runs it.

---

### 9.6 The walk's own wire contract

**The executor carries bytes and knows nothing about a census.** It evaluates a chunk in a state and
returns what the chunk returned, under a per-tick CPU budget, a per-chunk instruction budget and a
reply ceiling it applies to every evaluation. Everything below is the instrument's, shipped and
versioned with the collector that parses it, because a body format and its parser are one decision.

**The chunk carries its own state, in the state it is walking.** `walk` keeps its frontier, its
identity map and its session table under a single global in the target state — one name, declared in
the manifest. The executor holds no session and no cap. The consequences are the instrument's to
handle: a walk abandoned mid-run leaves that global behind, so the instrument owns
the verb that clears it; and the global is reachable from the walk itself, so it is **excluded by
identity, never by name** — the store is node 0, and any name match would be a second list to go
stale.

**The record grammar.** A sentinel first line, then TSV rows, then a terminating `end` record:

| Record | Carries |
|---|---|
| `node` | id, luatype, a short origin tag, the canonical path, depth |
| `key` | the owning node, the key as written, its type, detail, origin |
| `missing` | a path the walk was asked for and did not reach, with how it failed |
| `note` | something the walk observed about itself — a `__index` it declined to call |
| `truncated` | a value the emitter cut, and what it cut it at |
| `end` | status, stop reason, nodes, keys, frontier, identities, capped, holes, truncations |

Numbers are emitted at a precision that round-trips. A key that is not an identifier is spelled
`[3]`, `["a b"]`, `[true]`, `[<table>]` with its kind named, so a non-identifier key is never
mistaken for a dotted path.

**The `end` record is read from the body.** Nothing lifts its fields into a transport header. A
consumer that wants `frontier` parses for it, which is what it already does for every other row.

**Budgets are clamped inside the chunk, never refused.** Nodes, keys, depth and bytes each have a
range; a value outside it is a caller asking for more than the walk will do, not a malformed
request, and the `end` record reports what the walk actually did. The byte budget is held below the
reply ceiling, which is **an argument the driver passes in**: the executor publishes it in its
handshake, the driver reads it there and hands it to `walk` as a parameter. A chunk inside DCS
cannot read a handshake, and a walk called without a ceiling is refused rather than defaulted —
guessing the ceiling is how a body comes back cut.

**A body is refused whole, never cut.** If the walk would exceed the ceiling it fails with the
count and the limit and emits nothing, because a truncated body is *"a measurement with a hole it
cannot see"* — a consumer reading past the cut is parsing a record that was never written. This is
the same rule §5 states for absence, enforced at the wire: an incomplete measurement must not be
able to look like a complete one.

**`frontier` is what makes a walk resumable, and identity is what makes it terminate.** Depth is
bounded only if a caller asks; the `seen` map is what stops the walk, because a table visited twice
by two paths is one node. A `frontier` of zero is the only statement that a state is exhausted.

---

## 10. Scrubbing

Evidence is committed to git, so a machine-local filter that runs only at merge sits **downstream of
the artefact being committed**: it leaves `model/` clean and the captures dirty.

The requirements, all binding, none optional:

**1. The filter runs in the Lua walker, before a value enters the reply**, and it runs in layers:
the walker from its first line, a backstop at ingest, and a backstop at merge. Filtering in the
walker is what makes the raw captures safe, not just the committed artefact; the backstops exist
because a layer that only ever runs clean is a layer nobody notices has stopped working, and each
prints what it caught.

**2. Tokens are derived at run start, in-state, never hardcoded**: `lfs.writedir()` (which contains the
username), `lfs.tempdir()`, `lfs.currentdir()`, the install root, and the machine name where reachable.

**3. Every spelling is detected, over string keys as well as values** — a table keyed by username
leaks through the key:

| Form | Why it is not optional |
|---|---|
| the token, case-insensitive | the direct match |
| the token **reversed** | ED spells one path backwards — `me_openfile.rev_str` — and it is the proof that naive matching fails |
| the **8.3 short form** — six characters, uppercased, plus `~1` | a *derived* spelling that a token match misses entirely; the username occurs in more than one spelling across the captures (`captures.md`) |
| path-shaped patterns | the `ROOTS` regexes, below |

**The `ROOTS` set is normative and every arm is unanchored**, because a path appears mid-string far
more often than at the start of one:

| Arm | Matches |
|---|---|
| `[A-Za-z]:[\\/]` | a drive letter |
| `\\\\` | a UNC root, matched wherever it occurs and **not** `^`-anchored |
| `[\\/][Uu]sers[\\/]` | the POSIX arm — `captures.md`'s `/Users/` and `\Users\` pair is this one arm written both ways |

**4. A typed placeholder, never `nil`.** `{redacted: "path"}`, `{redacted: "user"}`,
`{redacted: "host"}` — the shape survives and the absence stays unambiguous. The `host` placeholder
is required wherever the machine name is reachable, and the planted-PII fixture carries a host
spelling so the control covers it. A silently dropped value
is indistinguishable from one nobody measured, which is the discipline the whole model rests on. This
is `{absent: withheld, why: …}` at the model tier.

**5. A planted-PII control, verified by mutation.** A fixture carries known PII in every spelling,
in keys and in values, and the test asserts the filter catches every one, printing `caught: N/N, all
planted`. Then break the filter
deliberately and the test must fail. **A scrubber that silently stops working is worse than none,
because the output looks clean** — the same standard every collector is held to.

**6. Collection runs only against a project-owned fixture mission.** No filter can tell a personal
mission name from a vendor one, so the source is controlled rather than filtered. No fixture `.miz`
exists yet. It must be **created, committed and hashed**, and `.gitattributes` must mark
`*.miz binary`. The check is split, because no method reports both halves: **the executor reports
the loaded mission's name from inside DCS and offers no hash**, and **the driver hashes the
committed `.miz` outside DCS**. The driver refuses to open a session unless the name it reads
matches the fixture's and the hash it computed matches the committed one. Until the fixture exists,
this requirement is a name and not a control.

**Never committed regardless**, whatever the filter says: crash dumps, `dcs.log`, and the supervisor's
rotated zips. They are unstructured, full of absolute paths, and no scrubber can be trusted against
them. The observation tier is structured and filterable, and it is what gets tracked.

---

## 11. The `_()` obligation, rehomed

Localisation is out of scope: the model holds no translations, reads no `.mo` catalog, and records
no locale counts. **One obligation survives that cut and needs an owner:**

> A collector must recognise `_()` and never record its argument as a value.

`_('No weapon')` is a gettext msgid. A parser that stores `"No weapon"` as a string value has recorded
a translation key and labelled it data. It lands where none of the landing places is localisation
machinery:

1. **The value-kind vocabulary.** `msgid` is a closed value kind alongside `redacted`, so the fact has
   a spelling: `value: {v: {msgid: "No weapon"}, by: [r08]}`. It is a *typed value*, exactly parallel
   to `{redacted: "path"}` — the shape survives and the reader cannot mistake the key for the text.
   No `domain`, no catalog, no locale count: those were localisation and are gone.
2. **The collector manifest.** A collector whose `writes` includes `value` must declare
   `msgid_aware: true`, and ingest refuses a `value` row from a collector that does not.
3. **A positive control verified by mutation.** A fixture source file contains `name = _('X')`; the
   collector must produce `{msgid: "X"}` and never `"X"`. Remove the `_()` recogniser and the control
   must fail.

The general lesson stands even though this instance is out of scope: **structure can hide inside
string content**, invisible to a schema that inspects only key and value types. The
`dash-prefix-tree` case — `shells=_('-Shells')`, `conventionalShell=_('--Conventional')` — is mission
editor display data and is not modelled, but its shape is why §6.4's `key_shape` exists.

---

## 12. Standing principles

The rules the rest of the design rests on.

1. **Closed vocabularies with specified absence.** Every axis an `as const` tuple, absence documented
   per field: `value` absent is not nil, `hazards` absent is never a clearance, `min_arity` absent is
   not zero. This is what makes the thing a measuring instrument, and §5 extends it rather than
   replacing it.
2. **Qualifiers that invalidate rather than overwrite** — `machineLocal`, `varies`, `min_arity`. §3.5.
3. **A documentary source can never create a symbol or set a type.** §14 preserves the principle
   while moving the fence: `external` stays at rank 0 everywhere, and `vendor-text` is a separate
   origin that may write only `def` entities, never a `sym` and never a slot on one. It is also
   excluded outright from the `existence` and `types` groups (§4.3), which is where "create a symbol
   or set a type" is enforced rather than merely ranked.
4. **Conflicts reported, never silently resolved.** Merge unions or refuses; it never picks. A tie is
   `lost: tie` on both values and a row in `CONFLICTS.md`.
5. **A positive control on every collector, verified by mutation.** §9.1, and the driver refuses to
   ledger a run whose controls did not pass.
6. **The machine-local filter tested backwards**, because `me_openfile.rev_str` spells a path
   backwards. §10 keeps that and adds the 8.3 spelling it lacks.

---

## 13. What is deliberately not modelled

| Not modelled | Why |
|---|---|
| Translation strings from `.mo` catalogs | ED's prose in every language it ships, outside the Lua surface, and reproducing it is out of scope. The msgid is modelled as a typed value; the text is not. |
| Per-key identity for userdata, function and unnamed-table keys | An address is run-local. A name that cannot be re-found is not an identity; the parent's index signature with a count is the honest fact. |
| Every integer-keyed node as a record | The grammar names them all so the evidence is lossless; the cut keeps only nodes an enum-shaped or API-shaped parent makes worth a pointer. The rest are `index` signatures with shapes and counts. |
| The contents of engine-populated data | Warehouse stock, mission objects: instance data at one instant, not API. Shape and count are kept. |
| Function environments and upvalues (`<env>`) | Syntax reserved so a future run has a name for them. Not collected: `debug` is absent where it would matter and the value of the fact is unproven. |
| `Mods/`, `Bazar/`, `DemoMods/` | Standing decisions with measurements behind them, not re-litigated here. `CoreMods/` and `Config/` are **in**, as `src data-table` shapes. |
| Prose semantics as a **measurement** | No method measures what a function does, so a *measured* behavioural slot exists only where a probe or an inspect established it: `mutability: frozen`, `hazards`, `requires_before` (§3.6). A written description is not one of these and is never graded as one — it is **authored content, graded `A`**, under §4.3: it attaches to a symbol already measured, cites its basis, and can neither create a `sym` nor set a type. `authored/` holds descriptions for exactly this reason. |
| A consumer-facing metatable chain | Resolved member sets are flat on every record; `inherits` edges are metadata. A consumer never walks `__index`. |
| Sandbox levels as a launch axis | Read at session start and stamped on the run row, never driven, and never a `scope` value: `scope` is role and phase. |
| `tree` as identity | It is how a collector reached a file. It is a `src` id and a `declares` edge now, and `unplaced` on the place axis. |

---

## 14. Text ED ships inside the product

**This is the project's rule**, stated here and enforced by ingest: a `vendor-text` origin may write
a `def`, graded `D`, and never a `sym`. It is not filed anywhere else and needs no record to become
binding — ingest refuses a `vendor-text` row outside a `def`, and §4.5's gate refuses an emission
where the grade did not survive.

`external` ranks 0 in every field group (§4.3), so a documentary
source can never create a symbol or set a type. That fence is right about the fact it protects and
wrong about which fact that is.

The founding rule exists so that no fact is *invented*. "`Scripts/Export.lua:670` says
`whTargetEOSLock = 0x0010`" is not invented. It is a measurement of a file ED ships inside the product
being measured, reproducible by anyone with the install, addressable as a `src` span. `findings.md`
§1.3 measured that the bitmask at `Scripts/Export.lua:666-675` and the closed string unions in the same
file exist *nowhere else*: no reflection can see them, no call site enumerates them. Under the current
rule they can never enter the model, and a model that answers "what values does `Manufacturer` take?"
with "unmeasurable" when ED's own shipped file states the answer has chosen a rule over a reader.

**`vendor-text` is an origin ranked above `external` and below every other origin, with the fences
that are what make it a measurement of the product rather than hearsay about it.**

1. **It may write only `def` entities** — `union`, `bitmask`, `enum` — and the slots on them.
   Never a `sym`, and never a slot on one. The runtime graph stays measurement-only, so the rule "an
   external source cannot create a symbol or set its type" is preserved exactly.
2. **Every slot it writes grades `D` in every emission**, including the LuaLS definitions a consumer
   actually reads. A gate in `verify` asserts the grade survives to the emitted text, with a positive
   control and a mutation check, because a fence nobody can see in the artefact is not a fence.
3. **It records tokens and values, never prose.** `{name: whTargetEOSLock, v: 16}`. Documented gaps are
   recorded as `reserved`, never guessed.

**Its source must be a `src` id inside the install.** That is the whole of what separates it from
`external`.

Promotion is possible and explicit: when a probe later reads a bitmask value off a live field, the `sym`
gains a measured type and the def's `probe_verified` slot fills with the run. Until then the def stands
alone, graded `D`.

**Rejected: keep `external: 0` and leave these vocabularies out, saying so.** It is defensible and it
is what an earlier draft of this design assumed. It fails the reader in the one case where ED has published the
answer inside the product, and it does so silently — the model does not say "ED documents this and we
declined to read it", it says nothing at all.

**Rejected: raise `external` to rank 1 generally.** Community wikis and prior notes are not shipped
inside the product being measured. The fence "text that ships with the install, at a `src` id" is the
whole distinction, and a general rank change erases it.

**Rejected: admit the facts as `notes` only, as `exportdoc` does today.** A note cannot be typed, cannot
be enumerated, and cannot be promoted by a later probe. The consumer asking "what values are legal" is
not served by prose.

**Revisit if a `vendor-text` def is ever contradicted by a runtime measurement**, or if a `D`-graded
value is ever found to have reached a consumer without its grade. The first says the fence is in the
wrong place; the second says the grade fence has failed and the origin must be withdrawn until the
gate works.

---

## 15. Where the schema's known gaps land

The schema-expressiveness gaps, and the field or shape each one lands in. One more, a
language map on `description`, is dropped because localisation is out of scope.

| Gap | Lands |
|---|---|
| second hop through `mission` unrecorded | §2.6 `inherits` edge with `hop`; §4.1 run `vantage` |
| join keys tree, reader wants state | §2.1 `src` family and `declares` edge; §2.4 `unplaced`. `tree` leaves identity entirely |
| first path wins, names lost to it | §2.3 pinned id plus `also_at`; §8 `also` column |
| **the key grammar, most of the `gui` graph unaddressable** | §2.2 |
| `aliases` for disagreeing joined pairs | §2.3 `also_at`; §6.8 `def alias-class` with a measured basis |
| `value` split, source literal vs runtime reading | §4.3 `declared` / `observed`; they stop competing |
| `SYMBOL_KINDS` wants `userdata`, integer keys, the enum shapes | §3.1 kinds; §2.2 integer steps; §6.2 scoped `def enum`, §6.3 `def bitmask`, §6.8 `def alias-class` |
| `superseded` names the wrong evidence method | §3.2 per-slot `by` |
| inferred-false indistinguishable from unread | §3.5 tri-state `optional`; §5's absence spellings |
| skin colour union, slot-to-type map undeclared | §3.4 value-class histograms and `def union` |
| flat enum undecodable, members never landed | §6.2 the scoped `def enum` tree — `wsType_Moving` and `wsType_Torpedo`, both value 8 |
| a measured impossibility is not a fault with a class and anchor | §5 `def ceiling` with scope, basis and revisit condition |
| behavioural facts have no field | §6.1 `mutability`; §3.6 `requires_before`; §3.6 `hazards`, with the call shape §9.4 writes and its closed `fault` vocabulary |
| receiver field sets, `fields` empty by choice | §3.6 `def shape` with per-field `seen: N of M`; "empty by choice" is `{absent: measured}`, §5 |
| no range field | §3.4 facets `min` / `max` / `unit` |
| `Sim.*`/`DCS.*` is an alias, not a rename | §6.8 `def alias-class S_EVENT`, basis measured |
| caller-context classification into a role | §2.6 `cites` edge carrying the site's enclosing declaration; the classification is a `def` with a basis |
| authored content and derived rebuild unlayered | §4.3 `authored/` outside `model/`, basis required, cannot create a `sym` |

**Every one lands in a field or a shape, not in a track that might get to it.**

