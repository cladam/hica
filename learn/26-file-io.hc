// 26 – File I/O
//
// hica can read and write files. The functions are available everywhere,
// no imports needed.
//
// Run: ./hica run learn/26-file-io.hc

fun main() {
  // --- Writing a file ---
  write_file("hello.txt", "Hello from hica!\nSecond line.\n")
  println("Wrote hello.txt")

  // --- Reading a file ---
  let content = read_file("hello.txt")
  println("Content:")
  println(content)

  // --- Line-oriented I/O ---
  write_lines("names.txt", ["Alice", "Bob", "Charlie"])
  let names = read_lines("names.txt")
  for name in names {
    if not_(is_empty(name)) {
      println("Hi, {name}!")
    }
  }

  // --- Safe reading with try_read_file ---
  // Returns Ok(content) or Err(message) instead of throwing
  match try_read_file("missing.txt") {
    Ok(text) => println(text),
    Err(msg) => println("Could not read: {msg}")
  }

  match try_read_file("hello.txt") {
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
// Hi, Alice!
// Hi, Bob!
// Hi, Charlie!
// Could not read: unable to read text file "missing.txt": No such file or directory
// Got 3 lines

// Challenge: write a program that reads a file, counts the number of
// non-empty lines, and writes the count to another file.
