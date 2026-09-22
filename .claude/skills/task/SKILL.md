---
name: task
description: Start a plan task. With an id, that row; with none, the next row the gates say is ready, confirmed with the maintainer when the choice is not obvious. Sets up the branch and the handoff, then the session works the task.
argument-hint: "[task id]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion
---

Start plan task `$ARGUMENTS`, or the next ready one when no id is given.

## 1. Which task

Run `sh tools/progress.sh next`. It prints the rows whose needs are all green and which are not
green themselves, `dev` rows first, in plan order.

Read `docs/STATE.md`'s "In progress" section.

Decide:

- **An id was given** and "In progress" names a different task: ask the maintainer which one
  before doing anything else. Never abandon an in-progress task silently.
- **An id was given** and it is not in the ready list: say why (a need is not green, or the row
  is already green) and ask whether to proceed anyway. Proceeding is the maintainer's call.
- **No id** and "In progress" names a task: resume that task. Say so and go to step 3.
- **No id** and exactly one ready row that runs on `dev`: take it. Say which and why in one line.
- **No id** and the choice is ambiguous: ask, with `AskUserQuestion`, listing the ready rows
  with their stage and where they run. It is ambiguous when more than one `dev` row is ready,
  when the only ready row runs on `DCS+human` (the maintainer has to be at the install), or
  when `docs/PLAN.md` §10's sequencing would prefer a row the sort did not put first (Track C
  as soon as it is ready; spikes early; the session chain before the calendar-filling stages).
  Put the row you would pick first and say why.

## 2. Read the row

`sh tools/progress.sh show <id>` gives the row. Read the plan section around it for context, and
the specification sections the row cites through `sh tools/spec.sh read <CODE> <section>`, never
whole. If the row's done-condition names a gate command, that command is the deliverable.

Decide **who verifies**: an agent can observe the printed result itself; a maintainer reads CI;
or only a person at a live install can see it. Write it down in step 3. A `DCS+human` row means
the third, and the session plans the human steps rather than pretending to run them.

## 3. Branch and handoff

- If "In progress" already names a different task that is being resumed elsewhere, or the
  maintainer says another session is running, this task takes a **worktree** of its own rather
  than a branch switch in this checkout: use `EnterWorktree` (or `git worktree add`), then run
  `mise run lua-build` there once. Otherwise `git switch -c task/<id>-<short-slug>` from `main`,
  unless already on that branch.
- Fill `docs/STATE.md`'s "In progress" with: the id and its one-line description; what is done
  and not done (nothing yet, on a fresh start); where to resume; what is committed versus only in
  the working tree; the who-verifies line. Stamp "Last updated" with today's date. Keep to the
  section's budget; `sh tools/statecheck.sh` says if it is over.
- If the row builds a control, note that its `docs/mutations.md` entry is owed in the same pull
  request, so `close-task` does not have to discover it.

## 4. Work

Then do the task, in this session. The done-condition is what the row's command prints, and a
check that has not been seen red is not done. When the work is complete, run `/close-task <id>`.
When the session must stop before that, run `/handoff`.
