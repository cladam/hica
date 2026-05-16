# Retrospective: TOML Library in Hica

## What Went Well

- **`hica test`** — Zero-friction test cycle. The 129-test suite was pleasant to build incrementally.
- **Pipe-friendly API** — `doc.at("key").as_str` is clean and idiomatic. UFCS gives chainable feel without method syntax.
- **Module system** — Multi-file layout with `pub import` barrel module worked well once established.
- **Pattern matching** — Recursive descent parser reads like its grammar rules.
- **`result<T, string>`** — Error threading with match arms composes well for parse → validate → insert pipelines.

## Pain Points

| Issue | Impact | Status |
|-------|--------|--------|
| `div` effect leakage | Non-recursive helpers calling recursive fns fail with cryptic Koka errors | Known — workaround: inline into recursive group |
| `let` inside `if/else` branches | Codegen bug forces restructuring (hoisting, helper functions) | Open bug |
| String interpolation with `{` | Triggers interpolation; requires `\u007B`/`join()` workarounds | By design — needs escape syntax |
| `+` operator char/string ambiguity | Forces `join()` instead of natural concat | Known — workaround: use `join()` |
| No early return | 6-7 levels deep match/if chains in parser code | **Fixed**: `?` operator shipped |
| Compile times | Full dependency tree recompiled per test file | Koka limitation |

## Lessons for Hica Development

1. Build one feature at a time, test immediately.
2. Keep all library functions `pub`.
3. Avoid wrapper functions around recursive helpers — inline or make mutual.
4. Use `join([...], "")` for strings with special characters or mixed types.

## Verdict

Hica is viable for real library development. 930-line parser with full TOML v1.1.0 coverage. Rough edges are predictable once known — all in codegen, not language design.
