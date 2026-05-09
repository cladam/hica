# Hica Backlog

Consolidated backlog of language features, CLI improvements, and tooling.
Items are grouped by area and roughly ordered by complexity within each group.

Legend: **done** = shipped, **—** = not started

---

## Language Features

### Expressions & Operators

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Unary negation (`-x`, `!x`) | **done** | Low | Lexer, parser, checker, codegen |
| `else if` chains | **done** | Low | Parser desugaring |
| Pipe operator `\|>` | **done** | Low | Desugar `a \|> f` → `f(a)` in parser |
| String concatenation (`+` on strings) | **done** | Low | Checker + codegen |
| String interpolation (`"score: {n}"`) | **done** | Medium | Lexer + parser + codegen |
| String utility functions | **done** | Low | `str_length`, `contains`, `trim`, `trim_start`, `trim_end`, `split`, `replace`, `to_upper`, `to_lower`, `starts_with`, `ends_with`, `join(list, sep)`, `index_of(str, substr)` → `maybe<int>`. Extern sigs backed by Koka `std/core/string` + higher-level helpers written in hica (`prelude/strings.hc`): `is_empty`, `is_blank`, `words`, `lines`, `unwords`, `unlines`, `count_substr`, `repeat_str`, `pad_left`, `pad_right`, `center`, `surround`, `capitalise`, `capwords`, `removeprefix`, `removesuffix` |
| String indexing & slicing (`s[0]`, `s[1:]`) | **done** | Low | Reuses `ListIndex`/`ListSlice` AST; checker branches on `TString` (returns `char` for index, `string` for slice); codegen emits `.list[i].unjust` / `.list.drop().take().string`. Enabled new prelude functions: `capitalise`, `capwords`, `removeprefix`, `removesuffix` |
| String comparison (`<`, `>`, `<=`, `>=`) | **done** | Low | Lexicographic ordering on strings. Checker allows comparison ops on `TString`; Koka `compare` handles strings natively. Needed by hica-semver's prerelease identifier comparison |
| Type annotations in syntax (`: int`) | **done** | Medium | Escape hatch when inference fails. Parser + AST + checker unification. Supports `let x: int`, `fun f(a: int) : int`, all types |
| Bitwise operations (`bit_and`, `bit_or`, `bit_xor`, `bit_not`, `bit_shl`, `bit_shr`) | **done** | Low | Function-call API backed by Koka `std/num/int32`. Converts `int` → `int32`, applies op, converts back. Works with UFCS: `flags.bit_and(0x0F)`. 32-bit signed range; values clamped on conversion |

### Pattern Matching

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Int literal patterns | **done** | — | `0 => ...`, `1 => ...` |
| Wildcard patterns | **done** | — | `_ => ...` |
| Variable patterns | **done** | — | `n => ...` |
| String literal patterns | **done** | Low | Parser + checker; codegen already emits strings |
| Constructor patterns (`Some(x)`, `None`, `Ok(x)`, `Err(e)`) | **done** | Medium | Maybe/result pattern matching in `match` arms |
| Match exhaustiveness checking | **done** | Medium | Warns on missing cases for Maybe, Result, Bool, and literal types |
| Destructuring patterns (tuples/structs) | tuples **done** | Medium | Depends on tuple/struct types; struct patterns not yet implemented |
| Or-patterns (`1 \| 2 \| 3 => ...`) | **done** | Medium | Multiple patterns per arm; emits Koka native or-patterns |
| Match guards (`n if n > 5 => ...`) | **done** | Medium | `pattern if cond => body`; guard parsed after pattern, type-checked as bool, emitted as Koka `pattern \| cond ->`; guarded arms excluded from exhaustiveness check |
| Tuple destructuring patterns (`(a, b) => ...`) | **done** | Low | Koka handles tuple patterns directly; just parse + emit |
| Range patterns (`4..=6 => ...`) | **done** | Medium | Desugar to match guard (`x >= 4 && x <= 6`); depends on guards |
| Slice patterns (`[first, ..rest]`) | — | High | Depends on list types |

### Data Types

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Float / double literals (`3.14`) | **done** | Low | Koka `float64`; lexer + parser + checker + codegen |
| Tuples (`(1, "hi")`, `.0`, `.1`) | **done** | Low | Koka has native tuples; parser + emitter only |
| Tuple destructuring (`let (a, b) = pair`) | **done** | Low | Parser + codegen |
| Lists (`[1, 2, 3]`) | **done** | Medium | Koka `list<a>`; same literal syntax |
| List operations (`map`, `filter`, `fold`) | **done** | Medium | Extern sigs in prelude; `fold` → Koka `foldl` |
| List indexing (`list[0]`, `list[-1]`) | **done** | Medium | Negative index → length adjustment; `.unjust` unwrap |
| List slicing (`list[1:3]`, `list[:2]`, `list[2:]`) | **done** | Medium | Emit `drop`/`take` composition |
| List concat with `+` | **done** | Low | Checker allows `+` on lists; codegen emits `++` |
| `in` operator (`x in list`) | **done** | Medium | New binop; emits `list.any(fn(el) el == x)` |
| `enumerate(list)` | **done** | Low | Prelude sig; emits Koka `map-indexed` |
| `find(list, fn)` | **done** | Low | Prelude sig; return `maybe<a>`; emits Koka `list.find(fn)` |
| `all(list, fn)` | **done** | Low | Prelude sig; emits Koka `list.all(fn)` |
| Character literals (`'c'`) | **done** | Low | Koka `char`; single-quote syntax |
| Maybe type (`Some` / `None`) | **done** | Medium | Koka `maybe<a>`; `Some` → `Just`, `None` → `Nothing` |
| Result type (`Ok` / `Err`) | **done** | Medium | Koka `either<a,b>`; `Ok` → `Right`, `Err` → `Left` |
| Structs (`struct Point { x: int, y: int }`) | **done** | Medium | Emit Koka `struct`. Sub-tasks: construction (`Point { x: 1, y: 2 }`), field access (`p.x`), auto-generated `show`. Update syntax: `{ ...old, x: 5 }` not yet implemented. Motivation: hica-diff's hunk state needs 8+ fields (exceeds tuple5 limit); hica-semver's `(major, minor, patch, pre, build)` is cleaner as named fields |
| Algebraic types / enums | **done** | High | `type Color { Red, Green, Blue }`. Emit Koka `type` with variants. Constructors with data: `Circle(radius: float)`. Pattern matching on constructors: `Circle(r) => ...`. Exhaustiveness checking for enum variants. Auto-generated `show` function. Parser resolves PascalCase to constructor vs struct via lookahead |
| Maps / dictionaries | **done** | High | `{"key": value}` literal syntax, `{:}` empty map. Functions: `map_get`, `map_set`, `map_remove`, `map_keys`, `map_values`, `map_contains_key`, `map_size`. Represented as list of tuples; all list operations work on maps. Codegen emits Koka list-of-tuples operations |
| User input (`input("prompt")`) | **done** | Medium | Koka `readline`; returns `string`, combine with parse fns |
| File I/O (`read_file`, `write_file`, `read_lines`) | **done** | Medium | `read_file(path)` → `result<string, string>`, `write_file(path, content)` → `()`, `read_lines(path)` → `list<string>`, `write_lines(path, lines)` → `()`. Koka `std/os/file` `read-text-file` / `write-text-file`. `read_file` returns result; use `unwrap` / `unwrap_or` / `match` |
| Parse functions (`parse_int`, `parse_float`) | **done** | Low | Prelude externs; return `maybe<int>` / `maybe<float>` |
| Type conversion (`to_int`, `to_float`) | **done** (`to_int`) | Low | `to_int(str)` → `int` (returns -1 on invalid); emits Koka `parse-int` with match. `to_float` still needed |
| Maybe/Result combinators (`unwrap_or`, `map_maybe`, `and_then`) | `unwrap`/`unwrap_or` **done** | Medium | `unwrap(result)` → value or throw; `unwrap_or(result, default)` → value or default. Maybe combinators and `map`/`and_then` still needed |
| `?` operator (early return on Err/None) | — | High | Needs a return/early-exit mechanism; Koka uses effects for this |
| Environment (`get_args()`, `get_env(key)`, `eprintln`) | **done** | Low | `get_args()` → `list<string>`, `get_env(key)` → `maybe<string>`, `eprintln` → stderr via `trace` |
| Mutable variables (`var x = 10; x = 5`) | **done** | Medium | `var` declares mutable local; `x = expr` reassigns. Emits Koka `var x := 10` / `x := 5`. Effect-safe via Koka's algebraic `local-var` — can't leak scope |

### Control Flow

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| `if` / `else if` / `else` | **done** | — | Expression-valued |
| `match` | **done** | — | Int + wildcard + var patterns |
| `repeat(n) { ... }` | **done** | – | Emit Koka `repeat` |
| `while condition { ... }` | **done** | Medium | Emit Koka `while { condition } { body }` |
| `for i in 0..n` (range loop) | **done** | Medium | Emit Koka `for(0, n) fn(i)` |
| `for x in list` (collection loop) | **done** | Medium | Emit Koka `list.foreach(fn(x) { body })` |
| `loop { ... }` (infinite loop) | **done** | Low | Emit Koka `while { True }` with break handler |
| `break` / `continue` | **done** | Medium | Koka effect-based control flow: `hica-brk`/`hica-cont` effects with `ctl` handlers; works in all loop types (`while`, `for`, `repeat`, `loop`) |

### Functions

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Named functions (`fun f(x) => ...`) | **done** | — | Arrow + block bodies |
| Lambdas (`(x) => x * 2`) | **done** | — | Desugars to `Fun` node |
| Higher-order functions | **done** | — | Checker infers `TFun` types |
| Self-recursion | **done** | Medium | Checker pre-seeds env; codegen omits annotation for `div` |
| Mutual recursion | — | Medium | Needs fixpoint or two-pass approach |
| Returning closures from functions | **done** | Medium | Codegen omits function-typed return annotations; Koka infers them |
| User-defined higher-order functions | **done** | Medium | Codegen omits incomplete `TFun` annotations; Koka infers them |

### Modules & Visibility

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Single-file compilation | **done** | — | `.hc` → `.kk` |
| Prelude (`prelude.hc`) | **done** | Low | Auto-load & prepend stdlib fns (abs, min, max …) before user code; no module system needed |
| `import "mymodule"` | — | High | Multi-file compilation, module graph. Sub-tasks: file resolution, selective imports (`from "math" import { sin, cos }`), qualified names (`math.sin(x)`) |
| `pub` visibility | **done** | Medium | Emit Koka `pub` |

---

## Compiler Infrastructure

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Lexer | **done** | — | |
| Parser | **done** | — | |
| Type checker (HM inference) | **done** | — | Phases 0–4 |
| Diagnostics (`diag` effect) | **done** | — | Errors with spans |
| Codegen (type annotations) | **done** | — | Phase 5 |
| Name resolution | **done** | — | Phase 6; only declared names get `hc_` |
| Module keyword clash fix | **done** | — | `match.hc` → `hc-match.kk` |
| Structured error output with source snippets | **done** | Medium | Line:col + source line + caret underline |
| Desugaring pass | — | Medium | Separate pass for complex transforms |

---

## CLI

| Command | Status | Complexity | Notes |
|---------|--------|------------|-------|
| `hica build <file>` / `hica b` | **done** | — | Lex → parse → check → emit → koka |
| `hica run <file>` / `hica r` | **done** | — | Build + execute |
| `hica check <file>` / `hica c` | **done** | — | Type check + report |
| `hica clean` | **done** | — | Remove generated files |
| `hica help <command>` | **done** | — | |
| `hica --version` | **done** | — | via klap |
| `hica new <name>` | **done** | — | Scaffold with hica.ini, main.hc, README.md |
| `hica init` | **done** | — | Initialise in current directory |
| `hica fmt` / `hica fmt --check` | — | Medium | Pretty-printer (Wadler-Leijen) |
| `hica test [file]` | **done** | High | Built-in test runner. `test "name" { ... }` blocks in `.hc` files; `assert(expr)`, `assert_eq(a, b)` builtins; collect all test blocks, emit as Koka fns, run + report pass/fail with ANSI colors. Exit code 1 on failure. No modules, no annotations, no imports needed. Short alias: `hica t` |

### The "fmt" Implementation Goal

For hica fmt tool, these rules should be the "Gold Standard":
 1. **Remove** trailing whitespace.
 2. **Enforce** a single space around operators (+, -, *, %, ==).
 3. **Insert** a single blank line between top-level definitions.
 4. **Auto-wrap** long pipe chains.
 5. **Remove** spaces inside parentheses, brackets, and braces.
 6. **Remove** spaces before function call parentheses.
 7. **Enforce** space after commas.
 8. **Enforce** space after colon in type annotations, no space before.

---

## Stand-Outs

Tactical changes to differentiate hica from similar-looking languages.

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Expose effect types in `hica check` | **done** | Medium | `hica check` now prints discovered effect types after successful analysis. Example: `check: main.hc — ok (2 declarations, 0 errors) [<console, fsys>]`. Pure programs show `[pure]`. Scans AST for calls to known effectful functions (println→console, read_file→fsys, input→io, random→ndet) and flags recursive functions as `div` |
| `random(min, max)` | **done** | Medium | Random integer in `[min, max]` (inclusive both ends). Extern backed by Koka `srandom-int32-range` (codegen adds +1 to max for inclusive semantics). Adds `ndet` effect. Codegen imports `std/num/random` + `std/num/int32` when used. Learn module: `learn/28-random.hc` |
| `show_fixed(value, decimals)` | **done** | Low | Format float to fixed decimal places. Extern backed by Koka `show-fixed`. Learn module: `learn/29-format.hc` |
| UFCS support (`a.f(b)` → `f(a, b)`) | **done** | Low/Medium | Parser desugars `expr.f(args)` to `f(expr, args)` in the postfix loop. Struct field access (`p.x`) still works when no `(` follows. Users can write `5.triple().inc()`, `nums.map(fn).filter(fn)`, `s.trim().to_upper()`. Equivalent to pipe but reads left-to-right. See `examples/ufcs.hc` |
| Binary & hex integer literals (`0b1010`, `0xFF`) | **done** | Low | `0b`/`0B` for binary, `0x`/`0X` for hex. Underscore separators in all integer literals (`1_000_000`, `0b1111_0000`, `0x00_FF`). All produce `TkInt(n)` — no AST changes. Prerequisite for bit-level matching |
| Bit-level matching in `match` | **done** | Medium/High | Allow `match` to work on bit patterns with don't-care bits: `0b1100_xxxx => "high nibble C"`. Desugars to mask-and-compare guards: `(signal.and(0xF0)) == 0xC0`. Needs: new `PBits(mask: int, value: int)` pattern in AST, parser support for `x` wildcard bits inside `0b` literals in pattern position, codegen emitting `.and(mask) == value` guard. Identity angle: "hardware-aware functional programming" — unique among teaching/functional languages. Real-world use: packet headers, CPU instruction decoding, hardware registers, binary format parsing. Similar to Erlang/Elixir binary matching but at the bit level |

---

## Known Limitations

Issues that exist today but are not yet fixed:

- **~~`println` reports "undefined variable"~~** — Fixed by prelude.
  `println`, `show`, `abs`, `min`, `max` are now seeded into the type
  checker's environment. Note: `show` is typed as `(int) -> string`;
  calling it on non-int types still triggers a type error but compiles fine.
- **Polymorphic functions over tuples** — a function like
  `fun swap(p) => (p.1, p.0)` leaves param/return types unresolved (TVar).
  The generated Koka code omits annotations, but Koka can't always resolve
  `.fst`/`.snd` without them. **Workaround:** use type annotations:
  `fun swap(p: (int, int)) : (int, int) => (p.1, p.0)`.
- **~~`show` gets marshalled to `hc_show` in user functions~~** — Fixed.
  `show` is now mapped directly to Koka's `show` in codegen, bypassing the
  `hc_` prefix. Both `show(42)` and `"{n}"` work correctly.
- **Tuples limited to 5 elements** — Koka defines tuple types up to `tuple5`.
  The checker now rejects tuples with > 5 elements.
- **No cross-function type propagation** — each function is inferred
  independently. Call-site constraints don't refine a callee's inferred types.

---

## What We Defer

These are explicitly **not** in scope near-term:

- **Row polymorphism / effect inference** — Koka handles this
- **Generics / let-polymorphism** — add later when needed
- **Sets** — Koka has no built-in set; use maps
- **Interfaces / traits** — Koka's effects cover many of the same use cases
