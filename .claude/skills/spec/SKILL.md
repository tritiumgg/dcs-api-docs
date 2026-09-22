---
name: spec
description: Read a specification precisely instead of whole. Finds the headings and lines matching a query in one of the frozen documents, then reads the one section that answers it.
argument-hint: "<MODEL|FINDINGS|CAPTURES|BENCHMARK> <query>"
allowed-tools: Bash
---

Find what `docs/specs/` says about the query, without loading a document whole.

The arguments are a document code and a query: `$ARGUMENTS`. The codes are the filenames
upper-cased; `sh tools/spec.sh list` prints them.

1. `sh tools/spec.sh find <CODE> <query>`: every heading and line that matches.
2. From the hits, pick the section number that answers the question and run
   `sh tools/spec.sh read <CODE> <section>`. Read a second section only if the first cites it.
3. Quote the document, not a memory of it. A quotation keeps the specification's own words,
   including names the build has since changed; say when a name in the quotation is one the
   build spells differently.

Never `Read` a file under `docs/specs/` without an `offset` and a `limit`; a hook refuses it,
and `sh tools/spec.sh sections <CODE>` is the map when a query is too vague to `find`.
