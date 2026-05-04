// Test the cli prelude with all new features:
// pipe-friendly builders, subcommands, defaults, positional args
//
// Usage:
//   ./hica run examples/cli-prelude.hc -- --help
//   ./hica run examples/cli-prelude.hc -- --verbose --output out.txt hello World
//   ./hica run examples/cli-prelude.hc -- -f csv data.txt
//   ./hica run examples/cli-prelude.hc -- check --strict src/

fun make_check_spec() =>
  cli("myapp check", "1.0.0", "run checks on a path")
    |> flag("strict", "s", "enable strict mode")
    |> arg("path", "path to check", true)

fun make_spec() =>
  cli("myapp", "1.0.0", "a demo CLI app")
    |> flag("verbose", "v", "enable verbose output")
    |> option("output", "o", "output file")
    |> option_default("format", "f", "output format", "json")
    |> arg("input", "input file", false)
    |> command("check", make_check_spec())

fun main() {
  let spec = make_spec()
  match cli_parse(spec) {
    Err("__help__")    => println(cli_help(spec)),
    Err("__version__") => println(cli_version_str(spec)),
    Err(msg)           => eprintln("error: {msg}"),
    Ok(r)              => {
      println("flags: {show(r.cli_flags)}")
      println("options: {show(r.cli_options)}")
      println("positionals: {show(r.cli_positionals)}")
      println("command: {r.cli_command}")
      if has_flag(r, "verbose") { println("verbose mode is ON") }
      println("format = {get_opt_or(r, "format", "???")}")
      match get_sub(r) {
        Some(sub) => {
          println("subcommand result:")
          println("  sub flags: {show(sub.cli_flags)}")
          println("  sub positionals: {show(sub.cli_positionals)}")
        },
        None => println("no subcommand")
      }
    }
  }
}
