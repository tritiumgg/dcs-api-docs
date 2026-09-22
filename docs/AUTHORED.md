# The authored layer: documentation on top of the model

The model says what exists and what was measured. It cannot say what a function is for, when to
use it over its neighbour, what happens on a client, or why a call that looks right silently does
nothing. Much of the surface is C and has no source to read. That knowledge is authored, and it
lives on top of the model, in its own tree, keyed by the model's ids, so that either can be
released without the other.

Rules from `model.md` hold here without exception: an authored entry needs a basis, and it
can neither create a symbol nor set a type. A third rule is this project's: **measurement takes
precedence over memory.** A claim that could be measured is a probe candidate, not a paragraph.

---

## 1. Entries and guides

**Entries** are per symbol. They attach to one id from the index and render into that symbol's
definition, so the one-grep-one-read query returns them without a third step.

**Guides** are per scenario or per topic. They span symbols: persistence across missions, event
ordering, what the sanitiser removed, hook-side versus mission-side. They render as their own
pages and every symbol they name is a link the drift gate checks.

Both live under `authored/`, separately from `model/`, `observations/` and `names/`:

```
authored/
  entries/<state>/<root>.yaml     one file per root, one entry per id
  guides/<scenario-or-topic>.md   prose, with symbol ids in a fenced link form
  examples/<id-slug>.lua          runnable, harness-checked where possible
  defs/<kind>/<slug>.yaml         authored def records: ceilings, exclusions, overrides
  reference-surface.yaml          stock Lua 5.1, lfs, socket and ED's additions, declared once
```

The last two are what the model itself needs from an author, as `model.md` §6.5 and §6.8 say:
a `def ceiling` with its totality basis, an exclusion citing a rule, an override with its run
basis, and the reference surface the census diffs against so stock Lua is not re-recorded in
every state. They obey the same rules as entries: a basis, no symbol creation, no type.

## 2. An entry

```yaml
- id: scripting:trigger.action.outText
  summary: Show a message to every player, for a duration in seconds.
  behavior: |
    Queues the text on the server's message panel. Shown to all coalitions; use
    `outTextForCoalition` or `outTextForGroup` to narrow. A duration of 0 shows nothing.
    Called before the mission has started rendering, the message is dropped, not queued.
  params:
    text: Lua string; a table is not coerced and raises.
    displayTime: seconds; fractional values are truncated.
    clearview: when true, clears earlier messages first.
  returns: nothing. The function has no return value in any measured build.
  hazards:
    - Calling at frame rate floods the panel; there is no coalescing.
  see_also: [scripting:trigger.action.outTextForCoalition, scripting:trigger.action.outTextForGroup]
  examples: [trigger-action-outtext-basic]
  basis:
    - run: r-2026-09-30-sp-scripting-03      # "returns nothing", "table raises", "0 shows nothing"
    - external: https://...                  # ED documentation for the parameter names
    - claim: 2026-09-22 build 2.9.29        # "dropped before rendering"; unverified
  verified: partial
```

Every sentence in `behavior`, `params` and `returns` traces to one basis line. The basis
kinds:

| basis | what it is | grade |
|---|---|---|
| `run` | a ledgered run whose observations show the fact | `A` backed by `M` |
| `external` | ED documentation or a community source, by URL, with a retrieval date | `A` backed by `external`, which ranks at 0 in the model; `D` is reserved for vendor text at a `src` id inside the install |
| `claim` | the author's knowledge, dated and stamped with the build | `A`, unverified |

`verified` is computed, never typed: `yes` when every fact has a `run` basis, `partial` when some
do, `no` when none do. It renders inline in the definition, next to the existing `[A]` marker, so
a consumer sees `[A, unverified]` and the benchmark's `invented` verdict can catch the harm if
the claim is wrong. The marker sits beside the grade, not inside it, and the grade-survival gate
asserts it survives to the emitted text the same way `[D]` and `[A]` do. The model's own
`probe-verified` slot on a `def bitmask` or `def union` is a different thing: a measurement.

## 3. Claims are hypotheses

An author, Claude included, knows a great deal about DCS that is neither measured nor sourced.
That knowledge enters as `claim` and nothing else. Then:

1. `authored claims` lists every claim, most-cited symbol first.
2. Each claim that a probe could settle is matched to a probe candidate under the same rules
   as Track C: cited, effect-classed, deny classes refused. The claim is never the citation.
   A candidate cites a call site, vendor text, a community call site, or a prior run, and the
   claim ranks it up the queue; a claim with no citable call site anywhere stays a claim.
3. When the run lands, the entry's basis line changes from `claim` to `run`, in the same commit
   as the observation, and `verified` moves.
4. A claim the run contradicts is deleted, and the contradicting observation is the fact. The
   entry does not keep a wrong sentence with a note.
5. A claim no probe can settle (intent, idiom, history) stays a claim, and stays marked.

The release document prints entries, claims outstanding, and claims contradicted since the
last release. The last is the honesty figure.

## 4. Examples are probes

An example under `authored/examples/` is a Lua chunk with a header naming its state and its
expected printed output. The harness runs the ones that need no game under the stub environment;
the session driver runs the rest in-state as read-only probes, and the run ledger records each.
An example that has never run is marked as such in the definition it renders into. An example
that fails to run is a red gate, not a stale comment.

This is the one place the authored layer produces measurements rather than consuming them, and
it is the cheapest evidence the project has: a worked example that ran is worth more to a
consumer than a paragraph, and it verifies the paragraph beside it.

## 5. Guides

A guide is Markdown under `authored/guides/`, one per scenario from `docs/SCENARIOS.md` plus
topics that cut across them. Symbol references use one spelling, `` `scripting:trigger.action.outText` ``
in a link, so a gate can check every one resolves in the current index and report the ones that
retired or renamed. A guide with an unresolved reference fails `verify`; the fix is the rename
ledger or an edit, never a silent drop.

Guides carry a basis block too, at the section level, with the same kinds.

## 6. Drift

The layer is keyed by pinned ids from the name ledger, which is why the model can move under it.
`authored review` already lists unresolved bases and drifted entries. It gains:

- an entry whose id was retired or renamed, with the ledger row that did it;
- an entry whose `run` basis was superseded by a later run on the same scope;
- an entry whose symbol's measured facts changed since the entry's build stamp, so the prose
  may be stale even though nothing it cites was retracted;
- an example that has not run on the current build.

None of these deletes anything. They print, and a person or a session decides.

## 7. What renders where

| From | To | How |
|---|---|---|
| `summary`, `behavior`, `params`, `returns` | the LuaLS definition | `---` lines above the declaration, `[A]` or `[A, unverified]` inline, `@param` and `@return` descriptions |
| `hazards` | the definition and the index `hazard` column | joined with measured hazards; authored ones marked |
| `see_also` | the definition | `@see` lines |
| `examples` | the definition | the chunk inline when under twenty lines, a link otherwise |
| guides | `guides/<name>.md` in the release | rendered with resolved links, one page each |
| reference-data notes | the data TSV's companion `.md` | per-table prose; rows stay prose-free |

The query stays one grep and one bounded read: everything per symbol is in the definition file.

## 8. Claude as an author

The `author <id>` skill: reads the index row, the definition, the cites sample, the community
usage, any prior entry, and the runs that touched the symbol. Drafts the entry with every
sentence tagged to a basis. Anything from memory is a `claim`. Emits the probe candidates the
claims imply. Never writes a type, never invents a symbol, and refuses to describe a symbol the
index does not hold.

A fan-out workflow authors one root per agent from the worklist (most-called,
most-hazardous, undescribed first), with the claim ratio printed per root so the maintainer can
see which drafts are knowledge and which are memory before merging any.

## 9. What this adds to the plan

- **8.5** the entry format, its schema, and the `verified` computation. Mutation: a fact with no
  basis line is refused.
- **8.6** the examples runner, stub and in-state. An in-state example is a probe and carries an
  effect class under the same deny rules. Mutation: an example whose output changes goes red.
- **8.7** guides and the reference gate. Mutation: retire a cited id, the gate names the guide.
- **8.8** `authored claims` and the claim-to-probe matching. Mutation: a claim whose probe
  contradicts it survives the run, red.
- **7.2 grows**: the defs emitter renders the entry fields and the verification marker, and 7.3
  asserts the marker survives.
- **The release document** prints entries, claims outstanding, claims contradicted.

Stage 8 stays "machinery only" and the worklist stays the maintainer's; this file adds the
shape of what the machinery holds and the rule that keeps an author's memory out of the model.
