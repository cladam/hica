// 26 – File I/O
//
// hica can read and write files. The functions are available everywhere,
// no imports needed.
//
// read_file returns a result — use unwrap for quick scripts,
// or match on Ok/Err for proper error handling.
//
// Run: ./hica run learn/26-file-io.hc

fun main() {
  // --- Writing a file ---
  write_file("hello.txt", "Hello from hica!\nSecond line.\n")
  println("Wrote hello.txt")

  // --- Reading a file with unwrap ---
  // unwrap extracts the Ok value, or throws on Err
  let content = read_file("hello.txt") |> unwrap
  println("Content:")
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

// Expected output:
// Wrote hello.txt
// Content:
// Hello from hica!
// Second line.
//
// Hi, Kalle!
// Hi, Olle!
// Hi, Lisa!
// Could not read: unable to read text file "missing.txt": No such file or directory
// fallback content
// Got 3 lines

// Challenge: write a program that reads a file, counts the number of
// non-empty lines, and writes the count to another file.
