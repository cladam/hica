# Bug: Perceus double-free / mimalloc corruption when a match scrutinee is re-referenced inside its own constructor-pattern arm

- **Reported by:** TOML library team
- **Date:** 2026-07-10
- **hica version:** 0.41.3
- **Koka version:** 3.2.3 (ghc release, Mar 18 2026)
- **Platform:** macOS / Darwin arm64 (Apple Silicon)
- **Severity:** High — silent memory corruption; wrong results and heap corruption at runtime, not a compile error
- **Area:** codegen (`src/emit/codegen.kk`) / Perceus reference-count interaction

## Summary

When a value is matched with a **constructor pattern that contains a nested wildcard**
(e.g. `Some(Wrap(_))`), and that same scrutinee variable is **used again inside the arm**,
and the arm is **followed by another sequential `match`** on a second value, the generated
Koka is miscompiled by Perceus. The inner payload is dropped while still live, producing:

1. an incorrect `assertion failed` (wrong value read), and
2. `mimalloc: error: corrupted free list entry ...` (heap corruption).

The behaviour is **deterministic** across runs.

## Minimal reproduction

Self-contained, no library dependencies. Save as `repro_perceus.hc` and run `hica test repro_perceus.hc`:

```hica
type Box {
  Wrap(payload: string),
  Empty
}

fun name_of(m: maybe<Box>) : maybe<string> => match m {
  Some(Wrap(v)) => Some(v),
  _ => None
}

test "reref scrutinee then sequential match" {
  let first = Some(Wrap("Hammer"))
  match first {
    Some(Wrap(_)) => {
      let n = name_of(first)      // re-reference `first` inside its own arm
      match n {
        Some(v) => assert(v == "Hammer"),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
  let second = Some(Wrap("Nail"))
  match second {                  // sequential match after the nested-match arm
    Some(Wrap(_)) => {
      let n = name_of(second)
      match n {
        Some(v) => assert(v == "Nail"),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}
```

## Expected vs actual

**Expected:** test passes (`first` holds `Wrap("Hammer")`, `second` holds `Wrap("Nail")`).

**Actual (deterministic):**

```
running 1 test(s)...

  ✗ reref scrutinee then sequential match
    assertion failed

1 test(s) failed, 0 passed
mimalloc: error: corrupted free list entry of size 24b at 0x0200000200E0: value 0x...
```

The same logic written **without** re-referencing the scrutinee — binding the value first,
then matching once — passes cleanly:

```hica
let first_name = name_of(Some(Wrap("Hammer")))   // don't re-touch the scrutinee
match first_name {
  Some(v) => assert(v == "Hammer"),
  _ => assert(false)
}
```

## Generated Koka (miscompiled)

`hica` emits the following for the test body (surface looks correct; the fault is in the
Perceus drop insertion, not the visible structure):

```koka
fun hc_name_of(m : maybe<box>) : maybe<string>
  match m
    Just(Wrap(v)) -> Just(v)
    _ -> Nothing

fun hctest0()
  val first = Just(Wrap("Hammer"))
  match first
    Just(Wrap(_)) ->
      val n = hc_name_of(first)      // `first` reused after Just(Wrap(_)) match
      match n
        Just(v) -> hc-assert((v == "Hammer"))
        _ -> hc-assert(False)
    _ -> hc-assert(False)
  val second = Just(Wrap("Nail"))
  match second
    Just(Wrap(_)) ->
      val n = hc_name_of(second)
      match n
        Just(v) -> hc-assert((v == "Nail"))
        _ -> hc-assert(False)
    _ -> hc-assert(False)
```

## Root-cause hypothesis

Matching `first` against `Just(Wrap(_))` with a nested wildcard appears to let Perceus treat
the inner `Wrap` payload as consumed/dropped, even though the scrutinee `first` is still live
and is passed to `hc_name_of(first)` in the same arm. The subsequent sequential `match second`
reuses the freed heap slot, corrupting the free list. The nested wildcard (`_`) inside the
constructor pattern is significant — it changes how the drop is inserted versus binding the
inner value.

## Trigger conditions (all three needed)

1. A constructor pattern with a **nested wildcard**, e.g. `Some(Wrap(_))` / `Just(Con(_))`.
2. The **scrutinee variable is used again inside that arm** (here, passed to `name_of`).
3. **Another `match` runs sequentially afterward** in the same block.

Removing any one of these avoids the crash.

## Workaround

Bind the extracted value **before** matching and do not re-reference the scrutinee inside its
own arm (this is also the more idiomatic pipe-style hica):

```hica
let first_name = name_of(first)
match first_name { Some(v) => ..., _ => ... }
```

## Where it surfaced

`toml` library, `tests/test_array_tables.hc` — the `array of tables value access` test used
`match first { Some(TTable(_)) => { let n = first.at("name") ... } }` followed by the same
pattern on `second`. The parser and API were correct (a standalone program printed the right
values); only the test-harness codegen crashed. Rewritten to the workaround pattern; all
129 library tests now pass.

## Suggested fix area

`src/emit/codegen.kk` — Perceus drop/dup insertion for constructor patterns with nested
wildcards when the scrutinee remains live in the arm body. Likely needs a `dup` on the
scrutinee (or suppression of the payload drop) when the matched variable is referenced again
after a `Con(_)` pattern. Add the minimal repro above as a codegen regression test.
