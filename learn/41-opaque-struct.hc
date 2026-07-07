// ============================================================
// Lesson 41: Opaque Structs — Type-Safe Boundaries
// ============================================================
//
// A regular struct lets anyone construct a value directly:
//
//   struct SqlParam { data: string }
//   SqlParam { data: "' OR 1=1" }   // nothing stops this
//
// An opaque struct locks the constructor to the defining module.
// Callers must go through a public constructor function that can
// validate, sanitise, or otherwise guard the value.
//
// ── Syntax 1: opaque struct ──────────────────────────────────
//
// Both the type name AND the constructor are private to this
// module. Other modules cannot name the type in annotations
// (they see it only through public function signatures).
//
//   opaque struct Token { data: string }
//
// ── Syntax 2: pub struct … priv ──────────────────────────────
//
// The type name is public — callers can write it in signatures
// and pattern-match on values — but the constructor is still
// private.
//
//   pub struct SqlParam priv { data: string }
//
// ── Smart constructors ────────────────────────────────────────
//
// Pair the opaque struct with a public function that is the
// only way to obtain a value. Any invariant lives there.
//
//   pub fun param(s: string) : SqlParam => SqlParam { data: s }
//
// Attempting to construct an opaque struct from another module:
//
//   SqlParam { data: "' OR 1=1" }   // ERROR at compile time
//   // error: cannot construct opaque struct 'SqlParam'
//   //        — use its module's constructor function
//
// ── Rule of thumb ────────────────────────────────────────────
//
//   opaque struct   — when the type itself is an implementation
//                     detail (e.g. an internal handle)
//   pub struct priv — when callers name the type in their own
//                     signatures (e.g. function parameters),
//                     but cannot forge values of the type
//
// ============================================================

// --- Example 1: session token (opaque) ---

opaque struct Token { data: string }

pub fun make_token(s: string) : Token => Token { data: s }
pub fun token_str(t: Token) : string => t.data

// --- Example 2: validated email (pub priv) ---
// The type name is public so other functions can use Email in
// their own signatures.

pub struct Email priv { address: string }

pub fun parse_email(s: string) : maybe<Email> {
  if contains(s, "@") { Some(Email { address: s }) }
  else { None }
}

pub fun email_address(e: Email) : string => e.address

// --- Example 3: SqlParam (the motivating use case) ---

pub struct SqlParam priv { data: string }

pub fun param(s: string) : SqlParam => SqlParam { data: s }
pub fun param_value(p: SqlParam) : string => p.data

fun fake_query(sql: string, args: list<SqlParam>) : string {
  let vals = map(args, (a) => param_value(a))
  sql + " [" + join(vals, ", ") + "]"
}

fun main() {
  // --- Token ---
  let tok = make_token("session-xyz")
  println("token: " + token_str(tok))

  // --- Email ---
  let good = parse_email("user@example.com")
  let bad  = parse_email("not-an-email")
  match good {
    Some(e) => println("email ok: " + email_address(e)),
    None    => println("email rejected")
  }
  match bad {
    Some(_) => println("email ok"),
    None    => println("email rejected: no @ found")
  }

  // --- SqlParam ---
  let result = fake_query(
    "SELECT * FROM users WHERE id = ? AND name = ?",
    [param("42"), param("alice")]
  )
  println(result)

  // The compiler prevents forgery:
  // Uncommenting the next line would produce a compile-time error:
  //   SqlParam { data: "' OR 1=1" }
}
