**Citation convention.** A path written `prior:<path>` is a file in the superseded repository
this project replaces, cited as evidence only. **Nothing in this repository reads one.** A bare
install path such as `Scripts/class.lua:1-44` is a file under the DCS installation, cited as the
place a finding was measured. An unprefixed repository path is a file this project expects to exist.

# Findings: what the model must actually hold

What DCS World actually looks like: the class idioms in its shipped Lua, the shapes its declaration
data takes, and what a read-only pass can and cannot reach in its live Lua states.

---

## Part 1 — Shapes in the shipped Lua

### 1.1 `class.lua`, `LuaClass` and dxgui modules are mutually incompatible, and coexist

| Idiom | Mechanism | Where |
|---|---|---|
| `class.lua` | shallow-copies every base key into the child, `__index = c`, `__call` constructs, and **`is_a` walks a separate `_base` pointer — not the metatable chain** | `Scripts/class.lua:1-44`; used by `fsm.lua`, `list.lua`, `utils.lua` |
| `LuaClass.lua` | `__index` is a **function** walking `parentClass_`; `__newindex` **errors on any mutation** (write-once objects); operator overloads `__eq`/`__le`/`__lt` by id | `Scripts/Common/LuaClass.lua:1-81` |
| dxgui modules | Lua 5.1 `module('Button')`, `Factory.setBaseClass(_M, Widget)`, `Factory.create`/`clone` | `dxgui/bind/*.lua` |

Plus DCS's own native userdata objects as a further mechanism, measured rather than inferred: the walk
records `type(v) == "userdata"` and the record carries `mechanism: native-userdata`.

**Consequence:** `kind: class` cannot be one derived category. A model that assumes one canonical
inheritance shape for all `setmetatable` usage misrepresents every idiom but the one it was drawn
from. **The mechanism must be recorded, not just the resolved member set.**

### 1.2 `wsTypes` reuses the same integer for unrelated concepts — the riskiest shape found

`Scripts/Database/wsTypes.lua:1-70`. Bare global assignments, organised into levels **by comment
banners only**. `wsType_Moving = 8` (level 2, Ground) and `wsType_Torpedo = 8` (level 2, Weapon).

`Scripts/Export.lua:653` consumes them as an ordered tuple — `type = {level1, level2, level3, level4}`
— meaningful only when resolved against the parent branch.

**A per-level enum is not enough:** two members at the same level with the same value mean different
things depending on branch. **The enum must be scoped to the hierarchy node**, protobuf-style, so
`Ground.Moving` and `Weapon.Torpedo` are different symbols that happen to share a wire value.

### 1.3 Facts that exist only in comments

`Scripts/Export.lua:666-675` documents a bitmask — `whTargetRadarView = 0x0002`,
`whTargetEOSLock = 0x0010`, with unexplained gaps at `0x0080`/`0x0100` — **as a comment block. There is
no live Lua table.** Same file documents closed string unions in prose: `Manufacturer = "RUS"/"USA"`,
`LaunchAuthorized = true/false`.

**These vocabularies exist *nowhere else*.** No reflection can see them — there is no live Lua table
to walk — and no call site enumerates them. The only thing in the product that names them is a
vendor document shipped inside it, `Scripts/Export.lua` itself.

### 1.4 and 1.5 — Localisation: out of scope

**The model holds no translations and does not model localisation.** What the install holds, and the
one obligation that survives the cut:

- **Gettext, entirely outside Lua.** `_('...')` is a lookup key, not a value. Translations live in
  compiled binary `.mo` catalogs — `l10n/<locale>/LC_MESSAGES/{dcs,input,payloads,launcher,speeches,
  about}.mo`, a catalog per locale. None of it is reachable from the Lua surface and none of
  it is wanted.
- **Hierarchy hidden inside translated strings.** `MissionEditor/modules/me_action_db.lua:35-68`
  encodes a display tree by counting leading `-` characters *inside the translated value* —
  `shells=_('-Shells')`, `conventionalShell=_('--Conventional')`. Mission-editor display data, not API.

**The one obligation that survives: a collector must recognise `_()` and never record its argument as a
value.** `_('No weapon')` is a msgid. A parser that stores `"No weapon"` as a string value has recorded
a translation key and labelled it data. That is a filter, not a feature, and it is required whether or
not translations are modelled.

**ED's descriptions are in whatever language ED wrote them, and most of them are Russian.** The
model records the description as written; a consumer that wants English translates at read time.

**Structure can hide inside string *content***, invisible to any schema that inspects only key and
value types. Worth remembering the next time a flat table looks flat.

### 1.6 Composite string keys

`Config/View/GroundCockpitQuake.lua`: keys like `"flak38 + genericAAA + 20x138B_HE + 20_00mm"` — parts
joined by `" + "`, row after row in one file. Naming a composite key as one undivided
string loses that internal structure: every part must be recorded, and so must the delimiter and the
arity that separated them.

### 1.7 Heterogeneous and self-referential declaration data

`CoreMods/aircraft/A-10/A-10C.lua:37`:
`attribute = {wsType_Air, wsType_Airplane, wsType_Battleplane, A_10C, "Battleplanes", "Refuelable"}` —
numeric enum constants, a **self-reference to the table being constructed**, and free-form capability
strings, in one array. Line 23 has `index = A_10C` inside the literal defining `A_10C`.

### 1.8 Records built by constructor call, not literal

`Scripts/Database/Troops/France.lua`: `troop("COTE D'ARGENT", _("COTE D'ARGENT"), "Cote_d'Argent.png")`
— positional-argument constructors collected into arrays, with `make_unit_list`/`add_unit_list`
varargs helpers (`db_countries.lua:19-42`), repeated across the country files.

A parser that only reads table literals sees nothing here.

### 1.9 `CoreMods/` and `Config/` — in scope, never read, structurally rich

- **Payloads** (`CoreMods/aircraft/*/UnitPayloads/*.lua`): `CLSID` is a genuine type union — GUID
  strings, bare symbolic names (`"ALQ_184"`), and **`"{CBU-87}"`, which is GUID-*shaped* but is not
  one.** A "looks like a GUID" rule misclassifies it.
- **Radios** (`CoreMods/aircraft/A-10/A-10C.lua:56-120`): bounded ranges with implicit units —
  `rangeFrequency = {{min=.., max=.., modulation=MODULATION_FM}}` — and doubly-nested integer arrays.
  `Config/DynamicRadios/Installations/A-10A.lua` uses **foreign-key-by-filename**:
  `radios = {[1]="ARC_164"}` resolves to `Config/DynamicRadios/Presets/ARC_164.lua`.
- **Input bindings** (`Config/Input/Aircrafts/base_keyboard_binding.lua`): a bespoke
  `external_profile(path)` extends mechanism that is not `require`; `combos` as arrays of chords with
  modifier arrays; and **kind-dependent field sets** — `down`+`up`, or `pressed`+`up`, or `down` alone,
  where which fields are present changes the record's semantics. Closer to a tagged union than a
  record.

### 1.10 Functions as data

`CoreMods/aircraft/A-10/Datalinks/SADL.lua:26-29`: `callBacks = {{name=.., type=.., fun=onShow_...}}` —
live function values in a dispatch registry.

---

## Part 2 — Shapes in the live states

### 2.1 `__index` is sometimes a function — collectable, but not by walking

`Airbase`, `Group`, `Controller`, `Communicator` (`mission`), `Align`, `Bkg` (`gui`) report
`metatable, __index function`. Reflect cannot walk a function `__index` and will not call it, by its
own contract. **The real DCS object API — the `Group.getByName(...)` handle surface — is therefore
invisible to a read-only walk.**

These claims must not be conflated: *a walker cannot enumerate these members* and *nothing can reach
them*. Only the first is true, and the tier ladder below exists because of it.

**Indexing is not calling.** `Group.getByName` runs ED's dispatcher and returns a function value.
`Group.getByName("x")` invokes DCS. The first is a read that happens to execute Lua; the second is a
call into the engine.

**The tiers, by what each actually executes:**

| Tier | What it does | Risk | Where it runs |
|---|---|---|---|
| **0 — cited** | ED's own shipped Lua names the member: `Group.getByName` appears at a call site, so the member exists | none; no game | offline, from a call-site collector — the cheapest tier to build |
| **1 — inspect the dispatcher** | `getmetatable(T)` and examine the `__index` **function itself** — `tostring` for identity, `debug.getinfo` where `debug` exists, to find its source; if it is Lua, read that source from the install | none; nothing is indexed or called | the census walk |
| **2 — metamethod-mediated read** | index `T[candidate]` and record `type()` of the result. **Never call the result.** | executes ED's dispatcher on an unknown key | the crash-tolerant probe path only |
| **3 — invoke** | call the value that comes back | kills DCS where `pcall` does not stop it | **barred** on the walk and across every state boundary. The one carve-out is the supervised in-state probe path: one candidate per round trip, effect-classed, deny classes refused before anything runs |

**Tier 2's rules, which are what make it safe:**

- **Candidates come from evidence, never from guessing.** A call site, a vendor document, a prior
  capture. **Never a dictionary sweep** — an unbounded probe of invented names is precisely the
  speculative behaviour the project bars, and it is also how you find the dispatcher's error path.
- **One candidate per round trip, on the progress-file path**, so an unbalanced entry names the key
  that killed the process and the run resumes past it.
- **`pcall` is expected not to help.** These faults are measured as not catchable.
- **Never on the census walk.** A crash mid-tier-2 must not cost the census.
- **The negative is a measurement.** Indexing a candidate and getting `nil` is evidence the member does
  not exist — a **measured absence**, which is valuable and currently unobtainable by any method.

**Tier 1 is the cheapest.** `LuaClass.lua:1-81` shows the idiom: `__index` is a function walking
`parentClass_`. If `debug.getinfo` resolves that function to a file and line in the install, the
dispatcher's logic — and often the member table it consults — is readable offline with no risk at
all.

**Caveat before relying on tier 1:** `debug` is present in `hook` and **absent from `mission`** —
which is where `Group`, `Airbase` and `Controller` live. Tier 1 is therefore unavailable in exactly
the state that needs it most, and tier 0 plus tier 2 carry the load there.

**For the model:** a member reached at tier 2 is not the same fact as one reached by reflection, and
the record must say which. A function `__index` is a **structural property of a table** — "this
table's members are dispatcher-mediated and cannot be enumerated by walking" — recorded as such, and
kept distinct from the absences it is easily confused with. A key that cannot be named — a userdata address that does not survive
the run — gets no record of its own: the parent's `index` signature carries it as a count
(`index: {key: userdata, n: …, values: …}`). A field no method reaches is `{absent: ceiling, ref}`,
and the ceiling it points at is scoped, usually to a state.

### 2.2 `impl` is not measurable in every state

`hook` and `config` report `function C` and `function Lua <file>:<line>`. **`mission` and `scripting`
mostly return a bare `function` with no tag** — every record measured in `mission` and most of those
in `scripting`, though `GetDevice` and `GetIndicator` did get tagged.

This is the shape behind every untagged `impl` record in the prior corpus. A model cannot
assume the field is populable per state, and the absence is not per symbol: it is one
`def ceiling` scoped to the state, written once, and every record in that scope carries
`impl: {absent: ceiling, ref: …}` pointing at it.

### 2.3 `DCS.S_EVENT_*` and `world.event.S_EVENT_*` share a value space, and nothing says so

`DCS.S_EVENT_*` duplicates the space reachable at `world.event.S_EVENT_*`, and nothing in
either namespace asserts that both denote the same value. This is the alias-versus-rename shape
`Sim.*`/`DCS.*` has: a first-path-wins join loses whichever name it did not take, so disagreeing pairs
need an `aliases` field.

### 2.4 Inheritance is already tagged by hop

`Button` carries most of its members marked `[inherited:1]` from a shared `Widget` base
(`dxgui/bind/Widget.lua`). Every widget class repeats it. **The model must decide whether
`Button.getPosition` is a fact about `Button` or about `Widget`** — reflect tags the hop for exactly
this reason.

### 2.5 Module boilerplate presents as API

`Button._M`, `Button._NAME`, `Button._PACKAGE` — Lua module-system convention fields on every widget
class. A walk-every-key collector surfaces them as members.

### 2.6 Existence is state- and phase-conditional

`AI` reflects as **absent** at the `mission` root despite being a documented mission-scripting global —
present only inside the sandboxed environment or after a script requires it. A path is not a stable
identity across states or phases.

### 2.7 Other confirmations

- Pure integer-keyed tables: `FULCRUM_INBOARD`, contiguous integer keys, values are tables.
- Empty-now vs structurally-empty: `warehouses.warehouses` has zero keys right now; one capture cannot
  tell those apart. A count of zero is a count, never an absence, and the merge never lifts it: a
  second run at another phase that disagrees becomes an `also`, and the consumer sees both counts with
  their phases.
- `config` returns a rooted user path (`track_file`) — scrubbing is needed beyond `export`, and the
  withheld value is spelled `{absent: withheld, why: machine-local}`.
- **Negative finding:** no non-identifier keys at all across a bounded walk of `hook`'s `_G`. They
  live nested in data tables, not at roots.
- Same identifier resolves to different member sets in `gui` versus `mission`. `state` is doing real
  disambiguating work, not just provenance.

---

### 2.8 The transport's names, the states they reach, and a state no name reaches

`net.dostring_in` recognises a closed set of state names, and they resolve to **fewer distinct Lua
states than there are names**. Measured on 2.9.28.26385 at `sp`; every pair settled by a marker, none
resting on a `package.loaded` count.

| Name | State |
|---|---|
| `gui` | `gui` |
| **`server`, `scripting`** | **one state** |
| `hook` | `hook` |
| `config` | `config` |
| `export` | `export` |
| `mission` | `mission` |

**`server` ≡ `scripting`**, settled twice over. *Write order:* a distinct value written into
`server`, then `scripting`, then `hook`; reading through `server` returned the value written through
`scripting`, while `hook` kept its own. *Globals address:* `return tostring(_G)` in each state in
one pass gave `server` and `scripting` the identical table — `…4FF6F170` — against `…4FF69C20` for
`gui`, `…4FF6BE40` for `hook` and `…3ED00EA0` for `config`. The alias belongs to the **transport**,
so the model holds the transport-alias table itself: `server` ≡ `scripting`, the state held once and
canonically as `scripting`, and the non-names below as measured absences against it.

**The control is the separate read, and it is the whole method.** A set-and-return inside *one*
chunk succeeds even where every chunk is handed a fresh environment table — which would make
distinct states look like one. The first attempt made exactly that mistake, and reading back in a
**separate request** is what caught it. Every pair was tested; every pair but `server`/`scripting`
came back distinct.
Each write was followed by a read from its own state — the positive control that the write landed —
then cleared, so no state was left carrying a marker.

**`missionscripting` is a seventh state that no transport name reaches.** It is where a `DO SCRIPT`
action runs, keyed beside `scripting` and never merged with it: every globals table was read
in one process in one sweep and no two are alike. A path present in both is two records. It is
reached only through `a_do_script` inside `mission`, and only while a mission is loaded.

**`editor` and `dxgui` are not transport names at all** — they are container-survey labels taken
from search paths, and they belong to the tree axis, not the state axis.

**`userhooks`, `userhook`, `zone` and `zones` are plausible, and are not names.** Each returned
nil, indistinguishable from `notastate` sent as the negative control in the same sitting, with `gui`
before and `config` after both answering with a globals address so the executor was demonstrably live
throughout. Each was a reasonable lead — `user_hooks_sandbox_level` is a real `config` global, and
`*_zone` trigger predicates exist — and both turn out to be ED's vocabulary for something that
is not an environment. The table records each as a measured absence, so the leads are settled once
rather than re-tried.

**A name the transport does not know returns nil rather than raising, and does not take DCS down.**
Unknown names sent one after another in a single sitting, no crash, the executor answering normally
either side.

**But nil is ambiguous, and that bounds the method to `sp`.** An unreachable *role* returns nil too.
On a connected client every state but `hook` answers nil, so the same reading there would mean
nothing at all. **Any probe of which names are valid is a single-player probe**; repeating it under
another role measures the role, not the name.

---

## Part 3 — Constraints these shapes place on any model of them

Rules that follow from Parts 1 and 2 rather than from taste. Each is a mistake that a schema
for a runtime-reflected API is drawn towards, and each is ruled out by something measured above.

1. **No discriminator-tag unions.** The pattern assumes a value announces its own variant. DCS values
   never do — the input-binding field sets in §1.9 differ with nothing in the data naming which shape
   is which. **The discriminator is the field set itself**, carried as `variants` on the `def shape`
   and merged only at a real type boundary. A tag-based union pushes classification onto every
   consumer instead of settling it once at merge.

2. **Never make a consumer walk `__index`.** Record the resolved member set flat on the record, each
   inherited row carrying its `from` and `hop`, and the inheritance relationship as a separate
   `inherits` edge. This is not a matter of convenience: a purpose-built checker for a
   runtime-reflected engine API still fails on recursive generics with metatables, and §1.1 shows DCS
   uses incompatible inheritance idioms, one of which exposes no metatable edge at all.

3. **Per-field counts, not a bare date — `seen: N` on every field of a `def shape`, against the
   shape's own `of: M`.** The failure mode this prevents is **silent under-generalisation**: a shape
   observed with a handful of its real fields ships as though that handful were the whole schema, and
   nothing in the record says the sample was thin. The counts on the record make the thinness visible;
   a date does not.
