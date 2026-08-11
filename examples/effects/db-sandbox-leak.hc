// hica — M4 db-sandbox negative example
//
// Companion to `db-sandbox.hc`. Here the callback `leaky_write` uses a
// `<Log>` op alongside `<Db>` — the effect-row on `with_db`'s callback
// parameter forbids that, so hica's checker rejects the call site at
// compile time with:
//
//   error: effect row mismatch — callback passed to 'with_db' may use
//     <Log, Db>, not permitted by <Db>
//
// Try:  hica check examples/effects/db-sandbox-leak.hc
// (This file is expected to *fail* to check — that IS the point.)

effect Db {
  fun query(sql: string) : int
  fun run_sql(sql: string)
}

effect Log {
  fun audit(msg: string)
}

pub fun with_db(f: () -> <Db> int) : int {
  handle Db {
    query(sql) => 42,
    run_sql(sql) => ()
  } in {
    f()
  }
}

// Leaky callback: uses <Log> as well as <Db>. Since with_db's
// callback annotation says `<Db>` only, this call is rejected.
fun leaky_write() : int {
  audit("touching users table")
  run_sql("INSERT INTO audit VALUES ('leak')")
  0
}

fun main() {
  let n = with_db(leaky_write)
  println(n)
}
