Updated todo list

Here's the analysis — just as a response, no file needed:

---

## Hica improvements needed for compile-time security boundaries

### 1. Opaque / newtype wrappers

**What's missing:** Hica structs are transparent — any code can construct `SqlParam { value: "' OR 1=1" }` directly. There's no way to make a type constructable only through a specific function.

**What's needed:** A `newtype` or `opaque` keyword that hides the constructor:
```hica
opaque struct SqlParam { value: string }

// Only this module can build one:
pub fun param(s: string) : SqlParam => SqlParam { value: sanitize(s) }
```

Callers get `SqlParam` values only by going through `param()`. The raw constructor is invisible outside the defining module. This is the single most impactful change for this use case.

---

### 2. Module-private constructors

Closely related but lighter: allow `pub struct` with `priv` constructors. The type is visible (so it can appear in signatures) but only the defining module can construct it.

```hica
pub struct SqlParam priv { value: string }
```

---

### 3. User-facing algebraic effect definitions

**What's missing:** Effect definitions and handlers exist in Koka but are not exposed in Hica syntax. Users can't write:
```hica
effect Db {
  fun query(sql: TrustedSql, params: list<SqlParam>) : QueryResult
}
```

**What's needed:** `effect` and `handle` keywords surfaced in Hica so library authors can define capability interfaces that the type checker enforces at call sites.

---

### 4. Effect-polymorphic function types

The `with_sqlite` callback is currently typed `(Db) -> ()` which silently accepts any effect. To express "this callback may only use the `Db` effect" you need effect-row polymorphism in Hica's function type syntax:

```hica
pub fun with_sqlite(path: string, f: (Db) -> <db> ()) : result<bool, string>
```

Without this, the sandbox model from the conversation (intercepting unauthorized writes) can't be expressed.

---

### 5. `trusted` / `validate` standard vocabulary

A smaller, convention-level improvement: a standard library pattern for marking strings as validated, so ecosystem libraries agree on what "crossed the trust boundary" means. Not a language change — a prelude addition.

---

### Priority order

For the sqlite use case specifically:

| Priority | Feature | Unlocks |
|----------|---------|---------|
| 1 | Opaque/newtype structs | Prevents `SqlParam` from being constructed unsafely |
| 2 | Module-private constructors | Same, lighter syntax |
| 3 | `effect` / `handle` in Hica | Full sandbox model |
| 4 | Effect-row in function types | Typed capability interfaces |

Items 1 or 2 are immediately actionable and high-value. Items 3 and 4 are the full Koka security model — significant language surface to add.