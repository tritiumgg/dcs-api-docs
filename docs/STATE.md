# Working state

**Last updated:** 2026-09-22

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

Nothing. The documents are reconciled and the plan has not started.

*One task at most. Say what is done, what is not, and where to resume. Say what
is committed and what is only in the working tree. Say what is knowingly
broken. Under it, say who verifies: an agent, a maintainer reading CI, or a
person at a live install. Empty this when the task closes.*

## Just finished

- **The documents corrected in place**: the specifications, the plan, the scenarios and the authored-layer design agree with each other and with the executor as shipped; the toolchain is decided (Rust, full_moon, mise, Lua 5.1.5).
- **The scaffold**: hooks, gates, `mise run check`, CI, `CLAUDE.md`, this file.

*The last three at most, one line each. Git log holds the rest.*

## Next

**Squash to the initial commit** once the maintainer is satisfied; then `/task`, which picks
0.1, the verify runner, and asks because B.0′ is ready too.
Who verifies: the maintainer reads the tree; 0.1's own gate after that.

## After that

- The fixture mission, authored by the maintainer in the editor (plan 3.2); the spikes the
  executor can serve before Stage 3 (SP-3, SP-6, SP-7) with the maintainer at DCS.
- Stage 0 in order: 0.1 verify, 0.2 the Lua pin, 0.3 the hook, 0.7 the Rust workspace.

## Carries forward

Things that must not be lost between sessions. Delete an entry when it is
resolved, and say where. Mark an entry only the maintainer can settle. Ten
entries at most: an eleventh means something here is finished, or belongs in
`docs/decisions/` or `CLAUDE.md` instead.

- **Maintainer**: the open rows in `docs/audit.md`: airbase identity under `Mods/terrains/`, the threshold N, what a release boundary runs.
- The first build commit creates `docs/specs/.frozen`; nothing else does.
