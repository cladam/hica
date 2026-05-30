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
| Brace escape in strings (`\{`, `\}`) | **done** | Low | `\{` and `\}` in strings produce literal `{`/`}`. Lexer handles both plain and interpolated strings. Reported by TOML team |
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
| Destructuring patterns (tuples/structs) | **done** | Medium | Tuple patterns: `(a, b) => ...`. Struct patterns: `Point { x, y } => ...`, `Point { x: 0, y } => ...`. Partial patterns (unmentioned fields are wildcards). Checker validates field names against struct definition |
| Or-patterns (`1 \| 2 \| 3 => ...`) | **done** | Medium | Multiple patterns per arm; emits Koka native or-patterns |
| Match guards (`n if n > 5 => ...`) | **done** | Medium | `pattern if cond => body`; guard parsed after pattern, type-checked as bool, emitted as Koka `pattern \| cond ->`; guarded arms excluded from exhaustiveness check |
| Tuple destructuring patterns (`(a, b) => ...`) | **done** | Low | Koka handles tuple patterns directly; just parse + emit |
| Range patterns (`4..=6 => ...`) | **done** | Medium | Desugar to match guard (`x >= 4 && x <= 6`); depends on guards |
| Slice patterns (`[first, ..rest]`) | **done** | High | Depends on list types |

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
| Structs (`struct Point { x: int, y: int }`) | **done** | Medium | Emit Koka `struct`. Sub-tasks: construction (`Point { x: 1, y: 2 }`), field access (`p.x`), auto-generated `show`, update syntax (`{ ...old, x: 5 }`). Motivation: hica-diff's hunk state needs 8+ fields (exceeds tuple5 limit); hica-semver's `(major, minor, patch, pre, build)` is cleaner as named fields |
| Algebraic types / enums | **done** | High | `type Color { Red, Green, Blue }`. Emit Koka `type` with variants. Constructors with data: `Circle(radius: float)`. Pattern matching on constructors: `Circle(r) => ...`. Exhaustiveness checking for enum variants. Auto-generated `show` function. Parser resolves PascalCase to constructor vs struct via lookahead |
| Maps / dictionaries | **done** | High | `{"key": value}` literal syntax, `{:}` empty map. Functions: `map_get`, `map_set`, `map_remove`, `map_keys`, `map_values`, `map_contains_key`, `map_size`. Represented as list of tuples; all list operations work on maps. Codegen emits Koka list-of-tuples operations |
| User input (`input("prompt")`) | **done** | Medium | Koka `readline`; returns `string`, combine with parse fns |
| File I/O (`read_file`, `write_file`, `read_lines`) | **done** | Medium | `read_file(path)` → `result<string, string>`, `write_file(path, content)` → `()`, `read_lines(path)` → `list<string>`, `write_lines(path, lines)` → `()`. Koka `std/os/file` `read-text-file` / `write-text-file`. `read_file` returns result; use `unwrap` / `unwrap_or` / `match` |
| Parse functions (`parse_int`, `parse_float`) | **done** | Low | Prelude externs; return `maybe<int>` / `maybe<float>` |
| Type conversion (`to_int`, `to_float`) | **done** | Low | `to_int(str)` → `int` (returns -1 on invalid); emits Koka `parse-int` with match. `to_float(n)` → `float`; emits Koka `.float64` |
| Maybe/Result combinators (`unwrap_or`, `map_maybe`, `and_then`) | **done** | Medium | `unwrap(result)` → value or throw; `unwrap_or(result, default)` → value or default. Maybe/Result combinators: `map_maybe`, `and_then`, `or_else`, `map_result`, `map_err` |
| `?` operator (early return on Err/None) | **done** | High | Postfix `?` on `maybe<T>` — unwraps `Some(v)` or returns `None` early. Implemented via Koka algebraic effects (`hica-early-maybe`) |
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
| Mutual recursion | **done** | Medium | Two-pass checker: pre-seeds all fn sigs, then checks bodies; cycle detection marks mutually recursive fns so codegen omits return annotations |
| Returning closures from functions | **done** | Medium | Codegen omits function-typed return annotations; Koka infers them |
| User-defined higher-order functions | **done** | Medium | Codegen omits incomplete `TFun` annotations; Koka infers them |

### Modules & Visibility

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Single-file compilation | **done** | — | `.hc` → `.kk` |
| Prelude (`prelude.hc`) | **done** | Low | Auto-load & prepend stdlib fns (abs, min, max …) before user code; no module system needed |
| `import "mymodule"` | **done** | High | Multi-file compilation, module graph. Three forms: `import "path"` (all pub items), `from "path" import { names }` (selective), `pub import "path"` (re-export). File resolution relative to importer, cycle detection, each module compiled to own Koka module |
| `pub` visibility | **done** | Medium | Emit Koka `pub` |
| Parser state record (reduce parameter threading) | **—** | Medium | Recursive-descent parsers currently thread state as extra parameters (e.g. `text_elems`, `dotted_names`). Adding a new piece of state means touching every recursive call in multiple functions. A `struct ParserState { ... }` passed-and-returned would reduce this friction. HML retro: "Parameter threading is brutal — 30% of session time" |

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
| Desugaring pass | **done** | Medium | Separate `transform/desugar.kk` pass between parse and type check. Rewrites PRange → PVar + guard, PBits → PVar + bit_and guard. Simplifies codegen |
| Koka keyword blocklist in checker | **done** | — | Checker emits warnings for Koka reserved words (`raw`, `prefix`, `value`, `control`, etc.) in user code. Prelude/imported code is skipped via skip counts. Codegen `marshal-field` auto-prefixes `hc-` on struct/enum field names that clash with Koka keywords. |

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
| `hica fmt` / `hica fmt --check` | **done** | Medium | Token-stream formatter. Enforces style-guide rules: trailing whitespace, operator spacing, blank line normalisation, bracket spacing, comma/colon formatting. `--check` returns exit 1 if changes needed. Short alias: `hica f` |
| `hica test [file]` | **done** | High | Built-in test runner. `test "name" { ... }` blocks in `.hc` files; `assert(expr)`, `assert_eq(a, b)` builtins; collect all test blocks, emit as Koka fns, run + report pass/fail with ANSI colors. Exit code 1 on failure. No modules, no annotations, no imports needed. Short alias: `hica t` |
| `hica clean --cache` / auto-invalidate | **—** | Medium | Stale `.kk` cache files cause phantom errors after edits. Currently requires manual `rm src/*.kk`. Auto-invalidate on recompile (hash source, compare before reusing `.kk`), or expose `hica clean --cache` to purge intermediate files. HML retro: "became muscle memory — this is a tooling gap that will trip up every new user" |
| `hica build -o <name>` | **done** | Low | Allow naming the output binary: `hica build foo.hc -o myprog`. Supports both `-o name` and `--output name`. Binary placed at the exact path given. Defaults to source stem as before |

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

## REPL

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Basic REPL (`hica repl`) | **done** | High | Expressions, let bindings, fun/struct/type defs, multiline, `_` variable, `:help`/`:defs`/`:reset`/`:history`/`:load`/`:quit` |
| Persistent subprocess for evaluation | **done** | Medium | Persistent Node.js subprocess with bidirectional pipes via `fork`/`pipe`/`exec`. JS snippets sent via stdin, output read from stdout. Uses `vm.runInContext` for proper declaration persistence. Eliminates per-eval process startup cost; `_` persists in subprocess memory (no temp files) |
| REPL tab completion | **done** | Low | Auto-wraps with `rlwrap` when available and stdin is a tty. Writes completions file with prelude function names, REPL commands, and keywords. Falls back gracefully with tip when rlwrap not installed |
| `:type` command | **done** | Low | `:type expr` / `:t expr` — shows inferred type without evaluating. Works on expressions, let bindings, function declarations, structs, and types |
| `:time` command | **skip** | Low | `:time expr` — evaluate and print elapsed time. Not prioritised; skipped |

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

## Prelude Extensions

Standard library functions added to the prelude. Extern functions are backed by Koka stdlib;
pure functions are written in hica itself.

### List Functions (`prelude/lists.hc` + externs)

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `head(xs)` | `(list<a>) -> maybe<a>` | **done** (extern) | First element; emits Koka `xs.head` |
| `head_or(xs, default)` | `(list<a>, a) -> a` | **done** (hica, std/list) | First element or default value. Avoids unwrapping `maybe` after length check. HML retro: "`head()` returning `maybe` is type-safe but ergonomically rough when you've already checked `length > 1`" |
| `tail(xs)` | `(list<a>) -> list<a>` | **done** (extern) | All but first; emits Koka `xs.tail` |
| `flat_map(xs, f)` | `(list<a>, (a) -> list<b>) -> list<b>` | **done** (extern) | Map + flatten; emits Koka `xs.flatmap(f)` |
| `sort_by(xs, cmp)` | `(list<a>, (a, a) -> bool) -> list<a>` | **done** (extern) | Merge sort; `cmp(a, b)` returns true if a should come first. Koka helper emitted when used |
| `intersperse(xs, sep)` | `(list<a>, a) -> list<a>` | **done** (hica) | Insert separator between elements |
| `sum(xs)` | `(list<int>) -> int` | **done** (hica) | Sum via `fold` |
| `product(xs)` | `(list<int>) -> int` | **done** (hica) | Product via `fold` |
| `scan(xs, init, f)` | `(list<a>, b, (b, a) -> b) -> list<b>` | **done** (hica) | Fold with all intermediate results |
| `zip_with(xs, ys, f)` | `(list<a>, list<b>, (a, b) -> c) -> list<c>` | **done** (hica) | Zip + map in one step |
| `unique(xs)` | `(list<a>) -> list<a>` | **done** (hica) | Remove duplicates (preserves first occurrence) |
| `chunks(xs, n)` | `(list<a>, int) -> list<list<a>>` | **done** (hica) | Split into groups of `n` |
| `head_or(xs, default)` | `(list<a>, a) -> a` | **done** (hica, std/list) | First element or default value. Avoids unwrapping `maybe` after length check. HML retro: "`head()` returning `maybe` is type-safe but ergonomically rough when you've already checked `length > 1`" |
| `take_while(xs, pred)` | `(list<a>, (a) -> bool) -> list<a>` | **done** (hica, std/list) | Take elements from the front while predicate holds; stop at first failure |
| `drop_while(xs, pred)` | `(list<a>, (a) -> bool) -> list<a>` | **done** (hica, std/list) | Drop elements from the front while predicate holds; return the rest |
| `count(xs, pred)` | `(list<a>, (a) -> bool) -> int` | **done** (hica, std/list) | Count elements matching predicate. Distinct from `length` — filters first |
| `group_by(xs, f)` | `(list<a>, (a) -> string) -> list<(string, list<a>)>` | **done** (hica, std/list) | Group elements by string key function. Returns list of `(key, group)` pairs in insertion order |
| `min_by(xs, f)` | `(list<a>, (a) -> int) -> maybe<a>` | **done** (hica, std/list) | Element with the smallest int key. Returns `None` on empty list |
| `max_by(xs, f)` | `(list<a>, (a) -> int) -> maybe<a>` | **done** (hica, std/list) | Element with the largest int key. Returns `None` on empty list |

### Math Functions (`prelude/math.hc`)

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `lcm(a, b)` | `(int, int) -> int` | **done** (hica) | Least common multiple; uses `gcd` |
| `pow(base, exp)` | `(int, int) -> int` | **done** (hica) | Integer exponentiation |
| `sign(n)` | `(int) -> int` | **done** (hica) | Returns -1, 0, or 1 |
| `clamp(n, lo, hi)` | `(int, int, int) -> int` | **done** (hica, prelude/math) | Clamp `n` to `[lo, hi]`. Common enough to avoid writing `if n < lo then lo else if n > hi then hi else n` inline |
| `is_even(n)` | `(int) -> bool` | **done** (hica, std/ops) | Returns `n % 2 == 0` |
| `is_odd(n)` | `(int) -> bool` | **done** (hica, std/ops) | Returns `n % 2 != 0` |

### Float Math (externs)

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `sqrt(x)` | `(float) -> float` | **done** (extern) | Square root; emits Koka `sqrt(x)` |
| `floor(x)` | `(float) -> int` | **done** (extern) | Round down; emits `floor(x).int` |
| `ceil(x)` | `(float) -> int` | **done** (extern) | Round up; emits `ceiling(x).int` |
| `round(x)` | `(float) -> int` | **done** (extern) | Round to nearest; emits `round(x).int` |
| `to_float(n)` | `(int) -> float` | **done** (extern) | Int to float conversion; emits `n.float64` |

### Random (`prelude/math.hc` or codegen)

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `random(min, max)` | `(int, int) -> int` | **done** (extern) | Random int in `[min, max]` inclusive. `ndet` effect |
| `random_float()` | `() -> float` | **done** (extern) | Random float in `[0.0, 1.0)`. Koka `srandom-float64`. `ndet` effect |
| `random_shuffle(xs)` | `(list<a>) -> list<a>` | **—** (hica) | Fisher-Yates shuffle using `random`. Returns new shuffled list. `ndet` effect |

### System / Environment (prelude additions)

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `get_env(key)` | `(string) -> maybe<string>` | **done** (extern) | Look up env var; `Some(val)` or `None` |
| `env_require(key)` | `(string) -> string` | **done** (hica, std/env) | Returns value or prints error and returns `""`. Useful in deploy scripts where a missing var is always a programmer error |
| `env_or(key, default)` | `(string, string) -> string` | **done** (hica, std/env) | Returns value or `default`. Thin wrapper over `get_env` + `unwrap_or` |
| `env_int(key)` | `(string) -> maybe<int>` | **done** (hica, std/env) | Look up env var and parse as `int`. Returns `None` if missing or non-numeric |

### Char/String Conversions (externs)

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `chars(s)` | `(string) -> list<char>` | **done** (extern) | String to char list; emits `s.list` |
| `from_chars(cs)` | `(list<char>) -> string` | **done** (extern) | Char list to string; emits `cs.string` |

### Datetime Functions (`prelude/datetime.hc`) — v0.1.0

String-based datetime validation, decomposition, comparison, and weekday calculation.
All functions are pure (no effects). Datetimes are represented as ISO 8601 strings.
No rich types or timezone database yet — deferred to a future version that may
leverage Koka's `std/time`.

| Function | Type | Impl | Notes |
|----------|------|------|-------|
| `is_valid_date(s)` | `(string) -> bool` | **done** (hica) | Validate `YYYY-MM-DD`, handles leap years |
| `is_valid_time(s)` | `(string) -> bool` | **done** (hica) | Validate `HH:MM:SS[.frac]` |
| `is_valid_offset(s)` | `(string) -> bool` | **done** (hica) | Validate `Z`, `+HH:MM`, `-HH:MM` |
| `is_local_date(s)` | `(string) -> bool` | **done** (hica) | Alias for `is_valid_date` |
| `is_local_time(s)` | `(string) -> bool` | **done** (hica) | Alias for `is_valid_time` |
| `is_local_datetime(s)` | `(string) -> bool` | **done** (hica) | Check `YYYY-MM-DDThh:mm:ss[.frac]` |
| `is_iso_datetime(s)` | `(string) -> bool` | **done** (hica) | Check offset datetime with `Z`/`±HH:MM` |
| `datetime_kind(s)` | `(string) -> string` | **done** (hica) | Classify variant: `"local-date"`, `"local-time"`, `"local-datetime"`, `"offset-datetime"`, `"invalid"` |
| `date_parts(s)` | `(string) -> result<(int,int,int), string>` | **done** (hica) | Decompose into `(year, month, day)` |
| `time_parts(s)` | `(string) -> result<(int,int,int), string>` | **done** (hica) | Decompose into `(hour, minute, second)` |
| `datetime_date(s)` | `(string) -> result<string, string>` | **done** (hica) | Extract date portion |
| `datetime_time(s)` | `(string) -> result<string, string>` | **done** (hica) | Extract time portion (offset stripped) |
| `datetime_offset(s)` | `(string) -> maybe<string>` | **done** (hica) | Extract offset, or `None` for local |
| `date_cmp(d1, d2)` | `(string, string) -> int` | **done** (hica) | Returns -1, 0, or 1 |
| `time_cmp(t1, t2)` | `(string, string) -> int` | **done** (hica) | Returns -1, 0, or 1 |
| `datetime_cmp(d1, d2)` | `(string, string) -> int` | **done** (hica) | Compare local datetimes |
| `is_before(d1, d2)` | `(string, string) -> bool` | **done** (hica) | Works on dates, times, local datetimes |
| `offset_to_minutes(s)` | `(string) -> result<int, string>` | **done** (hica) | `"+02:00"` → `120`, `"Z"` → `0` |
| `day_of_week(s)` | `(string) -> result<string, string>` | **done** (hica) | Sakamoto's algorithm; returns `"monday"` etc. |
| `to_unix(s)` | `(string) -> result<int, string>` | **—** | Deferred to Phase 3 — needs calendar math or `std/time` |
| `from_unix(n)` | `(int) -> string` | **—** | Deferred to Phase 3 |
| ISO 8601 durations | — | **—** | Not required by TOML/YAML core schemas; future consideration |

Internal helpers also available: `all_digits`, `in_range`, `days_in_month`, `nth`.

---

## Libraries

Optional libraries that extend hica beyond the prelude. Each is a standalone
importable module following the multi-file pattern established by the yaml library
(types, parser, api, barrel module).

Inspired by common crate categories seen in Rust ecosystems (choreo, tbdflow, etc.).

### Data Formats

| Library | Status | Complexity | Notes |
|---------|--------|------------|-------|
| **json** | **—** | Medium | Parse/emit JSON. Natural companion to the yaml library — same API shape (`parse`, `at`, `as_str`, `as_int`, `as_array`). Multi-file: `types.hc`, `parser.hc`, `api.hc`, `json.hc` barrel. **#1 priority** — every HTTP API response is JSON |
| **csv** | **—** | Low | RFC 4180 CSV parser and writer. `csv_parse(str) : list<list<string>>`, `csv_rows(str, header) : list<map>`, `csv_emit(rows) : string`. Pure hica, no deps. Python's pandas (#33, 669M/month) is the downstream signal — the underlying need is reading tabular data |
| **xml** | **—** | High | XML parsing. Less common but still needed for configs, feeds, legacy APIs |

### Text Processing

| Library | Status | Complexity | Notes |
|---------|--------|------------|-------|
| **regex** | **—** | Medium | String pattern matching. Wrap Koka's `std/text/regex`. Functions: `regex_match`, `regex_find`, `regex_replace`, `regex_split` |
| **template** | **—** | Low | Lightweight string templating. `tmpl_render(template, vars)` where `vars` is a `map`. Supports `{{var}}` substitution and `{% for x in list %}...{% end %}` blocks. Pure hica. Jinja2 is #43 on PyPI (564M/month) — the need is real for config and code generators |
| **case** | **—** | Low | Case-style conversion. `to_snake_case(s)`, `to_camel_case(s)`, `to_kebab_case(s)`, `to_title_case(s)`, `to_upper_snake(s)`. Pure hica string operations. Useful in hica's own codegen and in any tool that generates identifiers. Rust's `heck` crate is used internally by sqlx, clap, and serde |
| **base64** | **done** | Low | Encode/decode base64. Pure functions, no effects — good showcase of hica's functional style |

### Networking & Web

| Library | Status | Complexity | Notes |
|---------|--------|------------|-------|
| **url** | **—** | Low | Parse/build URLs. Functions: `parse_url`, `url_host`, `url_path`, `url_query`, `encode_uri`, `decode_uri`. Pure string operations |
| **jwt** | **—** | Medium | JSON Web Token encode/decode. `jwt_encode(payload, secret) : string`, `jwt_decode(token, secret) : result<map, string>`. HS256 signing via HMAC-SHA256 (C FFI). Depends on `json` library. `pyjwt` is #44 on PyPI (560M/month) — signals importance when building auth tooling or web services |

### CLI & Terminal

| Library | Status | Complexity | Notes |
|---------|--------|------------|-------|
| **term-color** | **done** | Low | ANSI terminal colors via `import "std/term"`. Functions: `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `white`, `bold`, `dim`, `italic`, `underline`, `strikethrough`, `bright_*` variants. Bundled in binary — no fetch needed. Extracted to `~/.hica/stdlib/term.kk` on first use. First module in the new `std/` stdlib system |
| **table** | **—** | Low | Terminal table formatter. `table_row(cols)`, `table_render(rows) : string`. Aligned columns, optional headers and borders. Pure hica (pad + join). Rich terminal output is a category: `rich` (#47, 546M), `tqdm` (#70, 441M), `colorama` (#78, 413M) all in Python top 80 |
| **prompt** | **—** | Medium | Interactive CLI prompts: `confirm("Continue?")`, `select(choices)`, `prompt("Name:")`. Inspired by `dialoguer` crate. Needs `console` effect |
| **progress** | **—** | Medium | Progress bars and spinners for long-running CLI tasks. Inspired by `indicatif` crate |

### Utilities

| Library | Status | Complexity | Notes |
|---------|--------|------------|-------|
| **uuid** | **—** | Low | UUID v4 generation. Single function: `uuid()` → `string`. Needs `ndet` effect |
| **semver** | **—** | Low | Semantic version parsing and comparison. `parse_semver(s)`, `semver_cmp(a, b)`, `satisfies(version, range)`. hica-semver already exists as a prototype |
| **glob** | **done** | Medium | File glob pattern matching. `glob_match(pattern, path)`, `glob_files(pattern)`. Inspired by `glob` crate. Useful for file-processing CLI tools. `examples/glob-test.hc` already exists |
| **env** (dotenv) | **—** | Low | Read `.env` files and merge into environment. `dotenv_load(path)`, `dotenv_parse(str) : map`. Complements the prelude's `get_env`/`env_or` helpers — those read live env vars, this reads the file. `python-dotenv` is #41 on PyPI (567M/month) |
| **datetime** (v2) | **—** | Medium | Promote `prelude/datetime.hc` to a full library. Add `to_unix`, `from_unix`, timezone support via Koka `std/time`. `python-dateutil` (#13, 1.05B/month) and `pytz` (#55, 489M/month) both in Python top 60 — datetime arithmetic is a genuine pain point |
| **compress** | **—** | High | Gzip/deflate compression. `gzip(data)`, `gunzip(data)`. Inspired by `flate2` crate. Would need `--cclib=z` |

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
- **Prelude functions not polymorphic across call sites** — a generic prelude
  function like `process_messages(state, msgs, receive)` (which is just `fold`)
  gets its type fixed on first use. A second call with different types fails:
  ```hica
  let x = process_messages(0, [Inc, Dec], counter_receive)      // OK: int
  let y = process_messages("even", [1,2,3], (s, n) => ...)      // ERROR: expected int
  ```
  Root cause: Hica lacks let-polymorphism — each function gets one concrete type.
  **Workaround:** use `fold` directly at each call site, or keep all usages
  at the same type.
- **~~`div` effect leakage through non-recursive wrappers~~** — Fixed. Codegen
  now computes transitive `div` names via fixpoint: any function that calls a
  `div`-needing function (directly or transitively) gets `div` annotated.
- **~~`""`.split(`""`) causes infinite loop~~** — Fixed. Codegen now guards
  empty separator: splits into characters instead of calling Koka's `.split("")`
  which loops infinitely.
- **~~`let` inside `if/else` branches generates broken Koka~~** — Fully
  fixed. Simple cases were fixed in v0.11.2; the remaining pattern
  (multiline init on the RHS of a `let`, e.g. `let x = { let a = ...; if ... }`)
  is now fixed by emitting `val x =\n  <indented-block>` when the init spans
  multiple lines. All 5 emit sites patched: `emit-body-wrap-last`, `emit-stmt`
  (Let + VarDecl), and `emit-expr` (Let + VarDecl). 386 codegen tests + 22 JS
  tests green. Helper-function workarounds in user code are no longer needed.
- **~~Parse errors report byte offsets, not line numbers~~** — Fixed. Parser
  now converts byte offsets to `line:col` using the source text. Error messages
  display human-readable positions (e.g. `3:11` instead of `36`).
- **~~Koka errors don't map back to `.hc` source~~** — Fixed. Generated `.kk`
  files now include `// .hc:N` comments before each user-declared function,
  mapping Koka error lines back to original `.hc` source lines.
- **~~Prelude-defined enum constructors not visible in user code~~** — Fixed.
  `load-prelude()` now collects `prog.types` alongside `structs` and `decls`.
  Prelude enums are merged into the type registry and visible for construction
  and pattern matching in user code.
- **~~`split(s, sub)` Perceus use-after-free when `sub` is from a nested match arm~~** —
  Fixed. Codegen now wraps both `s` and `sep` in an IIFE:
  `(fn(hc__s, hc__sep) if hc__sep.is-empty then hc__s.list.map(fn(c) c.string) else hc__s.split(hc__sep))(s, sep)`
  so Perceus ref-counting keeps both alive across the `is-empty` check and the
  `split` call. 2 regression tests added.
- **~~Struct update syntax broken with `var` reassignment~~** — Fixed. Codegen
  now emits an IIFE `(fn(hc__base) S(...))(base)` instead of a block
  `{ val hc__base = base; S(...) }` — the IIFE is valid in both `let` and
  `:=` positions. 3 regression tests added.
- **~~Explicit return type annotation on a side-effectful function causes Koka effect mismatch~~** —
  Fixed. The `effectful-prims` list in codegen now covers all effect-inducing
  calls: `println`, `print`, `eprintln`, `input`, `random`, `random_float`,
  `get_args`, `get_env`, `env_require`, `env_or`, `env_int`, `read_file`,
  `write_file`, `read_lines`, `write_lines`, `exec`, `exec_args`, `now_unix`,
  `now_iso`, `unix_to_iso`, `exit`. When any of these appear in a function body,
  the return type annotation is suppressed and Koka infers the full effect row.
  5 regression tests added.
- **~~Reserved keyword used as parameter name gives misleading error at wrong position~~** —
  Fixed. `parse-typed-params` and `parse-params` now detect keyword tokens via a
  `keyword-name` helper and emit: `'from' is a reserved keyword – choose a
  different parameter name` at the correct position. Added
  `run-parser-program-with-errors` to the parser for testability. 5 regression
  tests added.
- **~~`match` as the body of a lambda argument causes a codegen error~~** — Fixed.
  `Match` is now included in `is-multiline`, so a lambda with a `match` body always
  uses the `fn(x)\n  match x ...` form. Koka's parser sees a valid layout-block body.
  2 regression tests added. Discovered by the CSV library team.
- **~~`+` operator absorbed into `if/else` else branch when expression is parenthesised~~** —
  Fixed. `Binary` codegen now detects when either operand is an `If` node and hoists
  it to a `val hc__lv` / `val hc__rv` binding, so the operator is never on the same
  layout line as the else branch. 2 regression tests added. Discovered by the CSV library team.


---

## Playground & JS Backend

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| JS codegen backend (`codegen-js.kk`) | **done** | High | Emit JavaScript directly from hica AST, bypassing Koka. Enables 100% client-side playground on GitHub Pages |
| JS runtime preamble | **done** | Medium | Minimal JS implementations of hica prelude (`println`, `show`, list ops, maybe/result). Bundled inline in output |
| CLI `--target=js` flag | **done** | Low | Route `hica build --target=js foo.hc` to `emit-js-program` instead of `emit-program` |
| Playground frontend | **done** | Medium | CodeMirror 6 + hica syntax highlighting + Web Worker execution + virtual console |
| Share via URL hash | **done** | Low | `lz-string` compress editor state into URL fragment |
| Playground deployment | **done** | Low | Static files in `docs/playground/`; served by GitHub Pages |

---

## What We Defer

These are explicitly **not** in scope near-term:

- **Row polymorphism / effect inference** — Koka handles this
- **Generics / let-polymorphism** — add later when needed
- **Sets** — Koka has no built-in set; use maps
- **Interfaces / traits** — Koka's effects cover many of the same use cases
