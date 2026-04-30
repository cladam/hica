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
- The emitter (hica AST → valid `.kk` source, with type annotations)
- Name resolution (only user-declared names get `hc_` prefix)
- Module keyword clash fix (`match.hc` → `hc-match.kk`)

**What I still need to build:** see [backlog.md](backlog.md)

**The tradeoff:** this language is constrained by what Koka can express. But given that Hica's design pillars — algebraic effects, Perceus memory, expression-oriented, strong inference — are exactly what Koka already provides, that constraint costs me almost nothing. Hica is essentially a syntax skin and a type-checking layer on top of Koka's full runtime.

The practical route for me going forward: get the parser and emitter solid, write me some real `.hc` programs, and iterate on the type checker in parallell. 

---

**Gaps noticed while writing the kids tutorial (2026-04-29):**

- **Loops** — no `for` or `while` yet. Limits what people can build (counting,
  repetition, games). Could start with a simple `for i in range(n) { ... }`.
- **Lists / collections** — no list literals or operations. Even a basic
  `[1, 2, 3]` would unlock many beginner exercises.

See [backlog.md](backlog.md) for the full feature backlog.