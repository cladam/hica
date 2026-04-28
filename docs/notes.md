**What I get for free by targeting Koka:**
- Memory management (Perceus reference counting)
- Backend codegen (C, JS, WASM — all handled by Koka)
- Standard library (strings, lists, I/O, concurrency)
- Optimisation passes (tail-call, FBIP in-place reuse)
- Linker integration, platform support, ABI concerns
- Effect runtime (handlers, resumptions)

**What's done:**
- Lexer and parser (with `else if`, unary operators, match, lambdas)
- Type checker / inference (Hindley-Milner, all expr types, wired into build)
- Diagnostics and error reporting (`diag` effect, `collect-diagnostics`)
- The emitter (Hica AST → valid `.kk` source, with type annotations)
- Name resolution (only user-declared names get `hc_` prefix)
- Module keyword clash fix (`match.hc` → `hc-match.kk`)

**What I still need to build:**
- String matching in `match` (only int literals and wildcards today)
- String interpolation / concatenation
- Loops (`for`, `while`, `repeat`)
- Lists / collections (literals, `map`, `filter`, etc.)
- Tuples (literals, destructuring)
- Structs and algebraic types (`struct`, `enum`)
- Multi-file modules / imports
- Desugaring pass (Hica syntax → Koka idioms, beyond what codegen does)

**The tradeoff:** this language is constrained by what Koka can express. But given that Hica's design pillars — algebraic effects, Perceus memory, expression-oriented, strong inference — are exactly what Koka already provides, that constraint costs me almost nothing. Hica is essentially a syntax skin and a type-checking layer on top of Koka's full runtime.

The practical route for me going forward: get the parser and emitter solid, write me some real `.hc` programs, and iterate on the type checker in parallell. 

---

**Gaps noticed while writing the kids tutorial (2026-04-26):**

- ~~**`else if` chains**~~ — **fixed.** Parser handles `else if` natively.
- ~~**Unary negation**~~ — **fixed.** `-x` works (lexer, parser, checker, codegen).
- **String matching in `match`** — `match` currently works with integer
  literals only. String patterns like `"Dog" => ...` would make the match
  section much more kid-friendly.
- **String interpolation / concatenation** — no way to build strings from
  parts (e.g. `"Hello, " + name` or `"score: {n}"`).
- **Loops** — no `for` or `while` yet. Limits what kids can build (counting,
  repetition, games). Could start with a simple `repeat(n) { ... }` or
  `for i in range(n) { ... }`.
- **Lists / collections** — no list literals or operations. Even a basic
  `[1, 2, 3]` would unlock many beginner exercises.

---

**Feature backlog — how Lisette does it (2026-04-26):**

These are features Hica is currently missing. For each one, we note what
Lisette does (since it's our main syntax inspiration) and what a Hica version
could look like, given that we target Koka (not Go).

### Loops

Lisette has `for`, `while`, and `loop` (infinite, expression-valued via
`break n`). Range syntax: `for i in 0..5 { }` and `for i in 0..=5 { }`.
`for` iterates slices, maps, strings, channels. `while let` does
pattern-matching loops. `loop` is the only loop that's an expression.

*Hica angle:* Koka has `for`, `while`, `repeat`, and `foreach` in its
stdlib. A reasonable first step:
```
for i in 0..5 { println(i) }        // range loop
while condition { ... }              // condition loop
```
Since Hica is expression-oriented, all loops could return the last value
(or unit). Koka's `list(1,10,fn(i) i*i)` pattern is also worth exposing.

### Lists / Slices

Lisette uses `Slice<T>` (Go's `[]T`). Literal: `[1, 2, 3]`. Methods:
`length`, `get`, `append`, `extend`, `map`, `filter`, `fold`, `find`,
`any`, `all`, `contains`, `enumerate`, `join`. Slice patterns in match:
`[first, ..rest] =>`.

*Hica angle:* Koka has `list<a>` with `map`, `filter`, `foldl`, etc.
Hica could emit Koka list literals: `[1, 2, 3]` → `[1, 2, 3]` (same
syntax!). Slice patterns would need parser work.

### Tuples

Lisette supports 2–5 element tuples: `(42, "hello")`. Access via `.0`,
`.1`. Destructuring: `let (a, b) = pair`. Tuple patterns in match.
Tuple structs: `struct Color(int, int, int)`.

*Hica angle:* Koka has tuples natively. `(1, "hi")` just works. This is
likely easy to add — parser + emitter only, no new type system work.

### Maps / Dictionaries

Lisette has `Map<K, V>` (Go's `map[K]V`). Created via
`Map.from([("a", 1)])` or `Map.new<K,V>()`. Methods: `get` (→ Option),
`delete`, `length`, `is_empty`, `clone`. Iteration: `for (k, v) in m {}`.

*Hica angle:* Koka doesn't have a built-in map type in core, but
`std/data/linearmap` exists. Lower priority — useful but not essential
for kids or early adopters.

### Sets

Lisette does **not** have a built-in Set type. No `Set<T>` in prelude or
docs. Workaround: `Map<T, bool>`.

*Hica angle:* Same — skip for now. Koka has no built-in set either.

### Structs & Methods (OOP-like)

Lisette uses `struct` + `impl` blocks + `interface` (structural typing).
No classes, no inheritance. Methods have `self` receivers. Enums are
algebraic data types with variants: `enum Shape { Circle { r: f64 }, ... }`.
Visibility: `pub` keyword, private by default.

*Hica angle:* Koka has `struct`, `type` (algebraic), and `fun` (no impl
blocks — methods are just functions). Hica could:
- Phase 1: `struct` with named fields → emit Koka struct
- Phase 2: `enum` with variants → emit Koka `type` (algebraic)
- Phase 3: `impl` blocks → emit Koka functions with the struct as first param
Interfaces can wait — Koka's row-polymorphic effects cover many of the
same use cases.

### Modules / Imports

Lisette: `import "models"` (directory = module). Go stdlib via
`import "go:fmt"`. Namespaced access: `models.User { ... }`. `pub` for
visibility. No circular imports.

*Hica angle:* Koka has `import std/core` etc. Hica could support:
```
import "mymodule"          // → import mymodule
import "go:fmt"            // N/A (we target Koka, not Go)
```
Multi-file compilation is a bigger project — requires tracking which
`.hc` files form a module and emitting multiple `.kk` files.

### File I/O

Lisette has **no native file I/O** — it uses Go stdlib via `import "go:os"`.
`os.ReadFile`, `os.WriteFile`, `os.Open`, etc. Go's `(T, error)` maps to
`Result<T, error>` with `?` propagation.

*Hica angle:* Koka has `std/os/file` and `std/os/path`. Hica could
expose these via a passthrough import or a small prelude. The `?`
operator maps nicely to Koka's effect system (an `exn` effect).
Lower priority — kids tutorial doesn't need file I/O.