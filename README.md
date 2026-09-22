# dcs-api-docs

A measured model of the parts of the DCS World Lua API a developer actually uses, packaged so
that an AI agent helping with a DCS scripting task can find out whether a symbol exists, in
which Lua state, and how it behaves, without guessing.

> **Not built.** This repository holds the specifications, the plan and the tooling scaffold.
> No release exists yet. `docs/STATE.md` says where the work stands.

## What you get

*Planned.* One release artefact, installed as a Claude skill:

- `index/` — one TSV row per symbol: state, kind, implementation, arity, hazards, and the
  definition file that holds the rest. A question is one grep here.
- `defs/` — LuaLS definition files, one bounded read per symbol, with the declaration span, the
  build it was measured on, a sample of call sites, and a grade on every fact saying whether it
  was measured, read from source, taken from vendor text, or authored.
- `data/` — the reference databases (units, weapons, countries, airbases, liveries) as one TSV
  per table, for lookups.
- `guides/` — authored pages per scenario: mission scripting, campaigns, client UI, editor
  automation, offline mission authoring, export, cockpit actuation, server administration,
  cross-environment plumbing.

Every fact carries which run measured it and at which vantage. Absence is written explicitly.
A conflict between sources is reported, never resolved silently. No documentation creates a
symbol.

## Install

*Not built.*

## How it is made

Probes run inside a live DCS World through [`dcs-eval`](../dcs-eval), walk each Lua state, and
write observations. Offline collectors read the install's own Lua source. A pure merge turns
observations into records; emitters turn records into the artefacts above. `docs/PLAN.md` is
the build order; `docs/specs/` is what it builds.
