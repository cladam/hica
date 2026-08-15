// hica — db-sandbox example (positive path)
//
// Demonstrates the effect-row polymorphic callback pattern.
//
// `with_db` is a capability-based sandbox: the callback `f` may only use
// the `<Db>` effect. hica's checker enforces this by walking every call
// site whose callee has an explicit row on a `TFun` parameter and comparing
// the argument's effect leak set against the row.
//
// `list_users` uses only <Db> ops → the check passes.
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
