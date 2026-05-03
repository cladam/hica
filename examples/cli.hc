// A mini CLI tool built with hica
//
// Usage:
//   ./hica run examples/cli.hc -- greet Claudio
//   ./hica run examples/cli.hc -- upper "hello world"
//   ./hica run examples/cli.hc -- count "one two three four"
//   ./hica run examples/cli.hc -- calc add 10 3
//   ./hica run examples/cli.hc -- calc mul 7 6
//   ./hica run examples/cli.hc -- env HOME
//
// Or build and run directly:
//   ./hica build examples/cli.hc && ./examples/cli greet Claudio

struct Config { 
    command: string, 
    rest: list<string> 
}

fun parse_config(input: list<string>) =>
  if length(input) == 0 { Err("no command given. try: greet, upper, count, calc, env") }
  else { Ok(Config { command: input[0], rest: drop(input, 1) }) }

fun cmd_greet(args: list<string>) =>
  if length(args) != 1 { Err("usage: greet <name>") }
  else { Ok("Hello, {args[0]}!") }

fun cmd_upper(args: list<string>) =>
  if length(args) == 0 { Err("usage: upper <text>") }
  else { Ok(to_upper(join(args, " "))) }

fun cmd_count(args: list<string>) =>
  if length(args) == 0 { Err("usage: count <text>") }
  else { Ok("{length(split(join(args, " "), " "))} word(s)") }

fun do_calc(op: string, a: int, b: int) =>
  match op {
    "add" => Ok(show(a + b)),
    "sub" => Ok(show(a - b)),
    "mul" => Ok(show(a * b)),
    "div" => if b == 0 { Err("division by zero") }
             else { Ok(show(a / b)) },
    _     => Err("unknown op: {op}. try: add, sub, mul, div")
  }

fun cmd_calc(args: list<string>) =>
  if length(args) != 3 { Err("usage: calc <op> <a> <b>") }
  else { do_calc(args[0], to_int(args[1]), to_int(args[2])) }

fun cmd_env(args: list<string>) =>
  if length(args) != 1 { Err("usage: env <KEY>") }
  else {
    match get_env(args[0]) {
      Some(v) => Ok(v),
      None    => Err("not set")
    }
  }

fun dispatch(cfg: Config) =>
  match cfg.command {
    "greet" => cmd_greet(cfg.rest),
    "upper" => cmd_upper(cfg.rest),
    "count" => cmd_count(cfg.rest),
    "calc"  => cmd_calc(cfg.rest),
    "env"   => cmd_env(cfg.rest),
    _       => Err("unknown command: '{cfg.command}'")
  }

fun run(input: list<string>) =>
  match parse_config(input) {
    Err(msg) => "error: {msg}",
    Ok(cfg)  => match dispatch(cfg) {
      Ok(output) => output,
      Err(msg)   => "error: {msg}"
    }
  }

fun main() {
  println(run(get_args()))
}
