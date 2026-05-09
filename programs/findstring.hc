// Exercise: findstring
// Adapted from USI Systems Programming (Carzaniga, 2017)
//
// Search a file for one or more strings passed as command-line arguments.
// Prints which strings were found and which were not.
//
// Usage: hica run programs/findstring.hc -- <file> <string1> [string2 ...]
//
// In C this requires reading a stream in chunks, handling buffer
// boundaries, and manual string matching (~80 lines).
// In hica it's read + contains for each needle.

fun make_spec() =>
  cli("findstring", "1.0.0", "search a file for strings")
    |> arg("file", "file to search", true)
    |> arg("strings", "strings to find (one or more)", true)

fun find_matches(text: string, needles: list<string>) : (list<string>, list<string>) =>
  (needles.filter((n) => contains(text, n)),
   needles.filter((n) => not_(contains(text, n))))

fun search(file: string, needles: list<string>) {
  let text = read_file(file) |> unwrap
  let (found, missing) = find_matches(text, needles)
  found.foreach((n) => println("found: {n}"))
  missing.foreach((n) => println("NOT found: {n}"))
  if length(missing) == 0 { println("all strings found") }
  else { println("some strings missing") }
}

fun main() {
  let spec = make_spec()
  match cli_parse(spec) {
    Err("__help__")    => println(cli_help(spec)),
    Err("__version__") => println(cli_version_str(spec)),
    Err(msg)           => eprintln("error: {msg}"),
    Ok(r)              => search(r.cli_positionals[0], r.cli_positionals[1:])
  }
}

test "finds matching needles" {
  let (found, missing) = find_matches("hello world", ["hello", "xyz"])
  assert_eq(length(found), 1)
  assert_eq(length(missing), 1)
  assert_contains(found, "hello")
  assert_contains(missing, "xyz")
}

test "all needles found" {
  let (found, missing) = find_matches("hello world", ["hello", "world"])
  assert_eq(length(found), 2)
  assert_eq(length(missing), 0)
}