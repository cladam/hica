



fun main() {
    // Simple script — I don't care about errors
    let content = read_file("data.txt") |> unwrap

    // Robust code — handle the error
    match read_file("data.txt") {
    Ok(text) => process(text),
    Err(msg) => eprintln("Failed: {msg}")
    }

    // With a fallback
    let content = read_file("config.txt") |> unwrap_or("")
}


fun main() {
  // read_file now returns result
  match read_file("README.md") {
    Ok(text) => println("README has {length(lines(text))} lines"),
    Err(msg) => println("Error: {msg}")
  }

  // unwrap for quick scripts
  let content = read_file("README.md") |> unwrap
  println("First line: {lines(content)[0]}")

  // unwrap_or for defaults
  let data = read_file("nope.txt") |> unwrap_or("fallback content")
  println(data)

  // read_lines still works (uses unwrap internally)
  let ls = read_lines("README.md")
  println("Lines: {length(ls)}")

  // error case
  match read_file("missing.txt") {
    Ok(_) => println("unexpected"),
    Err(msg) => println("Caught: {msg}")
  }
}

fun main() {
  let x = read_file("nope.txt") |> unwrap
  println(x)
}