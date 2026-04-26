**What I get for free by targeting Koka:**
- Memory management (Perceus reference counting)
- Backend codegen (C, JS, WASM — all handled by Koka)
- Standard library (strings, lists, I/O, concurrency)
- Optimisation passes (tail-call, FBIP in-place reuse)
- Linker integration, platform support, ABI concerns
- Effect runtime (handlers, resumptions)

**What I still need to build:**
- Lexer and parser (done-ish)
- Type checker / inference
- Desugaring (Hica syntax → Koka idioms)
- Diagnostics and error reporting
- The emitter (Hica AST → valid `.kk` source)

**The tradeoff:** this language is constrained by what Koka can express. But given that Hica's design pillars — algebraic effects, Perceus memory, expression-oriented, strong inference — are exactly what Koka already provides, that constraint costs me almost nothing. Hica is essentially a syntax skin and a type-checking layer on top of Koka's full runtime.

The practical route for me going forward: get the parser and emitter solid, write me some real `.hc` programs, and iterate on the type checker in parallell. 