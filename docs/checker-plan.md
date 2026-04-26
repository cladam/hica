# Type Checker Plan

Incremental plan for `semantics/checker.kk`. Each phase is self-contained
and testable — wire it in, run the examples, move on.

## Context

Hica transpiles to **Koka**, so Koka's own type checker is the final
authority. Hica's checker exists to:

1. **Emit type annotations** so Koka can resolve overloaded operators
   (codegen-limitations.md #2, #4)
2. **Name resolution** — distinguish user declarations from Koka builtins
   (codegen-limitations.md #1)
3. **Early error reporting** — catch mistakes before they become cryptic
   Koka errors

The type system is **Hindley-Milner** with fresh type variables and
unification. Row polymorphism for effects is *not* needed yet — Koka
handles effect inference on its side.

---

## Phase 0: Infrastructure

Build the plumbing that every later phase depends on.

### 0a. Annotated AST

The current `node` has no place to store inferred types. Two options:

- **Option A (recommended):** Add an optional `hica-type` field to `node`:
  ```
  pub struct node
    span  : span
    expr  : expr
    typ   : maybe<hica-type>   // inferred type, Nothing before checking
  ```
  This requires updating every `Node(...)` construction site (parser,
  fold, tests) to add `Nothing` as the third field.

- **Option B:** Build a separate `Map<span, hica-type>` side-table.
  Less invasive but harder to thread through codegen.

**Recommendation:** Option A. The constructor churn is mechanical and
one-time. It makes codegen trivial — just read `n.typ`.

### 0b. Type variables & substitution

```
// Fresh type variable generation
effect fresh
  fun fresh-tvar() : hica-type   // returns TVar("t0"), TVar("t1"), ...

// Substitution: mapping from type-variable names to types
alias subst = list<(string, hica-type)>

fun apply-subst( s : subst, t : hica-type ) : hica-type
fun compose-subst( s1 : subst, s2 : subst ) : subst
```

Use a Koka effect for fresh variable generation (counter-based). Use
the `diag` effect from `diagnostics/diagnostics.kk` for type errors.

### 0c. Unification

```
fun unify( t1 : hica-type, t2 : hica-type, sp : span ) : <diag,fresh,...> subst
```

Standard HM unification:
- `TVar(a)` unifies with anything (occurs check)
- Two concrete types unify if they match structurally
- Mismatch → `emit-error(sp, "expected T1, got T2")`

### 0d. Type environment

```
alias type-env = list<(string, hica-type)>

fun lookup( env : type-env, name : string, sp : span ) : <diag> hica-type
fun extend( env : type-env, name : string, t : hica-type ) : type-env
```

---

## Phase 1: Literals, Variables, Let, Blocks

The simplest expressions — no polymorphism needed yet.

### Inference rules

| Expression       | Inferred type                                      |
|------------------|----------------------------------------------------|
| `LitInt(i)`      | `TInt`                                             |
| `LitBool(b)`     | `TBool`                                            |
| `LitString(s)`   | `TString`                                          |
| `Var(name)`      | `lookup(env, name)`                                |
| `Let(n, ann, i, b)` | infer `i` → τ, unify with annotation if present, extend env with `n : τ`, infer `b` |
| `Block(stmts)`   | type of the last statement (or `TUnit` if empty)   |

### Test checkpoint

After this phase, `hica check examples/arrow.hc` should infer that
`double` returns `TInt` and `main` returns `TInt`.

---

## Phase 2: Functions & Calls

### Functions

`Fun(params, body)`:
- Assign a fresh `TVar` to each param
- Extend env, infer `body` → τ_body
- Result type: `TFun([τ_p1, ..., τ_pN], τ_body)`

### Calls

`Call(callee, args)`:
- Infer `callee` → must unify with `TFun(param_types, ret_type)`
- Infer each arg, unify with corresponding param type
- Result type: `ret_type`

### Top-level declarations

`fun-decl` is essentially `Let(name, Nothing, Fun(params, body), <rest>)`.
Process all declarations in order, building up the environment. (No mutual
recursion for now — that would need a fixpoint or two-pass approach.)

### Test checkpoint

`hica check examples/higher-order.hc` — infers `square : (int) -> int`,
`twice : (int) -> int`, `main : () -> int`.

---

## Phase 3: Operators

### Binary operators

| Operator       | Constraint          | Result  |
|----------------|---------------------|---------|
| `+`, `-`, `*`, `/` | both operands `TInt` | `TInt`  |
| `==`, `!=`     | both operands same type | `TBool` |
| `<`, `>`, `<=`, `>=` | both operands `TInt` | `TBool` |
| `&&`, `\|\|`   | both operands `TBool` | `TBool` |

### Unary operators

| Operator | Constraint      | Result  |
|----------|-----------------|---------|
| `Neg`    | operand `TInt`  | `TInt`  |
| `Not`    | operand `TBool` | `TBool` |

### Why this matters

This is the **key unlock** for codegen-limitations.md #2. Once the checker
knows that `a` and `b` in `fun add(a, b) => a + b` are `TInt`, codegen
can emit `fun hc_add(a : int, b : int) : int`.

### Test checkpoint

`hica check examples/math.hc` — `double` and `square` params inferred as
`int`, return types as `int`.

---

## Phase 4: Control Flow

### If expressions

`If(cond, then, else)`:
- `cond` must be `TBool`
- `then` and `else` must unify to the same type → that's the result

### Match expressions

`Match(scrutinee, arms)`:
- Infer `scrutinee` → τ_scrut
- Each arm pattern constrains τ_scrut (literal patterns → concrete type)
- Each arm body must unify to the same type → result type

### Test checkpoint

`hica check examples/fizzbuzz.hc` — `fizzbuzz` returns `TString`,
condition `n == 15` checks out, all branches are `TString`.

---

## Phase 5: Wire into Pipeline

### 5a. Update `build()` in `main.kk`

Insert `check` between `parse` and `emit`:

```
fun build( file : string )
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens)
  val typed  = check-program(prog)        // ← NEW
  val koka   = emit-program(typed)
  ...
```

### 5b. Update codegen to emit type annotations

When `n.typ` is `Just(t)`, emit the Koka type annotation:

- Function params: `fun hc_add(a : int, b : int) : int`
- Let bindings: `val hc_x : int = ...`

This directly fixes codegen-limitations.md #2 and #4.

### 5c. Update `hica check` to report inferred types

Print a summary: `check: hello.hc — ok (2 declarations, 0 errors)`
and optionally `--verbose` to dump inferred signatures.

---

## Phase 6: Name Resolution (Bonus)

Separate pass (or integrated into the checker) that builds a symbol table
of all user-declared names. This lets codegen distinguish:

- **Declared in Hica** → prefix with `hc_`
- **Not declared** → pass through to Koka (it's a stdlib call)

This fixes the remaining tension in codegen-limitations.md #1 where
`abs(5)` should call Koka's `abs` if the user didn't define one.

### Implementation

```
alias declared-names = list<string>

fun collect-declarations( p : program ) : declared-names
  p.decls.map(fn(d) d.name)

fun should-marshal( name : string, declared : declared-names ) : bool
  declared.any(fn(d) d == name)
```

Then pass `declared-names` into codegen so `marshal-name` can check it.

---

## Suggested Order of Work

```
Phase 0  →  infrastructure (annotated AST, subst, unify, env)
Phase 1  →  literals, vars, let, blocks
Phase 3  →  operators  (do this early — biggest practical payoff)
Phase 2  →  functions & calls
Phase 4  →  control flow (if, match)
Phase 5  →  wire into pipeline + codegen annotations
Phase 6  →  name resolution
```

Note: Phase 3 (operators) is moved before Phase 2 because it unblocks the
most pressing codegen limitation and can be tested with simple examples
like `arrow.hc` and `math.hc` that don't use higher-order functions.

---

## What We Defer

These are explicitly **not** in scope for the first type checker:

- **Row polymorphism / effect inference** — Koka handles this
- **Generics / let-polymorphism** — add later when needed
- **Mutual recursion** — requires fixpoint; single-pass ordering is fine for now
- **Type annotations in syntax** — the parser doesn't parse `: type` yet;
  add when the checker is solid enough to benefit from user-provided hints
- **Algebraic data types / structs** — not in the AST yet
