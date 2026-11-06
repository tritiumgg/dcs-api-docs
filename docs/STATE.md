# Working state

**Last updated:** 2026-11-06

The handoff between sessions. Read it first; update it before a session ends,
not only when a task finishes. Stamp the date above each time; it carries a
date and nothing else, because what changed is what the sections below are for.

**This file is loaded cold every session, so its size is a tax on all of them.**
Each section has a line budget and `tools/statecheck.sh` enforces it. Over
budget, nothing is deleted — it moves. A completion older than the last few
goes to git log. A choice with reasoning behind it becomes a decision record.
A durable fact about the project belongs in `CLAUDE.md`. A resolved
carry-forward is just deleted. One or two lines per entry, never paragraphs.

---

## In progress

Nothing. The lean plan is written and waits on the maintainer's review of its pull request.

*One task at most. Say what is done, what is not, and where to resume. Say what
is committed and what is only in the working tree. Say what is knowingly
broken. Under it, say who verifies: an agent, a maintainer reading CI, or a
person at a live install. Empty this when the task closes.*

## Just finished

- **The lean plan** (`docs/PLAN.md`): five stages, two DCS sittings, one crate, the shared modding API in three offline rows; the discovery evidence and the keep/shrink/drop table are in it. `CLAUDE.md`, `docs/SCENARIOS.md`, `docs/audit.md` and the spec heads edited to match.
- **The documents corrected in place** and the scaffold: hooks, gates, `mise run check`, CI.

*The last three at most, one line each. Git log holds the rest.*

## Next

`/task 0.1`, the crate, once the plan lands. It needs no DCS.
Who verifies: CI reads `mise run check`.

## After that

- 1.1 to 1.3, the offline collection; 2.1, the walker and its scrub control, under the harness.
- Sitting A with the maintainer at DCS (2.2, 2.3), then sitting B (3.1, 3.2).

## Carries forward

Things that must not be lost between sessions. Delete an entry when it is
resolved, and say where. Mark an entry only the maintainer can settle. Ten
entries at most: an eleventh means something here is finished, or belongs in
`docs/decisions/` or `CLAUDE.md` instead.

- **Maintainer**: the open questions in `docs/PLAN.md` section 8: filter module `db` rows or not; which mission for sitting B; whether the predecessor's killer list seeds the deny list.
- **Maintainer**: `docs/audit.md`'s open row, scenario 1's state, is settled by sitting A.
- The first build commit creates `docs/specs/.frozen`; nothing else does.
- The mutation tooling (`tools/sweep*.sh`, `docs/mutations.md`, the close-task skill's red step, the verifier agent) still describes the ritual the plan shrank to one control; trim it in a `build/` change.
