// hica – CLI argument parsing prelude
//
// A lightweight CLI parsing library inspired by klap/clap.
// Covers the 80% case: flags, options, positionals, help, and version.
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

struct CliFlag {
  flag_name: string,
  flag_short: string,
  flag_help: string
}

struct CliOption {
  opt_name: string,
  opt_short: string,
  opt_help: string,
  opt_default: string
}

struct CliSpec {
  app_name: string,
  app_version: string,
  app_about: string,
  app_flags: list<CliFlag>,
  app_options: list<CliOption>
}

struct CliResult {
  cli_flags: list<string>,
  cli_options: list<(string, string)>,
  cli_positionals: list<string>
}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

fun cli_app(name: string, version: string, about: string) =>
  CliSpec {
    app_name: name,
    app_version: version,
    app_about: about,
    app_flags: [],
    app_options: []
  }

fun cli_add_flag(spec: CliSpec, name: string, short: string, help_text: string) =>
  CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags + [CliFlag { flag_name: name, flag_short: short, flag_help: help_text }],
    app_options: spec.app_options
  }

fun cli_add_option(spec: CliSpec, name: string, short: string, help_text: string) =>
  CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags,
    app_options: spec.app_options + [CliOption { opt_name: name, opt_short: short, opt_help: help_text, opt_default: "" }]
  }

// ---------------------------------------------------------------------------
// Help & version formatting
// ---------------------------------------------------------------------------

fun format_flag_usage(f: CliFlag) =>
  if is_empty(f.flag_short) { pad_right("    --" + f.flag_name, 24, " ") + f.flag_help }
  else { pad_right("  -" + f.flag_short + ", --" + f.flag_name, 24, " ") + f.flag_help }

fun format_option_usage(o: CliOption) =>
  if is_empty(o.opt_short) { pad_right("    --" + o.opt_name + " VALUE", 24, " ") + o.opt_help }
  else { pad_right("  -" + o.opt_short + ", --" + o.opt_name + " VALUE", 24, " ") + o.opt_help }

fun cli_help(spec: CliSpec) {
  let header = spec.app_name + " " + spec.app_version + " — " + spec.app_about;
  let usage_line = "USAGE: " + spec.app_name + " [OPTIONS] [ARGS...]";
  let flag_lines = map(spec.app_flags, (f) => format_flag_usage(f));
  let opt_lines = map(spec.app_options, (o) => format_option_usage(o));
  let builtin = [
    pad_right("  -h, --help", 24, " ") + "Show this help",
    pad_right("      --version", 24, " ") + "Show version"
  ];
  let all_opts = flag_lines + opt_lines + builtin;
  header + "\n\n" + usage_line + "\n\nOPTIONS:\n" + join(all_opts, "\n")
}

fun cli_version_str(spec: CliSpec) =>
  spec.app_name + " " + spec.app_version

// ---------------------------------------------------------------------------
// Querying results
// ---------------------------------------------------------------------------

fun cli_empty() =>
  CliResult { cli_flags: [], cli_options: [], cli_positionals: [] }

fun has_flag(r: CliResult, name: string) : bool =>
  any(r.cli_flags, (f) => f == name)

fun get_opt(r: CliResult, name: string) =>
  match find(r.cli_options, (pair) => pair.0 == name) {
    Some(pair) => Some(pair.1),
    None => None
  }

fun get_opt_or(r: CliResult, name: string, default: string) =>
  match get_opt(r, name) {
    Some(v) => v,
    None => default
  }

fun get_positionals(r: CliResult) => r.cli_positionals

// ---------------------------------------------------------------------------
// Parsing internals (bottom-up order — callees before callers)
// ---------------------------------------------------------------------------

fun find_flag_long(flags: list<CliFlag>, name: string) =>
  find(flags, (f) => f.flag_name == name)

fun find_flag_short(flags: list<CliFlag>, s: string) =>
  find(flags, (f) => f.flag_short == s)

fun find_opt_long(options: list<CliOption>, name: string) =>
  find(options, (o) => o.opt_name == name)

fun find_opt_short(options: list<CliOption>, s: string) =>
  find(options, (o) => o.opt_short == s)

fun add_flag_result(acc: CliResult, name: string) =>
  CliResult { cli_flags: acc.cli_flags + [name], cli_options: acc.cli_options, cli_positionals: acc.cli_positionals }

fun add_opt_result(acc: CliResult, name: string, v: string) =>
  CliResult { cli_flags: acc.cli_flags, cli_options: acc.cli_options + [(name, v)], cli_positionals: acc.cli_positionals }

fun add_pos_result(acc: CliResult, v: string) =>
  CliResult { cli_flags: acc.cli_flags, cli_options: acc.cli_options, cli_positionals: acc.cli_positionals + [v] }

fun add_all_pos(acc: CliResult, args: list<string>) =>
  CliResult { cli_flags: acc.cli_flags, cli_options: acc.cli_options, cli_positionals: acc.cli_positionals + args }

// --- Leaf parsers (no forward references) ---

fun do_parse_short_opt(spec: CliSpec, s: string, rest: list<string>, acc: CliResult, cont) =>
  match find_opt_short(spec.app_options, s) {
    Some(o) => if length(rest) == 0 { Err("option -{s} requires a value") }
              else { cont(spec, drop(rest, 1), add_opt_result(acc, o.opt_name, rest[0])) },
    None    => Err("unknown option: -{s}")
  }

fun do_parse_short(spec: CliSpec, s: string, rest: list<string>, acc: CliResult, cont) =>
  match find_flag_short(spec.app_flags, s) {
    Some(f) => cont(spec, rest, add_flag_result(acc, f.flag_name)),
    None    => do_parse_short_opt(spec, s, rest, acc, cont)
  }

fun do_parse_long_opt(spec: CliSpec, name: string, rest: list<string>, acc: CliResult, cont) =>
  match find_opt_long(spec.app_options, name) {
    Some(_) => if length(rest) == 0 { Err("option --{name} requires a value") }
              else { cont(spec, drop(rest, 1), add_opt_result(acc, name, rest[0])) },
    None    => Err("unknown option: --{name}")
  }

fun do_parse_long(spec: CliSpec, name: string, rest: list<string>, acc: CliResult, cont) =>
  match find_flag_long(spec.app_flags, name) {
    Some(_) => cont(spec, rest, add_flag_result(acc, name)),
    None    => do_parse_long_opt(spec, name, rest, acc, cont)
  }

fun do_parse_long_eq(spec: CliSpec, arg: string, rest: list<string>, acc: CliResult, cont) {
  let clean = removeprefix(arg, "--");
  let parts = split(clean, "=");
  let name = parts[0];
  let v = join(drop(parts, 1), "=");
  match find_opt_long(spec.app_options, name) {
    Some(_) => cont(spec, rest, add_opt_result(acc, name, v)),
    None    => Err("unknown option: --{name}")
  }
}

fun do_parse_one(spec: CliSpec, arg: string, rest: list<string>, acc: CliResult, cont) =>
  if starts_with(arg, "--") {
    if contains(arg, "=") { do_parse_long_eq(spec, arg, rest, acc, cont) }
    else { do_parse_long(spec, removeprefix(arg, "--"), rest, acc, cont) }
  }
  else {
    if starts_with(arg, "-") { do_parse_short(spec, removeprefix(arg, "-"), rest, acc, cont) }
    else { cont(spec, rest, add_pos_result(acc, arg)) }
  }

// --- Main parse loop (recursive, calls do_parse_one) ---

fun do_parse(spec: CliSpec, args: list<string>, acc: CliResult) =>
  if length(args) == 0 { Ok(acc) }
  else {
    match args[0] {
      "--help"    => Err("__help__"),
      "--version" => Err("__version__"),
      "--"        => Ok(add_all_pos(acc, drop(args, 1))),
      _           => do_parse_one(spec, args[0], drop(args, 1), acc, do_parse)
    }
  }

// ---------------------------------------------------------------------------
// Public parsing API
// ---------------------------------------------------------------------------

fun cli_parse(spec: CliSpec) =>
  do_parse(spec, get_args(), cli_empty())

fun cli_parse_or_exit(spec: CliSpec) =>
  match cli_parse(spec) {
    Ok(r)               => r,
    Err("__help__")     => { println(cli_help(spec)); cli_empty() },
    Err("__version__")  => { println(cli_version_str(spec)); cli_empty() },
    Err(msg)            => { eprintln("error: {msg}"); eprintln("try --help for usage"); cli_empty() }
  }
