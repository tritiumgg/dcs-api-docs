# Audit: what the specifications and the plan disagree about

The documents under `docs/specs/` were written and revised separately, and `docs/PLAN.md` was
written against an earlier revision of them. Where they contradict each other, or contradict
the plan, `docs/SCENARIOS.md` or `docs/AUTHORED.md`, the build has to pick one, and picking
silently is how a contradiction becomes a bug nobody can trace back to a document.

Before the first build commit, a disagreement is fixed in the documents themselves and leaves
no row here. From the freeze on, a disagreement discovered mid-task is recorded here in the
same commit that resolves it, with the decision record or plan edit that settles it, and a row
without a resolution is an open question that also sits in `docs/STATE.md`'s carries.

## Open

Each of these is the maintainer's call. The documents do not assume either answer.

| Subject | The question | Where it is settled |
|---|---|---|
| Scenario 1's state | The findings place the mission-scripting surface in `mission`; the transport's `server` name resolves to `scripting`. The census of both states settles it and the root gate prints the answer. | Sitting A's walk of both states (`docs/PLAN.md` row 2.2), not a person |

## Resolved

| Subject | The answer | Where |
|---|---|---|
| Airbase identity | Per-map values are out of scope (2026-11-06). `world.getAirbases` and the `Airbase` methods are documented as APIs; no `airbases` table ships | `docs/PLAN.md`, scope |
| The benchmark threshold and what a release boundary runs | The benchmark is not built | `docs/PLAN.md` section 7 |
