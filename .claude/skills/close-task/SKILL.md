---
name: close-task
description: Close a plan task on evidence. Runs its gate, applies its mutation and confirms red, records the control, updates the handoff, runs the full check, and opens the pull request.
argument-hint: "<task id>"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion
---

Close plan task `$ARGUMENTS`. A task is done when its one command prints the stated number, and
not before; nothing here is closed on prose.

## 1. The gate, green

`sh tools/progress.sh show $ARGUMENTS` gives the row and its done-condition. Run the row's
command exactly as the plan states it. Paste what it printed. If it does not print the stated
shape, the task is not done: say what differs and stop here.

## 2. The mutation, red

Where the row names a mutation: apply it as the row says, run the command again, and confirm it
went red in the way the row predicts. Restore the code and run the command a third time to
confirm green again. Paste all three outputs.

Then add the control to `docs/mutations.md` in the format that file states: a `###` heading with
the control id (`group/what-breaks`), `task:`, `command:`, `reddens:` as the substring actually
observed, a `note:` where the observed red differs from the predicted one, and the
`sweep-edit` block whose anchor lines match the source exactly. Run
`sh tools/sweep.sh --only <group>/` and confirm it reports the control performed and red.

A control that cannot be shown red is not evidence. If the mutation does not redden, the task
is not done: say so and stop.

## 3. Everything else green

Run `mise run check`. Fix what it reports. Run `sh tools/nospecrefs.sh` on its own if the check
did not reach it: a task id or a specification citation in the code fails CI.

## 4. The handoff

In `docs/STATE.md`: move the task to "Just finished" as one line; empty "In progress"; put the
next ready row from `sh tools/progress.sh next` under "Next" (or ask the maintainer when more
than one is ready); delete any carry-forward this task resolved and say where; stamp the date.
`sh tools/statecheck.sh` must pass.

If the task changed anything a consumer installs or runs, update `README.md` in the same
change; take out any "not built" line it settles.

## 5. Commit and the pull request

Commit in slices if the work is more than one logical change, each
commit `type(scope): summary` under 72 characters. Push the topic branch. Open the pull request
with `gh pr create --body-file`, the body following `.github/PULL_REQUEST_TEMPLATE.md`: Summary
and README are always present; Testing lists the commands from steps 1 and 2 and what they
printed; Not covered names any part of the done-condition these steps did not reach.

Report the pull request as waiting. It lands when the maintainer says so: then rebase onto
`main`, fast-forward `main`, push, delete the branch. A red CI run is fixed on the branch first.
