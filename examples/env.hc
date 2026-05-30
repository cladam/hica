// Environment helpers: get_args(), get_env(), set_env(), eprintln
// and std/dotenv for .env file loading
//
// Run with:  ./hica run examples/env.hc -- hello world

fun main() {
  // Command-line arguments
  let args = get_args()
  println("args: {args}")

  // Environment variable lookup
  match get_env("HOME") {
    Some(dir) => println("HOME = {dir}"),
    None      => eprintln("HOME is not set")
  }

  // Set an environment variable (overwrites existing)
  set_env("MY_APP_ENV", "production")
  match get_env("MY_APP_ENV") {
    Some(v) => println("MY_APP_ENV = {v}"),
    None    => println("MY_APP_ENV = (not set)")
  }

  // Load a .env file into the environment (skips already-set vars).
  // Uncomment and import "std/dotenv" to use:
  // dotenv_load(".env")

  // eprintln writes to stderr
  eprintln("this goes to stderr")
}
