---
layout: default
title: JavaScript Target - hica
---

# JavaScript Target

hica can compile `.hc` files to self-contained JavaScript instead of Koka. This enables running hica programs in Node.js or in a browser-based playground without needing the Koka compiler at runtime.

```sh
hica build examples/hello.hc --target=js
node examples/hello.js
```

## Supported Features

The JS backend handles most of hica's core language:

| Feature | Status |
|---------|--------|
| Functions, closures, recursion | ✅ |
| If/else, match expressions | ✅ |
| Structs (construction, field access, update) | ✅ |
| Enums (type declarations, pattern matching) | ✅ |
| Lists, tuples | ✅ |
| List patterns (`[x, ..rest]`) | ✅ |
| Struct patterns | ✅ |
| Tuple destructuring (`let (a, b) = ...`) | ✅ |
| Pipe operator (`\|>`) | ✅ |
| String interpolation | ✅ |
| For-loops, while-loops | ✅ |
| Lambda expressions | ✅ |
| Higher-order functions | ✅ |
| Maybe (`Some`/`None`) and Result (`Ok`/`Err`) | ✅ |
| Math, string, list standard library | ✅ |
| File I/O (`read_file`, `write_file`) | ✅ (Node.js only) |
| System clock (`now_unix`, `now_iso`, `unix_to_iso`) | ✅ |
| CLI args (`get_args`) | ✅ (Node.js only) |

## Limitations

The following features are **not supported** in the JS target:

- **Effects, handlers, and actors** — user-defined `effect` declarations, `handle E { ... } in { ... }` expressions, `spawn Name { ... } as ref`, and the `actor` sugar. These map to Koka's delimited continuations and have no JavaScript equivalent. The JS backend rejects them at compile time with a clear error pointing at the offending source line; use the default native (Koka) target for effectful code. **This includes the REPL and the browser playground**, which both share the JS codegen.
- **External Koka imports** — `extern` declarations that call Koka or C functions won't work.
- **Advanced type features** — Rank-2 types and effect rows are not emitted.
- **Interactive I/O** — `readline()` and terminal interaction are not available.
- **Multi-module builds** — Each `.hc` file compiles to a single `.js` file. Cross-module imports are not resolved in JS mode.

Example of the rejection:

```
$ hica build --target=js examples/effects/hello-effect.hc
error[examples/effects/hello-effect.hc:8:1]: effect declarations are not supported by the JavaScript backend — use the default native (Koka) target for effects/handlers/actors
 8 | effect Log {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
error[examples/effects/hello-effect.hc:17:3]: handle expressions are not supported by the JavaScript backend — use the default native (Koka) target for effects/handlers/actors
17 |   handle Log {
   |   ^^^^^^^^^^^^^^^^...
build: 2 unsupported construct(s) for --target=js
```


## Runtime Preamble

The generated JS file includes a self-contained runtime preamble with implementations of hica's standard library functions. No external dependencies are needed — the output runs with plain `node` or in a `<script>` tag.

Key runtime functions provided:

- **Output**: `println`, `print`, `show`
- **Lists**: `head`, `tail`, `map`, `filter`, `fold`, `foreach`, `zip`, `sort`, `reverse`, `take`, `drop`, `concat`, `cons`, `find`, `all`, `any`, `enumerate`
- **Strings**: `split`, `join`, `trim`, `replace`, `contains`, `starts_with`, `ends_with`, `to_upper`, `to_lower`, `pad_left`, `pad_right`, `words`, `lines`
- **Math**: `abs`, `min`, `max`, `random`, `is_even`, `is_odd`
- **Maybe**: `Some`, `None`, `is_some`, `is_none`, `unwrap`, `unwrap_or`, `map_maybe`, `and_then`
- **Result**: `Ok`, `Err`, `is_ok`, `is_err`, `unwrap_result`, `map_result`, `map_err`
- **I/O** (Node.js): `read_file`, `read_lines`, `write_file`, `get_args`
- **Time**: `now_unix`, `now_iso`, `unix_to_iso`
- **Parsing**: `parse_int`, `parse_float`, `to_int`

## REPL

hica includes an interactive REPL powered by the JS backend:

```sh
hica repl
```

The REPL evaluates expressions, function definitions, struct/type declarations, and import statements incrementally. State accumulates across inputs — functions defined in one line are available in subsequent lines.

```
hica> 1 + 2
3
hica> fun square(x: int) : int { x * x }
hica> square(7)
49
hica> struct Point { x: int, y: int }
hica> let p = Point { x: 3, y: 4 }
Point(x: 3, y: 4)
```

## Playground

The JS target is designed for the hica web playground. The generated code collects output into a `__hc_output` array, making it easy to display results in a browser UI without a server-side compiler.

## Testing

The JS backend is validated by `tests/test-js.sh`, which compiles a set of examples to both Koka (native) and JS, then compares their output:

```sh
bash tests/test-js.sh ./hica
```

All examples listed in the test script must produce identical output from both backends.
