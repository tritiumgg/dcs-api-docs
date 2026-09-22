---
name: handoff
description: End a session mid-task without losing where things stand. Fills docs/STATE.md's In progress block from the working tree and the branch, stamps it, and commits the handoff.
allowed-tools: Bash, Read, Edit, Grep
---

The session is stopping before its task closes. The next session must not have to re-derive
where things stood.

1. Establish the facts from the tree, not from memory: `git status --short`, `git log --oneline
   main..HEAD`, `git branch --show-current`, and the task's gate command if it runs at all yet.
2. Fill `docs/STATE.md`'s "In progress" with, in this order: the task id; what is done; what is
   not; where to resume (a file and a function, or the next step of the row); what is committed
   versus only in the working tree; what is knowingly broken; who verifies. Two lines per item at
   most. If a lead came up that must not be lost and is not part of this task, it goes under
   "Carries forward", at most ten there, or it becomes a plan row.
3. Stamp "Last updated" with today's date. Run `sh tools/statecheck.sh`; if a section is over
   budget, move something out rather than deleting it.
4. Commit the handoff on the topic branch, `docs(state): handoff <task id>`, and push it, so
   the next session can start from any checkout.
5. Say in one line where things stand and what the next session does first.
