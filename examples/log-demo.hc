import "std/log"

fun main() {
  let log = make_logger("myapp")
  log_info(log, "server started on port 8080")
  log_warning(log, "disk usage above 85%")
  log_error(log, "connection refused")

  let dbg = make_logger("myapp.db") |> logger_set_level(Debug)
  log_debug(dbg, "query took 42ms")
  log_info(dbg, "connected to database")
  log_critical(dbg, "database unreachable")

  let plain = make_logger("batch") |> logger_set_color(false)
  log_info(plain, "processing 1000 records")
}
