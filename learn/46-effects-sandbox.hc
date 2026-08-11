// hica — Effect-row polymorphism as a compile-time sandbox
//
// This lesson shows how a library can restrict what a caller-supplied
// callback is allowed to do — enforced by the type checker at compile time,
// with zero runtime cost. This is the M4 effect-row polymorphism feature
// (see documentation/effects-design.md §4.5 and §13.2 for the full spec).
//
// **The pattern in one sentence:** put an effect row on a callback parameter,
// and hica rejects any argument whose body calls ops outside that row.
//
// Run this file to see it in action:
//   hica run learn/46-effects-sandbox.hc
//
// Then peek at examples/effects/db-sandbox-leak.hc for the negative case —
// hica check catches the leak at compile time.

// -------------------------------------------------------------------------
// 1. Declare a capability
// -------------------------------------------------------------------------
//
// An `effect` names an abstract capability. `Db` here means: "the ability
// to execute SQL." The ops are ordinary function signatures, but instead
// of pointing at a real implementation they defer that choice until a
// handler is installed.

effect Db {
  fun query(sql: string) : int
  fun exec(sql: string)
}

// -------------------------------------------------------------------------
// 2. A library function with an effect-row on its callback
// -------------------------------------------------------------------------
//
// The type `f: () -> <Db> int` reads: "f is a zero-argument function that
// returns int and may use only <Db> and built-in effects (console, div,
// fsys, …)". No other user-defined effect is permitted inside f.
//
// The library installs its own real handler for `Db`, so from f's point of
// view the ops just work. From the caller's point of view they cannot
// reach outside the sandbox.

pub fun with_db(f: () -> <Db> int) : int {
  handle Db {
    // In real code these arms would open a connection, run the SQL, etc.
    // For the tutorial we return a fixed number so main() prints something.
    query(sql) => 42,
    exec(sql) => ()
  } in {
    f()
  }
}

// -------------------------------------------------------------------------
// 3. A compliant callback
// -------------------------------------------------------------------------
//
// list_users is annotated `<Db> int` — it declares that it only uses <Db>.
// It calls `exec` and `query`, both of which are Db ops. Everything checks.

fun list_users() : <Db> int {
  exec("UPDATE stats SET last_scan = now()")
  let n = query("SELECT count(*) FROM users")
  n
}

// -------------------------------------------------------------------------
// 4. What happens if the callback tries to leak?
// -------------------------------------------------------------------------
//
// Look at examples/effects/db-sandbox-leak.hc. It defines a second effect
// `Log` and a callback `leaky_write` that calls Log's `audit` op alongside
// Db ops. When main() passes `leaky_write` to `with_db`, hica errors:
//
//   error: effect row mismatch — callback passed to 'with_db' may use
//     <Log, Db>, not permitted by <Db>
//    41 |   let n = with_db(leaky_write)
//       |                   ^^^^^^^^^^^
//
// This is a **compile-time** error — the offending code never runs. The
// checker walks the callback's body (following refs to top-level decls)
// and compares the effects it uses against the declared row.

fun main() {
  let count = with_db(list_users)
  println("users = " + show(count))
}

// -------------------------------------------------------------------------
// Testable in-file examples — the same list_users function works with a
// handler that returns different data (useful for tests).
// -------------------------------------------------------------------------

test "with_db returns the query result" {
  let n = with_db(list_users)
  assert_eq(n, 42)
}

test "compliant callback passes the row check" {
  // If this test compiles, the row check passed. The check happens at
  // `hica check` / `hica test` time, before any code runs.
  let _ = with_db(list_users)
  assert(true)
}
