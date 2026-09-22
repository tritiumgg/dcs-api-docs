## Summary

<!--
One to three sentences: what this changes and why. Name the plan row it closes,
or say it belongs to no row and give the type it commits under. Do not repeat
the title.
-->

## Done when

<!--
The row's done-condition, and what the command printed. Paste the output, not a
description of it. If the output differs from the row's shape, say where and
why. Delete the section for a change that closes no row.
-->

```
$ mise run <task>
```

## Seen red

<!--
The row's mutation, the red it produced, and the green after the restore. Paste
all three outputs. Name the entry this adds to docs/mutations.md. A check that
was not seen red is not evidence, and the row is not closed. Delete the section
for a row with no mutation.
-->

```
$ <mutation applied>
$ mise run <task>
$ <restored>
$ mise run <task>
```

## Who verified

<!--
One line. An agent observed the printed result; the maintainer reads CI; or a
person at a live install saw it. For a live session: the DCS build, the launch
configuration, the vantage, and the run ids the ledger gained.
-->

## README

<!--
Always present. What this change alters in what a consumer installs or runs,
and the README paragraph that now says so. Name any "not built" line the change
takes out. When nothing a consumer sees changed, say so in one sentence.
-->

## Not covered

<!--
Every part of the row's done-condition these steps did not reach, and where the
gap is recorded: docs/STATE.md, docs/audit.md, or a later row. Delete the
section when the steps reach all of it.
-->

## Departures

<!--
After the freeze only. Each place this change goes where docs/specs/ did not,
with the decision record that holds it. Delete the section when there is none.
-->

## Notes for reviewers

<!--
Optional. Where to start, a choice worth challenging, follow-up work left out
on purpose, anything temporary.
-->
