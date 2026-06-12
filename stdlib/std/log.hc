// hica standard library — structured logging
//
// Level-filtered, named logging with optional ANSI color and file output.
// Inspired by Python's logging module and the pylogging Rust crate.
// Import with: import "std/log"
//
// Usage:
//   import "std/log"
//
//   fun main() {
//     let log = make_logger("myapp")
//     log_info(log, "server started on port 8080")
//     log_warning(log, "disk usage above 85%")
//     log_error(log, "connection refused")
//   }
//
//   // Customize level, colors, or file sink:
//   fun main() {
//     let log = make_logger("myapp")
//       |> logger_set_level(Debug)
//       |> logger_set_file("app.log")
//     log_debug(log, "verbose diagnostic info")
//   }
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ---------------------------------------------------------------------------
// Log level
// ---------------------------------------------------------------------------

// Log severity levels, from least to most severe.
// Messages below the logger's configured level are discarded without output.
pub type LogLevel {
  Debug,
  Info,
  Warning,
  Error,
  Critical
}

// Numeric value for level comparisons (higher = more severe).
// Debug=0, Info=1, Warning=2, Error=3, Critical=4.
pub fun level_value(lv: LogLevel) : int => match lv {
  Debug    => 0,
  Info     => 1,
  Warning  => 2,
  Error    => 3,
  Critical => 4
}

// Human-readable level name used in formatted output.
pub fun level_name(lv: LogLevel) : string => match lv {
  Debug    => "DEBUG",
  Info     => "INFO",
  Warning  => "WARNING",
  Error    => "ERROR",
  Critical => "CRITICAL"
}

// ---------------------------------------------------------------------------
// Logger struct
// ---------------------------------------------------------------------------

// A named logger with a minimum level, optional ANSI color output, and an
// optional file sink. Loggers are immutable values — use the logger_set_*
// helpers to produce a modified copy.
//
// Fields:
//   name      — label shown in formatted output, e.g. "myapp" or "myapp.db"
//   level     — minimum severity; messages below this threshold are discarded
//   use_color — when true, wraps console output in per-level ANSI color codes
//   log_file  — path to an append log file; "" disables file logging
pub struct Logger {
  name: string,
  level: LogLevel,
  use_color: bool,
  log_file: string
}

// Create a logger with the given name, level Info, colors on, no file sink.
pub fun make_logger(name: string) : Logger =>
  Logger { name: name, level: Info, use_color: true, log_file: "" }

// Create a logger with an explicit minimum level.
pub fun make_logger_level(name: string, lv: LogLevel) : Logger =>
  Logger { name: name, level: lv, use_color: true, log_file: "" }

// Return a copy of the logger with a new minimum level.
pub fun logger_set_level(lg: Logger, lv: LogLevel) : Logger =>
  Logger { name: lg.name, level: lv, use_color: lg.use_color, log_file: lg.log_file }

// Return a copy of the logger with color output toggled.
pub fun logger_set_color(lg: Logger, enabled: bool) : Logger =>
  Logger { name: lg.name, level: lg.level, use_color: enabled, log_file: lg.log_file }

// Return a copy of the logger that also appends records to the given file.
// Pass "" to disable file logging. File records are always plain text (no ANSI).
pub fun logger_set_file(lg: Logger, path: string) : Logger =>
  Logger { name: lg.name, level: lg.level, use_color: lg.use_color, log_file: path }

// True if a message at the given level would be emitted by this logger.
pub fun log_enabled(lg: Logger, lv: LogLevel) : bool =>
  level_value(lv) >= level_value(lg.level)

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// ESC character (ASCII 27) for ANSI escape sequences.
pub fun log_esc() : string => char_to_string(chr(27))

// Wrap text in an ANSI SGR code, resetting to default after.
pub fun log_ansi(code: string, s: string) : string =>
  log_esc() + "[" + code + "m" + s + log_esc() + "[0m"

// Per-level ANSI color, matching the pylogging color scheme:
//   Debug=gray, Info=blue, Warning=yellow, Error=red, Critical=deep red
pub fun log_colorize(lv: LogLevel, s: string) : string => match lv {
  Debug    => log_ansi("90", s),
  Info     => log_ansi("34", s),
  Warning  => log_ansi("33", s),
  Error    => log_ansi("31", s),
  Critical => log_ansi("38;5;88", s)
}

// Format a log record as "[LEVEL] name: message".
pub fun log_format(name: string, lv: LogLevel, msg: string) : string =>
  "[" + level_name(lv) + "] " + name + ": " + msg

// Append a plain-text line to a log file (read → append → write).
// Silently ignores write failures — logging should never crash the program.
pub fun log_append_file(path: string, line: string) {
  let existing = match read_file(path) {
    Ok(content) => content,
    Err(_) => ""
  }
  match write_file(path, existing + line + "\n") {
    Ok(_) => { },
    Err(_) => { }
  }
}

// Emit a single record: filter by level, colorize for console, write to file.
// Error and Critical records go to stderr; all others go to stdout.
pub fun log_emit(lg: Logger, lv: LogLevel, msg: string) {
  if log_enabled(lg, lv) {
    let line = log_format(lg.name, lv, msg)
    let output = if lg.use_color { log_colorize(lv, line) } else { line }
    match lv {
      Error    => eprintln(output),
      Critical => eprintln(output),
      _        => println(output)
    }
    if !is_empty(lg.log_file) {
      log_append_file(lg.log_file, line)
    } else { }
  } else { }
}

// ---------------------------------------------------------------------------
// Public logging functions
// ---------------------------------------------------------------------------

// Emit a DEBUG record (level 0). Verbose diagnostic output, disabled by default.
pub fun log_debug(lg: Logger, msg: string) { log_emit(lg, Debug, msg) }

// Emit an INFO record (level 1). Normal operational messages (default minimum).
pub fun log_info(lg: Logger, msg: string) { log_emit(lg, Info, msg) }

// Emit a WARNING record (level 2). Unexpected situation that is not yet an error.
pub fun log_warning(lg: Logger, msg: string) { log_emit(lg, Warning, msg) }

// Emit an ERROR record (level 3). A failure that should be investigated. Goes to stderr.
pub fun log_error(lg: Logger, msg: string) { log_emit(lg, Error, msg) }

// Emit a CRITICAL record (level 4). Fatal or near-fatal condition. Goes to stderr.
pub fun log_critical(lg: Logger, msg: string) { log_emit(lg, Critical, msg) }
