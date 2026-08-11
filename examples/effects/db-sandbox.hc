// hica — M4 db-sandbox example (positive path)
//
// Demonstrates the effect-row polymorphic callback pattern from
// documentation/effects-design.md §2.2, §4.5, and §13.2.
//
// `with_db` is a capability-based sandbox: the callback `f` may only use
// the `<Db>` effect. hica's checker enforces this by walking every call
// site whose callee has an explicit row on a `TFun` parameter and comparing
// the argument's effect leak set against the row.
//
// `list_users` uses only <Db> ops → the check passes.
//
// NOTE — v1 codegen limitation (tracked in effects-journal.md M4
// carry-forward): user effect op names must not collide with hica stdlib
// function names (`exec`, `write`, `read`, `input`, `print`, `println`,
// `open`, `close`, ...). The codegen intercepts those names for stdlib
// lowering *before* it consults the effect-op registry, so a user op
// named `exec` gets emitted as `run-system-read(...)` and Koka rejects the
// resulting effect row. Until session-10's codegen fix lands, name your
// effect ops distinctively: here we use `query` and `run_sql` instead of
// `exec`.
//
// Run:  hica run examples/effects/db-sandbox.hc

effect Db {
  fun query(sql: string) : int
  fun run_sql(sql: string)
}

// Callback contract: `f` may only use `<Db>`. built-ins (div, console)
// are always allowed in v1.
pub fun with_db(f: () -> <Db> int) : int {
  handle Db {
    query(sql) => 42,
    run_sql(sql) => ()
  } in {
    f()
  }
}

// Compliant callback: uses only <Db> ops. Passes the M4 subset check.
fun list_users() : <Db> int {
  run_sql("UPDATE stats SET last_scan = now()")
  let n = query("SELECT count(*) FROM users")
  n
}

fun main() {
  let count = with_db(list_users)
  println("users = " + show(count))
}
