fun main() {
  // --- Writing a file ---
  write_file("hello.txt", "Hello from hica!\nSecond line.\n")
  println("Wrote hello.txt")

  // --- Reading a file with unwrap ---
  // unwrap extracts the Ok value, or throws on Err
  let content = read_file("hello.txt") |> unwrap
  println("Content:")
  println(content)

   // --- Reading a file without unwrap will also workif the file exists ---
  let content = read_file("hej.txt")
  //  but will fail and throw if the file missing
  // Left("unable to read text file \"hej.txt\": No such file or directory")
  println(content)

  // --- Line-oriented I/O ---
  write_lines("names.txt", ["Kalle", "Olle", "Lisa"])
  let names = read_lines("names.txt")
  for name in names {
    if not_(is_empty(name)) {
      println("Hi, {name}!")
    }
  }

  // --- Error handling with match ---
  match read_file("missing.txt") {
    Ok(text) => println(text),
    Err(msg) => println("Could not read: {msg}")
  }

  // --- Fallback with unwrap_or ---
  let data = read_file("missing.txt") |> unwrap_or("fallback content")
  println(data)

  // --- Counting lines ---
  match read_file("hello.txt") {
    Ok(text) => println("Got {length(lines(text))} lines"),
    Err(msg) => println("Error: {msg}")
  }
}