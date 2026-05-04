// hica – CLI argument parsing prelude
//
// A lightweight CLI parsing library inspired by klap/clap and XS cli_args.
// Covers the 80% case: flags, options, positional args, subcommands,
// help, and version.
//
// Usage with pipe-friendly builders:
//   let spec = cli("myapp", "1.0.0", "does cool stuff")
//     |> flag("verbose", "v", "enable verbose output")
//     |> option("output", "o", "output file")
//     |> option_default("format", "f", "output format", "json")
//     |> arg("input", "input file", true)
//     |> command("check", check_spec)
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

struct CliArg {
  arg_name: string,
  arg_help: string,
  arg_required: bool
}

struct CliSpec {
  app_name: string,
  app_version: string,
  app_about: string,
  app_flags: list<CliFlag>,
  app_options: list<CliOption>,
  app_args: list<CliArg>,
  app_commands: list<(string, CliSpec)>
}

struct CliResult {
  cli_flags: list<string>,
  cli_options: list<(string, string)>,
  cli_positionals: list<string>,
  cli_command: string,
  cli_sub: maybe<CliResult>
}

// ---------------------------------------------------------------------------
// Builders (pipe-friendly: each returns a (CliSpec) -> CliSpec closure)
//
//   cli("myapp", "1.0.0", "about")
//     |> flag("verbose", "v", "enable verbose output")
//     |> option("output", "o", "output file")
// ---------------------------------------------------------------------------

fun cli(name: string, version: string, about: string) =>
  CliSpec {
    app_name: name,
    app_version: version,
    app_about: about,
    app_flags: [],
    app_options: [],
    app_args: [],
    app_commands: []
  }

fun flag(name: string, short: string, help_text: string) =>
  (spec) => CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags + [CliFlag { flag_name: name, flag_short: short, flag_help: help_text }],
    app_options: spec.app_options,
    app_args: spec.app_args,
    app_commands: spec.app_commands
  }

fun option(name: string, short: string, help_text: string) =>
  (spec) => CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags,
    app_options: spec.app_options + [CliOption { opt_name: name, opt_short: short, opt_help: help_text, opt_default: "" }],
    app_args: spec.app_args,
    app_commands: spec.app_commands
  }

fun option_default(name: string, short: string, help_text: string, default: string) =>
  (spec) => CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags,
    app_options: spec.app_options + [CliOption { opt_name: name, opt_short: short, opt_help: help_text, opt_default: default }],
    app_args: spec.app_args,
    app_commands: spec.app_commands
  }

fun arg(name: string, help_text: string, required: bool) =>
  (spec) => CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags,
    app_options: spec.app_options,
    app_args: spec.app_args + [CliArg { arg_name: name, arg_help: help_text, arg_required: required }],
    app_commands: spec.app_commands
  }

fun command(name: string, sub: CliSpec) =>
  (spec) => CliSpec {
    app_name: spec.app_name,
    app_version: spec.app_version,
    app_about: spec.app_about,
    app_flags: spec.app_flags,
    app_options: spec.app_options,
    app_args: spec.app_args,
    app_commands: spec.app_commands + [(name, sub)]
  }

// ---------------------------------------------------------------------------
// Help & version formatting
// ---------------------------------------------------------------------------

fun format_flag_usage(f: CliFlag) =>
  if is_empty(f.flag_short) { pad_right("    --" + f.flag_name, 24, " ") + f.flag_help }
  else { pad_right("  -" + f.flag_short + ", --" + f.flag_name, 24, " ") + f.flag_help }

fun format_option_usage(o: CliOption) {
  let suffix = if is_empty(o.opt_default) { "" } else { " [default: " + o.opt_default + "]" }
  if is_empty(o.opt_short) { pad_right("    --" + o.opt_name + " VALUE", 24, " ") + o.opt_help + suffix }
  else { pad_right("  -" + o.opt_short + ", --" + o.opt_name + " VALUE", 24, " ") + o.opt_help + suffix }
}

fun format_arg_usage(a: CliArg) {
  let marker = if a.arg_required { " (required)" } else { "" }
  pad_right("  <" + a.arg_name + ">", 24, " ") + a.arg_help + marker
}

fun format_arg_label(a: CliArg) =>
  if a.arg_required { " <" + a.arg_name + ">" } else { " [" + a.arg_name + "]" }

fun format_cmd_usage(pair: (string, CliSpec)) =>
  pad_right("  " + pair.0, 24, " ") + pair.1.app_about

fun cli_help(spec: CliSpec) {
  let header = spec.app_name + " " + spec.app_version + " — " + spec.app_about
  let arg_labels = map(spec.app_args, (a) => format_arg_label(a))
  let args_str = join(arg_labels, "")
  let cmds_str = if length(spec.app_commands) > 0 { " <COMMAND>" } else { "" }
  let usage_line = "USAGE: " + spec.app_name + " [OPTIONS]" + args_str + cmds_str
  let flag_lines = map(spec.app_flags, (f) => format_flag_usage(f))
  let opt_lines = map(spec.app_options, (o) => format_option_usage(o))
  let builtin = [
    pad_right("  -h, --help", 24, " ") + "Show this help",
    pad_right("      --version", 24, " ") + "Show version"
  ]
  let all_opts = flag_lines + opt_lines + builtin
  var out = header + "\n\n" + usage_line + "\n\nOPTIONS:\n" + join(all_opts, "\n")
  if length(spec.app_args) > 0 {
    let arg_lines = map(spec.app_args, (a) => format_arg_usage(a))
    out = out + "\n\nARGS:\n" + join(arg_lines, "\n")
  }
  if length(spec.app_commands) > 0 {
    let cmd_lines = map(spec.app_commands, (c) => format_cmd_usage(c))
    out = out + "\n\nCOMMANDS:\n" + join(cmd_lines, "\n")
  }
  out
}

fun cli_version_str(spec) =>
  spec.app_name + " " + spec.app_version

// ---------------------------------------------------------------------------
// Querying results
// ---------------------------------------------------------------------------

fun cli_empty() =>
  CliResult { cli_flags: [], cli_options: [], cli_positionals: [], cli_command: "", cli_sub: None }

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

fun get_command(r: CliResult) => r.cli_command

fun get_sub(r: CliResult) => r.cli_sub

// ---------------------------------------------------------------------------
// Parsing internals
// ---------------------------------------------------------------------------

fun find_flag_long(flags: list<CliFlag>, name: string) =>
  find(flags, (f) => f.flag_name == name)

fun find_flag_short(flags: list<CliFlag>, s: string) =>
  find(flags, (f) => f.flag_short == s)

fun find_opt_long(options: list<CliOption>, name: string) =>
  find(options, (o) => o.opt_name == name)

fun find_opt_short(options: list<CliOption>, s: string) =>
  find(options, (o) => o.opt_short == s)

fun find_command(commands: list<(string, CliSpec)>, name: string) =>
  find(commands, (pair) => pair.0 == name)

// Apply default values for options not provided by the user
fun add_default(acc: list<(string, string)>, o: CliOption) =>
  if !is_empty(o.opt_default) && !any(acc, (pair) => pair.0 == o.opt_name) {
    acc + [(o.opt_name, o.opt_default)]
  }
  else { acc }

fun apply_defaults(spec: CliSpec, options: list<(string, string)>) =>
  fold(spec.app_options, options, (acc, o) => add_default(acc, o))

// Check that all required positional args were provided
fun check_one_arg(positionals: list<string>, err: string, pair: (int, CliArg)) =>
  if !is_empty(err) { err }
  else {
    if pair.1.arg_required && pair.0 >= length(positionals) {
      "missing required argument: <" + pair.1.arg_name + ">"
    }
    else { "" }
  }

fun check_required_args(spec: CliSpec, positionals: list<string>) =>
  fold(enumerate(spec.app_args), "", (err, pair) => check_one_arg(positionals, err, pair))

// Internal struct to pass parse results without exceeding Koka's 5-tuple limit
struct ParseRaw {
  raw_error: string,
  raw_flags: list<string>,
  raw_options: list<(string, string)>,
  raw_positionals: list<string>,
  raw_subcmd: string,
  raw_sub_args: list<string>
}

// --- Parse loop: var/while, non-recursive ---

fun parse_loop(spec: CliSpec, args: list<string>) {
  var flags: list<string> = []
  var options: list<(string, string)> = []
  var positionals: list<string> = []
  var subcmd = ""
  var sub_args: list<string> = []
  var remaining = args
  var error = ""

  while is_empty(error) && length(remaining) > 0 {
    let a = remaining[0]
    remaining = drop(remaining, 1)

    if a == "--help" || a == "-h" { error = "__help__" }
    else if a == "--version" { error = "__version__" }
    else if a == "--" {
      positionals = positionals + remaining
      remaining = []
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
      let s = removeprefix(a, "-")
      match find_flag_short(spec.app_flags, s) {
        Some(f) => { flags = flags + [f.flag_name] },
        None    => match find_opt_short(spec.app_options, s) {
          Some(o) => if length(remaining) == 0 { error = "option -{s} requires a value" }
                     else { options = options + [(o.opt_name, remaining[0])]; remaining = drop(remaining, 1) },
          None    => { error = "unknown option: -{s}" }
        }
      }
    }
    else {
      match find_command(spec.app_commands, a) {
        Some(_) => { subcmd = a; sub_args = remaining; remaining = [] },
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

fun cli_parse_args(spec: CliSpec, args: list<string>) {
  let raw = parse_loop(spec, args)
  let error = raw.raw_error
  let flags = raw.raw_flags
  let options = raw.raw_options
  let positionals = raw.raw_positionals
  let subcmd = raw.raw_subcmd
  let sub_args = raw.raw_sub_args

  if !is_empty(error) { Err(error) }
  else {
    let final_options = apply_defaults(spec, options)
    let req_err = check_required_args(spec, positionals)
    if !is_empty(req_err) { Err(req_err) }
    else if !is_empty(subcmd) {
      match find_command(spec.app_commands, subcmd) {
        Some(pair) => match cli_parse_args(pair.1, sub_args) {
          Ok(sub) => Ok(CliResult {
            cli_flags: flags,
            cli_options: final_options,
            cli_positionals: positionals,
            cli_command: subcmd,
            cli_sub: Some(sub)
          }),
          Err(e) => Err(e)
        },
        None => Err("unknown command: " + subcmd)
      }
    }
    else {
      Ok(CliResult {
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

fun cli_parse(spec) =>
  cli_parse_args(spec, get_args())

fun cli_parse_or_exit(spec) =>
  match cli_parse(spec) {
    Ok(r)               => r,
    Err("__help__")     => { println(cli_help(spec)); cli_empty() },
    Err("__version__")  => { println(cli_version_str(spec)); cli_empty() },
    Err(msg)            => { eprintln("error: {msg}"); eprintln("try --help for usage"); cli_empty() }
  }
