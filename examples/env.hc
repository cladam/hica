// Environment helpers: get_args(), get_env(), eprintln
//
// Run with:  ./hica run examples/env.hc -- hello world

fun main() {
  // Command-line arguments
  let args = get_args();
  println("args: {args}");

  // Environment variable lookup
  match get_env("HOME") {
    Some(dir) => println("HOME = {dir}"),
    None      => eprintln("HOME is not set")
  };

  // eprintln writes to stderr
  eprintln("this goes to stderr")
}
