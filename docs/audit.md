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
| Airbase identity | `Mods/terrains/*/` holds the airbase tables and `Mods/` is excluded from the census. Either exactly that path is admitted as a named exception, or airbase identity is recorded as a measured absence citing the exclusion, and the reference-data emitter ships no `airbases` table until then. | `docs/specs/model.md` §13 and `docs/SCENARIOS.md` §6, in the same edit |
| The benchmark threshold | N is unset until the first card exists; the first card prints ungated and N is then written to `bench/threshold` and the release table in `docs/PLAN.md`. | `docs/PLAN.md` §6, by the maintainer, after B.10's first run |
| What a release boundary runs | The default is the whole live pool plus the controls, at the repeats rule. The maintainer may name a subset, and the release document and the card must then say which tasks it holds. | `docs/specs/benchmark.md` §11 already permits it; the choice is recorded in the release document |
| Scenario 1's state | The findings place the mission-scripting surface in `mission`; the transport's `server` name resolves to `scripting`. The census of both states settles it and the root gate prints the answer. | The Stage 4 sessions and the root gate, not a person |

## Resolved

Nothing yet. Rows arrive with the freeze.
