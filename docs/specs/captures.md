# Captures: track the observation tier, filter in the walker

**Citation convention.** A path written `prior:<path>` is a file in the superseded repository
this project replaces, cited as evidence and readable there on demand. **Nothing in the new
repository reads one at build time.** An unprefixed path is a file in the new repository — one this
document expects to exist, or tells you to create.

---

## 1. The tier that is tracked

**Observations are tracked. Raw replies stay local, in a configured directory outside the
repository — `../dcs-api-captures-local` by default.**

A generation is one collection of every artefact a run leaves behind. The raw replies dominate it;
the derived observations are a small fraction of the same generation, gzipped.

| Tier | Lets you | Costs |
|---|---|---|
| **Observations** (JSONL) | re-merge, re-emit, diff, verify determinism | cannot re-derive under a *changed collector version* |
| Raw `.res` | everything above, plus re-derive with a new collector | an order of magnitude larger, and holds unstructured PII |

Git keeps history, so overwriting the same paths reclaims nothing: every generation is a permanent
cost, not a working-set size. That is what makes the ratio decide the rule — at the collection rate
this project expects, the observation tier stays a rounding error in history and the raw tier does
not.

The one thing the rule gives up is re-deriving observations under a collector-version bump.
**Re-collect instead** — the one-command/one-session design makes that cheap.

**Tracking observations is what makes merge determinism achievable rather than asserted.** Merge is
a pure function of `(runs, observations, authored)` — `model.md` §4.3 — so every fact merge needs,
including the probe and `mp-client` evidence that would otherwise exist nowhere else, is in the
observation log, and the model never reads its own prior output back in. The prior pipeline kept no
such log, which is why its merge had to read the committed model first
(`prior:pipeline/src/cli.ts:240`); a merge that reads its own output is not a function of its
inputs.

---

## 2. The filter

### Where

**In layers, every one of them binding.** First **in the Lua walker, before a value enters the
reply**. Then a **backstop at ingest**, where a reply becomes observations. Then a **backstop at
merge**, where observations become records. The project already uses this belt-and-braces shape — an
in-state filter with a merge-time pass that calls itself "the backstop"
(`prior:pipeline/src/merge/instrument.ts`).

**A merge-time filter alone is not enough.** The prior implementation filtered only at merge
(`prior:pipeline/src/merge/machinelocal.ts`), which is why its committed model was clean and its raw
captures were not. Filtering where the value is produced is what makes the raw captures safe too,
not just the committed artefact, so **the filter goes into the walker from the first line of it**.

The cost is that redaction is irreversible and must be right the first time, which is why the
control below is not optional.

### What to detect

Derive the sensitive tokens **at run start, in-state**, rather than hardcoding them:

- `lfs.writedir()` — contains the username; extract it
- `lfs.tempdir()`, `lfs.currentdir()`, the install root
- the machine name, where reachable

Then scan every string **key and value** for:

| Form | Why |
|---|---|
| the token, case-insensitive | the obvious case |
| **the token reversed** | ED stores at least one path spelled backwards — `me_openfile.rev_str`. A filter that tests one direction fails on it |
| **the 8.3 short form** — the first six characters, uppercased, plus `~1` | a *derived* spelling a token match misses. The username turned up in **every spelling in this table**, spread across the install |
| path-shaped patterns | unanchored `ROOTS` regexes — a drive-letter arm `[A-Za-z]:[\\/]`, a UNC arm `\\\\`, and a POSIX arm covering `/Users/` and `\Users\`. Unanchored because a path is as often embedded in a longer string as it is the whole of one. They catch paths that contain no known token |

Keys matter as much as values: a table keyed by username leaks through the key.

### What to write instead

**Never `nil`.** A typed placeholder that preserves the shape, from the closed vocabulary
`{redacted: path|user|host}`:

```
{redacted: "path"}     the value was a rooted filesystem path
{redacted: "user"}     the value contained the operator's identity
{redacted: "host"}     the value contained the machine name
```

This keeps absence unambiguous — the project's central discipline. A silently dropped value is
indistinguishable from a value nobody measured.

### The control

**Plant known PII in a fixture and assert the filter catches it — forwards, reversed, and 8.3 — then
verify by mutation.** Break the filter deliberately; the test must fail. A scrubber that silently
stops working is worse than none, because the output looks clean.

---

## 3. Mission names are controlled, not filtered

No filter can tell a personal mission name from a vendor one, and captures have carried the
operator's own missions alongside ED's `tempMission.miz`. **So do not filter the name — control the
source: collect only against a single project-owned fixture mission, tracked in the repository, and
never against an operator's own missions.** Then the only mission name a capture can contain is one
the repository owns.

**The refusal rests on a pair, measured on both sides of the boundary.** The executor reports the
loaded mission's **name** from inside DCS and offers no hash; the driver computes the **hash of the
fixture `.miz` outside DCS**, from the committed file. A session is collected against only when the
name matched inside agrees with the fixture and the hash computed outside agrees with the one
recorded for it.
Name alone would accept an edited fixture; a hash cannot be read from inside a running game.

No `.miz` was tracked in the prior repository, so this fixture is a thing to make, not a thing to
inherit: it is created, committed and hashed, and `.gitattributes` marks `*.miz binary`.

---

## 4. What is never committed regardless

**Crash dumps, `dcs.log`, and any rotated log archives DCS or the executor leaves behind.** They are
unstructured, they are full of absolute paths, and no scrubber can be trusted against them. They stay
local, and the observation tier — which is structured and filterable — is what gets tracked.
