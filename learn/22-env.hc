// ============================================================
// Lesson 22: Environment
// ============================================================
//
// hica can interact with the outside world:
//
//   get_args()      — command-line arguments (list<string>)
//   get_env(key)    — environment variable lookup (maybe<string>)
//   eprintln(msg)   — print to stderr
//
// These are the building blocks for CLI tools and scripts.
//
// ============================================================

fun main() {
  // Command-line arguments
  let args = get_args()
  println("arguments: {args}")

  // Look up an environment variable
  match get_env("HOME") {
    Some(dir) => println("HOME = {dir}"),
    None      => println("HOME is not set")
  }

  // eprintln writes to stderr (useful for error messages)
  eprintln("this goes to stderr, not stdout")
}
