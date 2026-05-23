// Demo of the cli prelude: pipe-friendly builders, subcommands,
// combined short flags, typed options, positional access, and defaults.
//
// Usage:
//   ./hica run examples/cli-prelude.hc -- --help
//   ./hica run examples/cli-prelude.hc -- --verbose --output out.txt data.txt
//   ./hica run examples/cli-prelude.hc -- -vf csv data.txt
//   ./hica run examples/cli-prelude.hc -- -vo out.txt data.txt
//   ./hica run examples/cli-prelude.hc -- check --strict src/

import "std/cli"

fun make_check_spec() =>
  cli("myapp check", "1.0.0", "run checks on a path")
    |> flag("strict", "s", "enable strict mode")
    |> arg("path", "path to check", true)

fun make_spec() =>
  cli("myapp", "1.0.0", "a demo CLI app")
    |> flag("verbose", "v", "enable verbose output")
    |> option("output", "o", "output file")
    |> option_default("format", "f", "output format", "json")
    |> option("count", "n", "repeat count")
    |> arg("input", "input file", false)
    |> command("check", make_check_spec())

fun main() {
  let spec = make_spec()
  match cli_parse(spec) {
    Help          => println(cli_help(spec)),
    Version       => println(cli_version_str(spec)),
    CliError(msg) => eprintln("error: {msg}"),
    Parsed(r)     => {
      if has_flag(r, "verbose") { println("verbose mode is ON") }
      let fmt = get_opt_or(r, "format", "???")
      let count = get_opt_int_or(r, "count", 1)
      println("format = {fmt}")
      println("count  = {show(count)}")
      match get_opt(r, "output") {
        Some(out) => println("output = {out}"),
        None      => println("output = (stdout)")
      }
      match get_positional(r, 0) {
        Some(input) => println("input  = {input}"),
        None        => println("input  = (none)")
      }
      match get_sub(r) {
        Some(sub) => {
          println("subcommand: {get_command(r)}")
          if has_flag(sub, "strict") { println("  strict mode") }
          println("  path: {show(get_positionals(sub))}")
        },
        None => println("")
      }
    }
  }
}
