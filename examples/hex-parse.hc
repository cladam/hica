// Hex parsing: convert hex strings to integers using recursion
// Demonstrates: recursion, pattern matching, result type, char_to_string, chr

fun hex_digit_val(c: string) : result<int, string> {
  if c == "0" { Ok(0) } else if c == "1" { Ok(1) } else if c == "2" { Ok(2) }
  else if c == "3" { Ok(3) } else if c == "4" { Ok(4) } else if c == "5" { Ok(5) }
  else if c == "6" { Ok(6) } else if c == "7" { Ok(7) } else if c == "8" { Ok(8) }
  else if c == "9" { Ok(9) } else if c == "a" || c == "A" { Ok(10) }
  else if c == "b" || c == "B" { Ok(11) } else if c == "c" || c == "C" { Ok(12) }
  else if c == "d" || c == "D" { Ok(13) } else if c == "e" || c == "E" { Ok(14) }
  else if c == "f" || c == "F" { Ok(15) }
  else { Err("invalid hex digit: " + c) }
}

fun parse_hex(s: string, pos: int, acc: int) : result<int, string> {
  if pos >= str_length(s) { Ok(acc) }
  else {
    let c = s[pos: pos + 1]
    match hex_digit_val(c) {
      Err(e) => Err(e),
      Ok(v) => parse_hex(s, pos + 1, acc * 16 + v)
    }
  }
}

fun hex_to_int(s: string) : result<int, string> =>
  if str_length(s) == 0 { Err("empty hex string") }
  else { parse_hex(s, 0, 0) }

fun show_result(r: result<int, string>) : string {
  match r {
    Ok(v) => show(v),
    Err(e) => "error: " + e
  }
}

fun main() {
  // Parse hex strings to integers
  println("ff   -> " + show_result(hex_to_int("ff")))     // 255
  println("1A   -> " + show_result(hex_to_int("1A")))     // 26
  println("0    -> " + show_result(hex_to_int("0")))      // 0
  println("CAFE -> " + show_result(hex_to_int("CAFE")))   // 51966
  println("zz   -> " + show_result(hex_to_int("zz")))     // error: ...

  // Use hex to look up unicode characters
  println("")
  println("Unicode from hex:")
  match hex_to_int("41") {
    Ok(cp) => println("41    -> " + char_to_string(chr(cp))),
    Err(_) => println("error")
  }
  match hex_to_int("2713") {
    Ok(cp) => println("2713  -> " + char_to_string(chr(cp))),
    Err(_) => println("error")
  }
  match hex_to_int("1F600") {
    Ok(cp) => println("1F600 -> " + char_to_string(chr(cp))),
    Err(_) => println("error")
  }
}
