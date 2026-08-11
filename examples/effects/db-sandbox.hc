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
// M4.5 note — the op name `exec` used to collide with hica's stdlib
// `exec(cmd) → run-system-read(cmd)` codegen intercept. The checker now
// tags every effect-op call site with an `hc-op:` prefix so the codegen
// stdlib arms never hijack them; the emitted Koka call is `hc_exec(sql)`,
// matching the `ctl hc_exec(...)` in the `effect db` declaration.
//
// Run:  hica run examples/effects/db-sandbox.hc

effect Db {
  fun query(sql: string) : int
  fun exec(sql: string)
}

// Callback contract: `f` may only use `<Db>`. built-ins (div, console)
// are always allowed in v1.
pub fun with_db(f: () -> <Db> int) : int {
  handle Db {
    query(sql) => 42,
    exec(sql) => ()
  } in {
    f()
  }
}

// Compliant callback: uses only <Db> ops. Passes the M4 subset check.
fun list_users() : <Db> int {
  exec("UPDATE stats SET last_scan = now()")
  let n = query("SELECT count(*) FROM users")
  n
}

fun main() {
  let count = with_db(list_users)
  println("users = " + show(count))
}
