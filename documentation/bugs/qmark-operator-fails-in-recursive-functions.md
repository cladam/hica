# Bug: `?` operator fails to compile in any recursive function (infinite-type effect error)

- **Reported by:** TOML library team
- **Date:** 2026-07-11
- **hica version:** 0.41.3
- **Koka version:** 3.2.3 (ghc release, Mar 18 2026)
- **Platform:** macOS / Darwin arm64 (Apple Silicon)
- **Severity:** High — blocks the `?` operator's primary use case (recursive-descent parsers)
- **Area:** effect inference / codegen for `?` (`hica-early-result` / `hica-early-maybe` handlers) in recursive groups

## Summary

The `?` operator introduces the `hica-early-result` (or `hica-early-maybe`) algebraic effect
into the enclosing function. When that function is **self-recursive or mutually recursive**,
effect inference produces an **infinite type** and compilation fails:

```
inferred effect: _e
expected effect: <hica-early-result<string>|_e>
```

Because virtually every function in a recursive-descent parser is recursive, `?` cannot be
used there — which is exactly the workload the backlog cites as the motivation for `?`
("Eliminates nested `match` chains that bubble `Err(e)` — the single biggest source of parser
boilerplate in hica today").

## Minimal reproduction

Fully self-contained. Save as `repro.hc` and run `hica run repro.hc`:

```hica
fun step(n: int) : result<int, string> =>
  if n < 0 { Err("neg") } else { Ok(n) }

fun countdown(n: int) : result<int, string> {
  let v = step(n)?              // `?` introduces hica-early-result effect
  if v == 0 { Ok(0) } else { countdown(v - 1) }   // recursive call
}

fun main() {
  match countdown(5) {
    Ok(v) => println("ok: " + show(v)),
    Err(e) => println("err: " + e)
  }
}
```

## Expected vs actual

**Expected:** compiles; prints `ok: 0`.

**Actual:** compile error:

```
repro.hc(3, 25): type error: types do not match (due to an infinite type)
  context        : fun hc_countdown(n : int)
                   ...
                     if (v == 0) then Right(0) else hc_countdown((v - 1))
  inferred effect: _e
  expected effect: <hica-early-result<string>|_e>
  hint           : give a type to the function definition?

Failed to compile repro.kk
error: koka failed with exit code 256
```

## Notes

- `?` works fine in **non-recursive** functions, including with tuple destructuring
  (`let (a, b) = expr?`), confirmed working.
- Failure occurs for both `result<T,E>` (`hica-early-result`) and is expected to occur
  identically for `maybe<T>` (`hica-early-maybe`).
- Applies to **self-recursion** (repro above) and **mutual recursion**. Observed originally in
  the TOML parser on `parse_array` (self+mutually recursive via `parse_value`) and the
  string-scanner cycle (`scan_key_unicode` ↔ `scan_basic_string` ↔ `scan_escape`), both with
  the same `<div, hica-early-result<string>|_e>` mismatch.
- The `hint: give a type to the function definition?` is misleading — the function already
  has a full `: result<int, string>` annotation. The problem is the effect row, not the
  return type, and there is no surface syntax to annotate/close the effect row.

## Root-cause hypothesis

`?` desugars to a `with` handler for the `hica-early-*` effect wrapped around the function
body. At the recursive call site, the callee's effect row still contains the un-discharged
`hica-early-result` row variable, so unifying the call's effect with the body's effect creates
a recursive (infinite) effect type. The handler is presumably being placed such that the
recursive call is *inside* the handled region while the row is still open, instead of the
recursive call seeing a fully-discharged effect.

## Suggested fix direction

- Insert the `hica-early-*` handler so the recursive call observes the discharged effect row
  (handle at the function boundary and have recursion target the handled function), or
- Emit an explicit closed effect annotation on the generated Koka function so the row variable
  does not escape into the recursive call, or
- At minimum, detect `?` used inside a recursive group in the checker and emit a clear
  diagnostic instead of a Koka-level infinite-type error.

## Impact / workaround

Until fixed, recursive functions must keep the explicit `match { Err(e) => Err(e), Ok(x) => … }`
passthrough. In the TOML library, `?` could only be applied to the two non-recursive helpers
(`expect_eol`, `finish_bare`); all recursive parser functions retain manual error threading.
