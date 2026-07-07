// Opaque structs — type-safe security boundaries
//
// An opaque struct keeps its constructor private to the module that
// defines it. Callers can hold values of the type and pass them around,
// but they cannot create one directly — they must go through the
// module's public smart constructor, which can enforce any invariant.
//
// This file shows both syntaxes and a practical SqlParam example.

// ── Syntax 1: opaque struct ─────────────────────────────────────────
// Both the type name AND the constructor are private to this module.
opaque struct Token { data: string }

// This is the only way to obtain a Token.
// Any sanitisation / validation logic lives here.
pub fun make_token(s: string) : Token => Token { data: s }

// Accessor — exposes the inner string on the module's terms.
pub fun token_value(t: Token) : string => t.data


// ── Syntax 2: pub struct … priv ─────────────────────────────────────
// The type name is public (usable in signatures across modules), but
// the constructor is still private — callers cannot write
//   SqlParam { data: "' OR 1=1" }
// They must call param() instead.
pub struct SqlParam priv { data: string }

// Smart constructor — the single point of trust.
pub fun param(s: string) : SqlParam => SqlParam { data: s }

// Expose the sanitised string when the caller needs it.
pub fun param_value(p: SqlParam) : string => p.data

// A function that accepts only properly-wrapped parameters.
pub fun fake_query(sql: string, args: list<SqlParam>) : string {
  let values = map(args, (a) => param_value(a))
  sql + " [" + join(values, ", ") + "]"
}


fun main() {
  // ── Token example ────────────────────────────────────────────────
  let t = make_token("session-abc123")
  println("token: " + token_value(t))

  // ── SqlParam example ─────────────────────────────────────────────
  let user_id  = param("42")
  let username = param("alice")

  // Safe: values came through param()
  let result = fake_query("SELECT * FROM users WHERE id = ? AND name = ?",
                          [user_id, username])
  println(result)

  // The type system prevents raw construction across module boundaries.
  // Attempting:  SqlParam { data: "' OR 1=1" }
  // from another module would produce a compile-time error:
  //   error: cannot construct opaque struct 'SqlParam'
  //          — use its module's constructor function
}
