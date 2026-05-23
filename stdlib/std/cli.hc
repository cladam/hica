// hica – CLI argument parsing stdlib module
//
// A lightweight CLI parsing library inspired by klap/clap.
// Covers the 80% case: flags, options, positional args, subcommands,
// help, version, combined short flags (-vf), and typed option values.
//
// Import with: import "std/cli"
//
// Usage:
//   let spec = cli("myapp", "1.0.0", "does cool stuff")
//     |> flag("verbose", "v", "enable verbose output")
//     |> option("output", "o", "output file")
//     |> option_default("format", "f", "output format", "json")
//     |> arg("input", "input file", true)
//     |> command("check", check_spec)
//
//   match cli_parse(spec) {
//     Parsed(r) => {
//       if has_flag(r, "verbose") { println("verbose!") }
//       let fmt = get_opt_or(r, "format", "json")
//       let count = get_opt_int_or(r, "count", 1)
//       let name = get_positional(r, 0)
//     },
//     Help          => println(cli_help(spec)),
//     Version       => println(cli_version_str(spec)),
//     CliError(msg) => eprintln("error: {msg}")
//   }
//
//   // Or use cli_parse_or_exit for the common case:
//   let r = cli_parse_or_exit(spec)
//
// Short flags can be combined: -vf is equivalent to -v -f.
// An option short can appear last: -vo out.txt or -oout.txt.
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

pub struct CliFlag {
  flag_name: string,
  flag_short: string,
  flag_help: string
}

pub struct CliOption {
  opt_name: string,
  opt_short: string,
  opt_help: string,
  opt_default: string
}

pub struct CliArg {
  arg_name: string,
  arg_help: string,
  arg_required: bool
}

pub struct CliSpec {
  app_name: string,
  app_version: string,
  app_about: string,
  app_flags: list<CliFlag>,
  app_options: list<CliOption>,
  app_args: list<CliArg>,
  app_commands: list<(string, CliSpec)>
}

pub struct CliResult {
  cli_flags: list<string>,
  cli_options: list<(string, string)>,
  cli_positionals: list<string>,
  cli_command: string,
  cli_sub: maybe<CliResult>
}

pub type CliOutcome {
  Help,
  Version,
  CliError(cli_error_msg: string),
  Parsed(cli_result: CliResult)
}

// ---------------------------------------------------------------------------
// Builders (pipe-friendly)
// ---------------------------------------------------------------------------

pub fun cli(name: string, version: string, about: string) =>
  CliSpec {
    app_name: name,
    app_version: version,
    app_about: about,
    app_flags: [],
    app_options: [],
    app_args: [],
    app_commands: []
  }

// --- with_* helpers to reduce builder boilerplate ---

pub fun with_flags(spec: CliSpec, flags: list<CliFlag>) =>
  CliSpec { app_name: spec.app_name, app_version: spec.app_version,
            app_about: spec.app_about, app_flags: flags,
            app_options: spec.app_options, app_args: spec.app_args,
            app_commands: spec.app_commands }

pub fun with_options(spec: CliSpec, options: list<CliOption>) =>
  CliSpec { app_name: spec.app_name, app_version: spec.app_version,
            app_about: spec.app_about, app_flags: spec.app_flags,
            app_options: options, app_args: spec.app_args,
            app_commands: spec.app_commands }

pub fun with_args(spec: CliSpec, args: list<CliArg>) =>
  CliSpec { app_name: spec.app_name, app_version: spec.app_version,
            app_about: spec.app_about, app_flags: spec.app_flags,
            app_options: spec.app_options, app_args: args,
            app_commands: spec.app_commands }

pub fun with_commands(spec: CliSpec, commands: list<(string, CliSpec)>) =>
  CliSpec { app_name: spec.app_name, app_version: spec.app_version,
            app_about: spec.app_about, app_flags: spec.app_flags,
            app_options: spec.app_options, app_args: spec.app_args,
            app_commands: commands }

pub fun flag(spec: CliSpec, name: string, short: string, help_text: string) =>
  with_flags(spec, spec.app_flags + [CliFlag { flag_name: name, flag_short: short, flag_help: help_text }])

pub fun option(spec: CliSpec, name: string, short: string, help_text: string) =>
  with_options(spec, spec.app_options + [CliOption { opt_name: name, opt_short: short, opt_help: help_text, opt_default: "" }])

pub fun option_default(spec: CliSpec, name: string, short: string, help_text: string, default: string) =>
  with_options(spec, spec.app_options + [CliOption { opt_name: name, opt_short: short, opt_help: help_text, opt_default: default }])

pub fun arg(spec: CliSpec, name: string, help_text: string, required: bool) =>
  with_args(spec, spec.app_args + [CliArg { arg_name: name, arg_help: help_text, arg_required: required }])

pub fun command(spec: CliSpec, name: string, sub: CliSpec) =>
  with_commands(spec, spec.app_commands + [(name, sub)])

// ---------------------------------------------------------------------------
// Help & version formatting
// ---------------------------------------------------------------------------

pub fun format_flag_usage(f: CliFlag) =>
  if is_empty(f.flag_short) { pad_right("    --{f.flag_name}", 24, " ") + f.flag_help }
  else { pad_right("  -{f.flag_short}, --{f.flag_name}", 24, " ") + f.flag_help }

pub fun format_option_usage(o: CliOption) {
  let suffix = if is_empty(o.opt_default) { "" } else { " [default: {o.opt_default}]" }
  if is_empty(o.opt_short) { pad_right("    --{o.opt_name} VALUE", 24, " ") + o.opt_help + suffix }
  else { pad_right("  -{o.opt_short}, --{o.opt_name} VALUE", 24, " ") + o.opt_help + suffix }
}

pub fun format_arg_usage(a: CliArg) {
  let marker = if a.arg_required { " (required)" } else { "" }
  pad_right("  <{a.arg_name}>", 24, " ") + a.arg_help + marker
}

pub fun format_arg_label(a: CliArg) =>
  if a.arg_required { " <{a.arg_name}>" } else { " [{a.arg_name}]" }

pub fun format_cmd_usage(pair: (string, CliSpec)) =>
  pad_right("  {pair.0}", 24, " ") + pair.1.app_about

pub fun cli_help(spec: CliSpec) {
  let header = "{spec.app_name} {spec.app_version} — {spec.app_about}"
  let arg_labels = map(spec.app_args, (a) => format_arg_label(a))
  let args_str = join(arg_labels, "")
  let cmds_str = if length(spec.app_commands) > 0 { " <COMMAND>" } else { "" }
  let usage_line = "USAGE: {spec.app_name} [OPTIONS]{args_str}{cmds_str}"
  let flag_lines = map(spec.app_flags, (f) => format_flag_usage(f))
  let opt_lines = map(spec.app_options, (o) => format_option_usage(o))
  let builtin = [
    pad_right("  -h, --help", 24, " ") + "Show this help",
    pad_right("      --version", 24, " ") + "Show version"
  ]
  let all_opts = flag_lines + opt_lines + builtin
  var out = "{header}\n\n{usage_line}\n\nOPTIONS:\n{join(all_opts, "\n")}"
  if length(spec.app_args) > 0 {
    let arg_lines = map(spec.app_args, (a) => format_arg_usage(a))
    out = "{out}\n\nARGS:\n{join(arg_lines, "\n")}"
  }
  if length(spec.app_commands) > 0 {
    let cmd_lines = map(spec.app_commands, (c) => format_cmd_usage(c))
    out = "{out}\n\nCOMMANDS:\n{join(cmd_lines, "\n")}"
  }
  out
}

pub fun cli_version_str(spec) => "{spec.app_name} {spec.app_version}"

// ---------------------------------------------------------------------------
// Querying results
// ---------------------------------------------------------------------------

pub fun cli_empty() =>
  CliResult { cli_flags: [], cli_options: [], cli_positionals: [], cli_command: "", cli_sub: None }

pub fun has_flag(r: CliResult, name: string) : bool =>
  name in r.cli_flags

pub fun get_opt(r: CliResult, name: string) =>
  match find(r.cli_options, (pair) => pair.0 == name) {
    Some(pair) => Some(pair.1),
    None => None
  }

pub fun get_opt_or(r: CliResult, name: string, default: string) =>
  match get_opt(r, name) {
    Some(v) => v,
    None => default
  }

pub fun get_opt_int(r: CliResult, name: string) =>
  match get_opt(r, name) {
    Some(v) => parse_int(v),
    None => None
  }

pub fun get_opt_int_or(r: CliResult, name: string, default: int) : int =>
  match get_opt_int(r, name) {
    Some(v) => v,
    None => default
  }

pub fun get_opt_float(r: CliResult, name: string) =>
  match get_opt(r, name) {
    Some(v) => parse_float(v),
    None => None
  }

pub fun get_opt_float_or(r: CliResult, name: string, default: float) : float =>
  match get_opt_float(r, name) {
    Some(v) => v,
    None => default
  }

pub fun get_positional(r: CliResult, index: int) =>
  if index < length(r.cli_positionals) { Some(r.cli_positionals[index]) }
  else { None }

pub fun get_positionals(r: CliResult) => r.cli_positionals

pub fun get_command(r: CliResult) => r.cli_command

pub fun get_sub(r: CliResult) => r.cli_sub

// ---------------------------------------------------------------------------
// Parsing internals
// ---------------------------------------------------------------------------

pub fun find_flag_long(flags: list<CliFlag>, name: string) =>
  find(flags, (f) => f.flag_name == name)

pub fun find_flag_short(flags: list<CliFlag>, s: string) =>
  find(flags, (f) => f.flag_short == s)

pub fun find_opt_long(options: list<CliOption>, name: string) =>
  find(options, (o) => o.opt_name == name)

pub fun find_opt_short(options: list<CliOption>, s: string) =>
  find(options, (o) => o.opt_short == s)

pub fun find_command(commands: list<(string, CliSpec)>, name: string) =>
  find(commands, (pair) => pair.0 == name)

// Apply default values for options not provided by the user
pub fun add_default(acc: list<(string, string)>, o: CliOption) =>
  if !is_empty(o.opt_default) && !any(acc, (pair) => pair.0 == o.opt_name) {
    acc + [(o.opt_name, o.opt_default)]
  }
  else { acc }

pub fun apply_defaults(spec: CliSpec, options: list<(string, string)>) =>
  fold(spec.app_options, options, (acc, o) => add_default(acc, o))

// Check that all required positional args were provided
pub fun check_one_arg(positionals: list<string>, err: string, pair: (int, CliArg)) =>
  if !is_empty(err) { err }
  else {
    if pair.1.arg_required && pair.0 >= length(positionals) {
      "missing required argument: <{pair.1.arg_name}>"
    }
    else { "" }
  }

pub fun check_required_args(spec: CliSpec, positionals: list<string>) =>
  fold(enumerate(spec.app_args), "", (err, pair) => check_one_arg(positionals, err, pair))

// Internal struct to pass parse results without exceeding Koka's 5-tuple limit
pub struct ParseRaw {
  raw_error: string,
  raw_flags: list<string>,
  raw_options: list<(string, string)>,
  raw_positionals: list<string>,
  raw_subcmd: string,
  raw_sub_args: list<string>
}

// --- Parse loop: var/while, non-recursive ---

pub fun parse_loop(spec: CliSpec, args: list<string>) {
  var flags: list<string> = []
  var options: list<(string, string)> = []
  var positionals: list<string> = []
  var subcmd = ""
  var sub_args: list<string> = []
  var remaining = args
  var error = ""
  var short_chars: list<string> = []
  var si = 0

  while is_empty(error) && length(remaining) > 0 {
    let a = remaining[0]
    remaining = drop(remaining, 1)

    if a == "--help" || a == "-h" { error = "__help__"; break }
    else if a == "--version" { error = "__version__"; break }
    else if a == "--" {
      positionals = positionals + remaining
      break
    }
    else if starts_with(a, "--") && contains(a, "=") {
      let clean = removeprefix(a, "--")
      let parts = split(clean, "=")
      let name = parts[0]
      let v = join(drop(parts, 1), "=")
      match find_opt_long(spec.app_options, name) {
        Some(_) => { options = options + [(name, v)] },
        None    => { error = "unknown option: --{name}" }
      }
    }
    else if starts_with(a, "--") {
      let name = removeprefix(a, "--")
      match find_flag_long(spec.app_flags, name) {
        Some(_) => { flags = flags + [name] },
        None    => match find_opt_long(spec.app_options, name) {
          Some(_) => if length(remaining) == 0 { error = "option --{name} requires a value" }
                     else { options = options + [(name, remaining[0])]; remaining = drop(remaining, 1) },
          None    => { error = "unknown option: --{name}" }
        }
      }
    }
    else if starts_with(a, "-") {
      short_chars = map(chars(removeprefix(a, "-")), (c) => char_to_string(c))
      si = 0
      while si < length(short_chars) && is_empty(error) {
        let c = short_chars[si]
        match find_flag_short(spec.app_flags, c) {
          Some(f) => { flags = flags + [f.flag_name]; si = si + 1 },
          None => match find_opt_short(spec.app_options, c) {
            Some(o) => if si + 1 < length(short_chars) {
              options = options + [(o.opt_name, join(drop(short_chars, si + 1), ""))]
              si = length(short_chars)
            }
            else if length(remaining) == 0 { error = "option -{c} requires a value"; si = si + 1 }
            else {
              options = options + [(o.opt_name, remaining[0])]
              remaining = drop(remaining, 1)
              si = si + 1
            },
            None => { error = "unknown option: -{c}"; si = si + 1 }
          }
        }
      }
    }
    else {
      match find_command(spec.app_commands, a) {
        Some(_) => { subcmd = a; sub_args = remaining; break },
        None    => { positionals = positionals + [a] }
      }
    }
  }

  ParseRaw {
    raw_error: error,
    raw_flags: flags,
    raw_options: options,
    raw_positionals: positionals,
    raw_subcmd: subcmd,
    raw_sub_args: sub_args
  }
}

// --- Recursive wrapper: handles subcommand parsing ---

pub fun cli_parse_args(spec: CliSpec, args: list<string>) {
  let raw = parse_loop(spec, args)
  let error = raw.raw_error
  let flags = raw.raw_flags
  let options = raw.raw_options
  let positionals = raw.raw_positionals
  let subcmd = raw.raw_subcmd
  let sub_args = raw.raw_sub_args

  if error == "__help__" { Help }
  else if error == "__version__" { Version }
  else if !is_empty(error) { CliError(error) }
  else {
    let final_options = apply_defaults(spec, options)
    let req_err = check_required_args(spec, positionals)
    if !is_empty(req_err) { CliError(req_err) }
    else if !is_empty(subcmd) {
      match find_command(spec.app_commands, subcmd) {
        Some(pair) => match cli_parse_args(pair.1, sub_args) {
          Parsed(sub) => Parsed(CliResult {
            cli_flags: flags,
            cli_options: final_options,
            cli_positionals: positionals,
            cli_command: subcmd,
            cli_sub: Some(sub)
          }),
          other => other
        },
        None => CliError("unknown command: {subcmd}")
      }
    }
    else {
      Parsed(CliResult {
        cli_flags: flags,
        cli_options: final_options,
        cli_positionals: positionals,
        cli_command: "",
        cli_sub: None
      })
    }
  }
}

// ---------------------------------------------------------------------------
// Public parsing API
// ---------------------------------------------------------------------------

pub fun cli_parse(spec) =>
  cli_parse_args(spec, get_args())

pub fun cli_parse_or_exit(spec) =>
  match cli_parse(spec) {
    Parsed(r)     => r,
    Help          => { println(cli_help(spec)); exit(0); cli_empty() },
    Version       => { println(cli_version_str(spec)); exit(0); cli_empty() },
    CliError(msg) => { eprintln("error: {msg}"); eprintln("try --help for usage"); exit(1); cli_empty() }
  }
