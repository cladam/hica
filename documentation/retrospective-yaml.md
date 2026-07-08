# Retrospective: YAML Library in hica

## What Worked Well

- **Module system** — `pub import` barrel pattern (yaml.hc re-exporting sub-modules) is clean and scales well. Multi-file layout straightforward.
- **Test runner** — `hica test` is fast and simple. 201 tests across 13 files, all runnable individually. No test framework boilerplate.
- **Pipe-friendly design** — `yaml_parse(input) |> yaml_ok |> at("key") |> as_str` reads naturally.
- **Expression bodies** — `=> if ... { } else { }` keeps small functions concise.
- **Iteration speed** — `hica check` for syntax/type feedback is instant. Full test runs take seconds.

## Friction Points

| Issue | Workaround | Severity |
|-------|-----------|----------|
| `option<int>` not supported as return type annotation | Use `int` with `-1` sentinel | Medium |
| `div` effect only propagates via `=>` + direct recursive call | Restructure callers to directly call the recursive function | High |
| `{`/`}` in strings triggers interpolation | `join(["{", content, "}"], "")` | Low once known |
| `"".split("")` infinite loop at runtime | Guard with `str_length == 0` check | Medium — silent hang |
| `let` bindings inside nested match arms | Restructure to avoid nesting | Medium |
| `|>` + `==` inside `assert()` | Use `let` binding first, then `assert` | Low once known |
| Nested match inside match arms | Flatten or use helpers | Medium |

## The `div` Effect Problem

Biggest time sink. The rule is non-obvious: a function only inherits `div` if it uses `=>` AND directly calls a self-recursive function. Calling through a non-recursive wrapper (even one that has `div`) doesn't propagate. Required:

- Making `is_map_line` call `find_kv_split_acc` directly (skipping the wrapper)
- Making `kv_key`/`kv_val` do the same
- Inlining `escape_yaml_chars` into `emit_scalar_value`

This constraint shapes code architecture in ways that aren't intuitive.

## Error Reporting

- hica parse errors give byte offsets, not line numbers — requires `head -c N | tail` to locate
- Koka type errors reference generated `.kk` files, not `.hc` source — mental translation required
- Two-phase compilation means you debug hica syntax or Koka types, never both at once

## Verdict

The language is expressive and the output is clean. Pipe API, pattern matching, and module system feel well-designed. But `div` effect propagation and parser limitations create a "minefield" — natural-looking code hits walls requiring restructuring. Once you learn the patterns, velocity improves significantly.

**Rating:** Productive once you know the constraints. Workarounds are mechanical, not fundamental. A few compiler fixes (div propagation, generic return types, better error locations) would eliminate most friction.
