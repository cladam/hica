// Test the glob prelude: character classification and pattern matching

fun main() {
  // --- Character classification ---
  println("=== Character Classification ===")

  // is_digit
  assert(is_digit(chr(48)))    // '0'
  assert(is_digit(chr(57)))    // '9'
  assert(!is_digit(chr(65)))   // 'A'
  println("is_digit: ok")

  // is_upper / is_lower / is_alpha
  assert(is_upper(chr(65)))    // 'A'
  assert(is_upper(chr(90)))    // 'Z'
  assert(!is_upper(chr(97)))   // 'a'
  assert(is_lower(chr(97)))    // 'a'
  assert(is_lower(chr(122)))   // 'z'
  assert(is_alpha(chr(65)))
  assert(is_alpha(chr(97)))
  assert(!is_alpha(chr(48)))
  println("is_alpha/upper/lower: ok")

  // is_alnum
  assert(is_alnum(chr(65)))
  assert(is_alnum(chr(48)))
  assert(!is_alnum(chr(33)))   // '!'
  println("is_alnum: ok")

  // --- String-level helpers ---
  println("\n=== String Helpers ===")

  assert(all_digits("12345"))
  assert(!all_digits("123a5"))
  assert(!all_digits(""))
  println("all_digits: ok")

  assert(all_upper("HELLO"))
  assert(!all_upper("Hello"))
  assert(all_lower("hello"))
  assert(!all_lower("Hello"))
  assert(all_alpha("hello"))
  assert(!all_alpha("hello1"))
  println("all_upper/lower/alpha: ok")

  // --- Glob matching ---
  println("\n=== Glob Matching ===")

  // Exact match
  assert(glob_match("hello", "hello"))
  assert(!glob_match("hello", "world"))
  println("exact: ok")

  // ? matches single char
  assert(glob_match("h?llo", "hello"))
  assert(glob_match("h?llo", "hallo"))
  assert(!glob_match("h?llo", "hllo"))
  println("? pattern: ok")

  // * matches any chars
  assert(glob_match("*.txt", "readme.txt"))
  assert(glob_match("*.txt", ".txt"))
  assert(!glob_match("*.txt", "readme.md"))
  assert(glob_match("hello*", "hello"))
  assert(glob_match("hello*", "helloworld"))
  assert(glob_match("h*o", "hello"))
  assert(glob_match("h*o", "ho"))
  println("* pattern: ok")

  // * does not cross /
  assert(!glob_match("*.txt", "dir/file.txt"))
  println("* no slash: ok")

  // --- Path glob matching (with **) ---
  println("\n=== Path Glob Matching ===")

  // ** matches zero or more segments
  assert(glob_match_path("**/*.txt", "file.txt"))
  assert(glob_match_path("**/*.txt", "dir/file.txt"))
  assert(glob_match_path("**/*.txt", "a/b/c/file.txt"))
  assert(!glob_match_path("**/*.txt", "a/b/c/file.md"))
  println("** pattern: ok")

  // Directory prefix
  assert(glob_match_path("src/**/*.hc", "src/main.hc"))
  assert(glob_match_path("src/**/*.hc", "src/lib/util.hc"))
  assert(!glob_match_path("src/**/*.hc", "test/main.hc"))
  println("dir/**/file: ok")

  // Mixed * and **
  assert(glob_match_path("src/*/test_*.hc", "src/foo/test_bar.hc"))
  assert(!glob_match_path("src/*/test_*.hc", "src/a/b/test_bar.hc"))
  println("mixed patterns: ok")

  println("\nAll glob tests passed!")
}
