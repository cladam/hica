## HML Library Retrospective — Developing in Hica

**What worked well:**

- **Recursive descent + pattern matching** is a natural fit. The parser reads almost like a specification — `match parse_key_path(...)` → `match parse_value(...)` chains are clear and composable.
- **The test runner** (`hica test`) gave fast, focused feedback. 129 tests across 7 files caught regressions immediately.
- **Multi-file module layout** (types → parser → api → display → barrel) kept things navigable even as parser.hc grew to 1000+ lines.
- **Pipe-friendly API** fell out naturally — `at(body, "host") |> as_str` is pleasant to write and read.

**Pain points:**

- **Parameter threading is brutal.** Adding `text_elems` meant touching every recursive call in 3 functions. Then adding `dotted_names` meant doing it all again. A parser state record would eliminate this, but Hica doesn't support that pattern cleanly yet.
- **The `let`-in-`if/else` bug** forced awkward restructuring — extracting tiny helper functions (`first_segment`, `add_if_missing`) just to avoid codegen issues. You end up thinking about the compiler more than the problem.
- **Stale `.kk` cache files** caused phantom errors repeatedly. `rm src/*.kk` became muscle memory. This is a tooling gap that will trip up every new user.
- **`head()` returning `maybe`** is type-safe but ergonomically rough when you've already checked `length > 1`. A `head_or(list, default)` in the stdlib would help.
- **Koka keyword collisions** (`prefix`) surface late — you write valid Hica, it compiles to invalid Koka. Hard to predict.

**Patterns that emerged:**

- Always make library functions `pub` — non-pub causes cryptic "undefined variable" through the barrel.
- Use `join()` instead of `+` for strings containing braces or single chars.
- Flatten if/else chains instead of nesting (dangling-else codegen bug).
- Commit after each feature, not after "everything works" — the stale cache issues make it important to have known-good checkpoints.

**Bottom line:** Hica is productive for this kind of work — the type system catches real bugs, pattern matching is expressive, and the compilation is fast enough for tight iteration. But you're still working around a young compiler. The gap between "this should work" and "this actually compiles" ate maybe 30% of the session time. For a 1.0 library, the result is solid — but I wouldn't call the DX frictionless yet.