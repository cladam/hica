// time-report.hc — showcase: std/term + std/datetime + built-in clock primitives
//
// Prints a colored time report using now_unix(), now_iso(), unix_to_iso()
// and the epoch duration helpers from std/datetime.

import "std/term"
import "std/datetime"

fun header(s: string) {
  println(bold(cyan(s)))
}

fun row(label: string, val_str: string) {
  println("  " + dim(label + ":") + " " + val_str)
}

fun age_label(days: int) : string {
  if days > 730 {
    bold(show(days / 365)) + yellow(" years ago")
  } else if days > 60 {
    bold(show(days / 30)) + yellow(" months ago")
  } else {
    bold(show(days)) + yellow(" days ago")
  }
}

fun check_date(s: string) {
  let result = if is_valid_date(s) { green("valid date") } else { red("invalid") }
  row(s, result)
}

fun check_time(s: string) {
  let result = if is_valid_time(s) { green("valid time") } else { red("invalid") }
  row(s, result)
}

fun check_iso(s: string) {
  let result = if is_iso_datetime(s) { green("valid ISO 8601") } else { red("invalid") }
  row(s, result)
}

fun main() {
  let epoch = now_unix()

  header("── System Time ─────────────────────────────")
  row("ISO 8601  ", green(now_iso()))
  row("Unix epoch", yellow(show(epoch)))
  println("")

  header("── Historical Timestamps ───────────────────")
  let y2k     = date_to_unix("2000-01-01")
  let billion = date_to_unix("2001-09-09")
  let hica_v0 = date_to_unix("2024-01-01")

  row("Y2K          (" + unix_to_iso(y2k)     + ")", age_label(days_since(y2k)))
  row("Unix 10^9    (" + unix_to_iso(billion)  + ")", age_label(days_since(billion)))
  row("Hica v0.1    (" + unix_to_iso(hica_v0)  + ")", age_label(days_since(hica_v0)))
  println("")

  header("── Duration Math ───────────────────────────")
  let one_week_ago  = epoch - 604800
  let one_month_ago = epoch - 2592000
  row("secs between (now, now-1w)", bold(show(secs_diff(epoch, one_week_ago))))
  row("days between (now, now-1m)", bold(show(days_diff(epoch, one_month_ago))))
  row("is now-1m older than 7d   ", bold(show(is_older_than_days(one_month_ago, 7))))
  println("")

  header("── Validation ──────────────────────────────")
  check_date("2026-05-27")
  check_date("2026-13-01")
  check_date("not-a-date")
  check_time("14:30:00")
  check_time("25:00:00")
  check_iso(now_iso())
  println("")

  println(bold("done."))
}
