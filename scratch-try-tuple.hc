pub fun peek(s: string, pos: int) : string { s[pos:pos+1] }

pub fun parse_key(s: string, pos: int) : result<(string, int), string> {
  if pos >= str_length(s) { Err("eof") }
  else { Ok((peek(s, pos), pos + 1)) }
}

// Recursive, uses `?` — seeds the hica-early-result group.
pub fun parse_key_path(s: string, pos: int) : result<(list<string>, int), string> {
  let (key, p2) = parse_key(s, pos)?
  if peek(s, p2) == "." {
    let (rest, p3) = parse_key_path(s, p2 + 1)?
    Ok(([key] + rest, p3))
  }
  else { Ok(([key], p2)) }
}

// Recursive, returns a plain tuple, and calls the `?`-using parse_key_path.
// It is a one-directional caller (parse_key_path never calls back), so it must
// NOT be pulled into the early-result group.
pub fun collect_text_run(s: string, pos: int) : (list<string>, int) {
  if pos >= str_length(s) { ([], pos) }
  else {
    match parse_key_path(s, pos) {
      Ok((keys, p2)) => {
        let (rest, p3) = collect_text_run(s, p2)
        (keys + rest, p3)
      },
      Err(_) => ([], pos)
    }
  }
}

fun main() {
  let (texts, p) = collect_text_run("a.b.c", 0)
  match parse_key_path("a.b.c", 0) {
    Ok((keys, p2)) => println("ok"),
    Err(e) => println("err")
  }
}
