# The mutation inventory

Every control in this build is proved the same way: the code it watches is broken on purpose,
the check goes red, the code is put back. That proof happens once, by hand, in the session that
builds the control, and nothing else would re-run it. A check that quietly stopped reddening as
the code moved underneath it would look exactly like a check that still works.

This file is the record those proofs are re-run from. `tools/sweep.sh` reads it, applies each
mutation to a file it has copied first, runs the one command that must go red, restores from
the copy and reports. A control that no longer reddens is a finding; a control whose mutation
no longer applies is a finding too, never a silent skip.

**A task that builds a control adds its entry here, in the same pull request.** That is the
only way the file stays honest. `close-task` does it as part of closing.

**`reddens:` is what was observed, not what was predicted.** Where the red a mutation produced
is not the red its plan cell named, the entry says so in a `note:`; that difference is the
interesting part, because it says what the check actually watches.

**A mutation's anchor is a line of source nothing marks.** The inventory matches on exact
whole-line text, so reformatting, renaming or inlining a line some control anchors on does not
fail the build; it turns that control UNPERFORMED, which is the failure this whole apparatus is
against. Before tidying a line you did not write, grep it here; if it is an anchor, leave it or
move the anchor in the same commit and re-run `sh tools/sweep.sh --only <group>/`.

**The sweep is not in `mise run check`.** It is slow and it edits the working tree. It runs
weekly against `main` and green before a stage closes; `mise run sweep` is the command.

**Why this file is under `docs/`.** It has to name the task a control came from, and
`tools/nospecrefs.sh` refuses a plan task id anywhere outside `docs/`, `CLAUDE.md` and
`README.md`. `tools/sweep.sh` carries no inventory data at all, and control ids are lowercase
slugs because the runner prints them.

---

## The format

One `###` heading per control. The heading text is the control's id: a lowercase slug,
`group/what-breaks`, the group naming the area so that `--only group/` selects the lot.

Bullets, one per line, each `- name: value`:

- `task:` the plan row the control came from. One id.
- `command:` the one command that must go red, in backticks. Run from the repository root,
  through `mise exec` where it needs the toolchain.
- `reddens:` one line, and one line only: a substring of the failing check's own output, as it
  was observed. The runner looks for it in what the command printed, so it is the check's name
  or a fragment of its message, never a description of it.
- `note:` optional prose. Where the red observed is not the red the plan cell predicted, this is
  where that is said.
- `folds:` optional, and its value begins with a number. Present where one entry covers several
  mutations the plan names separately because they cannot be performed apart; the runner counts
  the entry as that many controls.

Then one or more fenced blocks whose info string is `sweep-edit <path>`:

    ```sweep-edit instrument/DcsApiCensus.lua
    -   local chunk, why = loadstring(req.body, chunkname)
    +   local chunk, why = loadstring("\n" .. req.body, chunkname)
    ```

Inside a block, a *hunk* is a run of `- ` lines, the anchor, taken verbatim after the
two-character prefix, followed by zero or more `+ ` lines, the replacement. A blank line
separates hunks. A hunk with no `+` lines deletes.

**Matching is exact whole-line equality and never a line number.** The anchor run must occur
exactly once in the file: zero occurrences means the code moved, two means the anchor is
ambiguous, and either way the control is reported UNPERFORMED rather than guessed at.

Limits that follow, and a control needing more than the format gives is out of scope rather than
silently wrong:

- an anchor cannot contain a blank line, because a blank line separates hunks;
- two blocks may name the same file, where a control moves a line from one place to another;
  their hunks are applied together in one rewrite;
- a replacement line cannot begin with `- `, because it would be read as the start of the next
  anchor;
- comparison is on LF lines. A CR anywhere in the target file means no anchor will ever match,
  so the runner detects one and says so in the UNPERFORMED reason. `.gitattributes` keeps every
  file LF.

## What out of scope looks like

A group that is not swept is an entry in this same file carrying `out-of-scope:`, the reason,
and `controls:`, the number it stands for. The runner sums them into its coverage line, so what
the sweep does not cover is printed by the sweep itself rather than left to be assumed.

---

## Stage 0 — Foundation

No control yet. The first one arrives with the verify runner.
