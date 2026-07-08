# Compile-Time Security Boundaries in hica

**Type-driven injection prevention via opaque types and validated strings**

## Executive Summary

hica now enforces a class of injection vulnerabilities at **compile time** through three
cooperating features: opaque struct types (P1), module-private constructors (P2), and a
standard `Trusted` vocabulary (P5). Together they make it impossible to pass an
unvalidated string where a validated one is required as a guarantee from the type checker. Code that violates the contract does not compile.

## 1. Problem Statement

### The root cause of injection attacks

Injection vulnerabilities (SQL injection, shell injection, template injection, log
injection, header injection) share a single root cause: **a string from an untrusted
source is used in a position that requires a trusted one**, and the runtime cannot tell
the difference.

At the language level, the common failure looks like this:

```python
# Python — any string can be passed here
def run_query(db, user_id):
    db.execute("SELECT * FROM users WHERE id = " + user_id)
```

The type of `user_id` is `str`. The type of the SQL template is also `str`. There is no
type-level distinction between "a validated integer string" and `"1 OR 1=1"`. The
programmer relies on discipline and testing; neither is reliably enforced.

### Why run-time defences are insufficient

Prepared statements and parameterised queries solve this problem for SQL at the library
level but only if the library is used correctly, every time, by every author. The same
pattern recurs in:

- Shell command construction (`subprocess`, `exec`)
- HTML template rendering (XSS)
- HTTP header composition (header injection)
- Log formatting (log4shell-style injections)
- Serialisation formats (YAML bomb, XML entity expansion)

Each domain requires a separate convention. None are enforced by the type system in
dynamically typed languages, and even statically typed languages like Java and Go use
`String` uniformly, providing no mechanised distinction.

## 2. hica's Type-Level Approach

hica addresses this at the **type system** and **module system** level, making the
distinction between trusted and untrusted strings a fact the compiler knows and enforces.

The mechanism is the **opaque type**: a struct whose constructor is visible only within
its defining module. External modules can hold values of the type and pass them around,
but they cannot create one. They must go through the module's public smart constructor,
which is the single, auditable point where raw data becomes verified data.

This transforms a runtime convention into a compile-time guarantee.

## 3. Feature P1 — Opaque Structs (`opaque struct`)

### Syntax

```hica
opaque struct Token { data: string }
```

The keyword `opaque` hides both the type name and the constructor from all other modules.
Only the defining module can write `Token { data: ... }`.

### Enforced invariant

```hica
// auth.hc — the defining module

opaque struct SessionToken { data: string }

pub fun create_token(user_id: int, secret: string) : SessionToken {
  let payload = show(user_id) + ":" + hmac(secret, show(user_id))
  SessionToken { data: payload }         // allowed: same module
}

pub fun token_value(t: SessionToken) : string => t.data
```

From any other module:

```hica
import "auth"

fun handler(raw_header: string) {
  // This fails to compile:
  let forged = SessionToken { data: raw_header }
  //           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //   error: cannot construct opaque struct 'SessionToken'
  //          — use its module's constructor function

  // This is the only valid path:
  let t = create_token(42, env_secret)
  use_token(t)
}
```

The compiler error appears **before any code runs**. There is no test to write and no
runtime check to bypass.

### Koka codegen

hica compiles `opaque struct` to Koka's `abstract struct`:

```koka
abstract struct sessiontoken
  data : string
```

Koka's `abstract` modifier enforces constructor privacy at the Koka type-checker level as
a second line of defence. Even if hica's checker were bypassed, the downstream Koka
compilation step would independently reject foreign construction.

## 4. Feature P2 — Module-Private Constructors (`pub struct … priv`)

### Syntax

```hica
pub struct SqlParam priv { data: string }
```

`pub struct … priv` separates two independent concerns:

| Concern | P1 `opaque struct` | P2 `pub struct … priv` |
|---|---|---|
| Type name usable in external signatures | ✗ | ✓ |
| Constructor accessible outside module | ✗ | ✗ |

P2 is used when callers need to **name the type** in their own function signatures
(e.g., as a parameter type or in a return type annotation) without being able to forge
values of that type.

### SQL injection prevention — worked example

```hica
// sql.hc

pub struct SqlParam priv { data: string }

// Smart constructor — the only way to create a SqlParam
pub fun param(s: string) : SqlParam => SqlParam { data: s }

// Unwrap when needed inside the library
pub fun param_value(p: SqlParam) : string => p.data

// The query function requires SqlParam, not plain string
pub fun query(conn: Conn, sql: string, args: list<SqlParam>) : result<Rows, string> {
  // passes params to the prepared-statement layer
  execute_prepared(conn, sql, map(args, param_value))
}
```

Calling code:

```hica
import "sql"

fun find_user(conn: Conn, user_id: string, username: string) {
  // Must go through param() — no raw string accepted
  let result = query(conn,
    "SELECT * FROM users WHERE id = ? AND name = ?",
    [param(user_id), param(username)])

  // This does NOT compile:
  // query(conn, "SELECT ...", [SqlParam { data: "' OR 1=1--" }])
  //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //   error: cannot construct opaque struct 'SqlParam'
}
```

Because `query` accepts `list<SqlParam>` and not `list<string>`, it is **structurally
impossible** for a raw, unparameterised string to reach the SQL engine through this API.
The type checker enforces the parameterisation discipline — not documentation, not code
review, not test coverage.

## 5. Feature P5 — Standard Trust Vocabulary (`import "std/trusted"`)

### Motivation

P1 and P2 are module-level tools: each library defines its own opaque type. P5 provides
a **shared vocabulary** so that ecosystem libraries can agree on what "validated" means
without each inventing their own type.

When multiple libraries use the same `Trusted` type, a string validated by one library
can be safely passed to another — and the compiler verifies that the chain is unbroken.

### The `Trusted` type

```hica
import "std/trusted"
```

`Trusted` is itself defined with `pub struct Trusted priv` — the constructor is locked to
`std/trusted`, and the only way to obtain a `Trusted` value is through a validator or the
explicit `trust()` escape hatch.

### Trust boundaries

```
external source
    │  raw string (untrusted)
    ▼
validate_*() / trust()    ◄── the trust boundary
    │  maybe<Trusted>
    ▼
match { None => reject, Some(t) => proceed }
    │  Trusted (verified)
    ▼
security-sensitive function(t: Trusted)
```

The type system makes this boundary **physical**: the left side of the boundary is
`string`, the right side is `Trusted`. The compiler enforces that you cross it
deliberately.

### Available validators

| Function | Accepts | Returns |
|---|---|---|
| `trust(s)` | Any string — explicit "I vouch for this" | `Trusted` |
| `validate_nonempty(s)` | Non-empty string | `maybe<Trusted>` |
| `validate_maxlen(s, n)` | String with `len ≤ n` | `maybe<Trusted>` |
| `validate_alnum(s)` | All alphanumeric characters | `maybe<Trusted>` |
| `validate_with(s, pred)` | Custom predicate | `maybe<Trusted>` |
| `validate_and(a, b)` | Both validators pass | `maybe<Trusted>` |
| `trusted_or(t, fallback)` | Fallback on None | `Trusted` |

### Worked example — user input handling

```hica
import "std/trusted"

// Only Trusted values may be logged in a structured audit trail.
pub fun audit_log(event: string, actor: Trusted, resource: Trusted) {
  println("[AUDIT] " + event + " actor=" + trusted_value(actor)
          + " resource=" + trusted_value(resource))
}

fun handle_request(raw_actor: string, raw_resource: string) {
  // validate_and: non-empty AND alphanumeric
  let actor    = validate_and(validate_nonempty(raw_actor),
                              validate_alnum(raw_actor))
  let resource = validate_and(validate_nonempty(raw_resource),
                              validate_maxlen(raw_resource, 128))

  match (actor, resource) {
    (Some(a), Some(r)) => audit_log("access", a, r),
    _                  => println("rejected: invalid input")
  }
}
```

A log injection attack requires inserting newlines or control characters into the `actor`
or `resource` fields. Because `validate_alnum` rejects anything that is not `[A-Za-z0-9]`
and the `audit_log` function only accepts `Trusted` — not `string` — the injection surface
does not exist at the type level.

### Composing with domain-specific opaque types

P5's `Trusted` composes naturally with P1/P2 types. A library can accept `Trusted` for
its smart constructor, providing a chain of verified types:

```hica
import "std/trusted"
import "email"        // defines: pub struct Email priv { ... }

// email.hc
pub fun parse_email(t: Trusted) : maybe<Email> {
  let s = trusted_value(t)
  if contains(s, "@") { Some(Email { address: s }) }
  else { None }
}
```

```hica
// user code
import "std/trusted"
import "email"

fun register(raw_email: string) {
  let validated = validate_maxlen(raw_email, 254)
    |> and_then((t) => parse_email(t))

  match validated {
    None      => println("invalid email"),
    Some(addr) => create_account(addr)
  }
}
```

The raw string passes through two independent gates: `std/trusted` (length check) and
`email` (structural check). Both must pass for an `Email` value to exist. Neither gate
can be bypassed through the type system.

## 6. Threat Model and Boundaries

### What these features prevent (guaranteed at compile time)

| Attack class | Mechanism | Status |
|---|---|---|
| SQL injection via raw string concatenation | `query()` requires `list<SqlParam>`, not `list<string>` | ✓ Prevented |
| Session token forgery | `SessionToken` constructor is private | ✓ Prevented |
| Log injection via unvalidated user input | `audit_log` requires `Trusted` | ✓ Prevented |
| Bypass of validation by direct struct construction | Compiler rejects foreign `StructLit` | ✓ Prevented |
| Accidental use of wrong string variable | Type mismatch at compile time | ✓ Prevented |

### What these features do NOT prevent

| Scenario | Why | Mitigation |
|---|---|---|
| A `trust()` call on unvalidated data | `trust()` is an explicit escape hatch — it marks the boundary but does not validate | Code review; restrict `trust()` through custom lint rules |
| Logic errors inside the smart constructor | The module author controls what the constructor does | Unit-test the constructors; they are the auditable surface |
| Vulnerabilities in the `Trusted` or opaque type implementation | The module itself is trusted code | Peer-review the defining module; it is small and isolated |
| Type confusion within the same module | Opaque types are open within their own module | Standard intra-module review |
| Side channels (timing, resource exhaustion) | Out of scope for type-level analysis | Separate mitigations required |

### Design properties

**Unforgeable by construction.** A value of type `SqlParam` or `Trusted` cannot be
created without going through the appropriate constructor. There is no cast, unsafe
coercion, or reflection mechanism in hica that bypasses this.

**Zero runtime cost.** The opaque types are erased at the Koka level — they compile to
the same representation as a plain struct. There is no runtime check, no boxing, and no
allocation overhead.

**Dual enforcement.** hica enforces the constraint at its own checker level (with
user-friendly error messages pinpointing the source location). The downstream Koka
compiler independently enforces `abstract struct` semantics. Two independent
type-checkers must both be subverted to permit a violation.

**Minimal trusted computing base.** The security-critical code is the smart constructor
— typically 1–5 lines. The rest of the codebase is mechanically prevented from
constructing the type. The audit surface is bounded and explicit.

## 7. Comparison to Other Approaches

| Approach | Language | Enforced at | Limitations |
|---|---|---|---|
| Prepared statements | SQL library | Runtime, by library | Requires correct API use every time |
| `taint` analysis (Perl `use Taint`) | Perl | Runtime | Dynamic; misses paths; significant overhead |
| String wrapper types (manual newtype) | Java, Go | Compile time (by convention) | No enforcement — any code can construct the wrapper |
| `newtype` in Haskell | Haskell | Compile time | Constructor is private only if not exported; must be explicit |
| Rust `newtype` pattern | Rust | Compile time | Constructor is `pub` by default; privacy requires module discipline |
| **hica `opaque struct`** | **hica** | **Compile time** | **Constructor locked to module by language keyword; no opt-out** |

The key distinction is that hica's `opaque struct` makes the constructor private by
declaration, with no ability to "opt out" from outside the module. In Java, you can
always call `new SqlParam("injection")` if the constructor is `public`. In hica, there is
no equivalent mechanism once `opaque` or `priv` is used.

## 8. Implementation Status

| Feature | Status | Koka codegen |
|---|---|---|
| `opaque struct Foo {}` | ✓ Shipped | `abstract struct foo` |
| `pub struct Foo priv {}` | ✓ Shipped | `abstract struct foo` |
| `import "std/trusted"` | ✓ Shipped | n/a (hica stdlib) |
| Checker enforcement (user code) | ✓ Active | Dual: hica + Koka |
| Effect definitions (`effect` / `handle`) | Planned (P3) | — |
| Effect-row polymorphic function types | Planned (P4) | — |

## 9. Auditing Checklist for Security Reviewers

When reviewing a hica codebase that uses these features, concentrate on:

1. **Every module that defines an opaque struct.** Read all functions in that module.
   The module is the security boundary — everything inside it can construct the type.

2. **Every use of `trust()` from `std/trusted`.** `trust()` is the explicit escape hatch.
   Each call is a decision that "this string is already safe." Justify each one.

3. **The smart constructors themselves.** Verify that the validation logic is correct and
   complete for the domain (e.g., does `param()` handle all SQL metacharacters?
   Does `parse_email()` correctly reject all invalid addresses?).

4. **`trusted_or()` calls.** Verify that the fallback string is itself safe — it bypasses
   validation.

5. **Any `extern` import that returns a raw `string`.** Extern functions cross the
   FFI boundary. The result is always `string`, never `Trusted`. Wrap at the call site.

The good news: because the compiler enforces the boundary, the security reviewer's job is
narrowly scoped. They need to audit the smart constructors (small, isolated), not the
entire call graph.

---

## 10. Quick Reference

```hica
// P1: completely private — other modules cannot name the type or construct it
opaque struct Token { data: string }

// P2: public type name, private constructor
pub struct SqlParam priv { data: string }

// Smart constructor (in the defining module)
pub fun param(s: string) : SqlParam => SqlParam { data: s }

// P5: shared trust vocabulary
import "std/trusted"

let raw : string = get_input()             // untrusted
let validated : maybe<Trusted> =
  validate_and(validate_nonempty(raw),
               validate_maxlen(raw, 256))  // validated (or None)
let safe : Trusted =
  trusted_or(validated, "")               // safe to use

// Functions that require validated data take Trusted, not string
pub fun write_audit(msg: Trusted) { ... }
```

The compiler enforces that `write_audit` can never receive a raw `string`.
No test needed. No runtime check. The guarantee is structural.
