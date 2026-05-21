# Level 35. Pattern Matching with Globs: The Treasure Map

Imagine you have a treasure map, and you're looking for files that match a
pattern — like "all the text files" or "any picture in any folder". That's what
**glob matching** does!

Hica has built-in functions for this, plus helpers that tell you what kind of
character you're looking at.

### What Kind of Character Is It?

Every character has a type. Hica can check it for you:

```hica
fun main() {
  // Is it a digit? (0-9)
  println(is_digit(chr(48)))    // true  — that's '0'
  println(is_digit(chr(65)))    // false — that's 'A'

  // Is it a letter? (a-z or A-Z)
  println(is_alpha(chr(65)))    // true  — 'A'
  println(is_alpha(chr(48)))    // false — '0'

  // Is it uppercase or lowercase?
  println(is_upper(chr(65)))    // true  — 'A'
  println(is_lower(chr(97)))    // true  — 'a'
}
```

You can also check whole strings at once:

```hica
fun main() {
  println(all_digits("12345"))   // true  — every character is a digit
  println(all_digits("123a5"))   // false — 'a' is not a digit!
  println(all_upper("HELLO"))    // true
  println(all_lower("hello"))    // true
}
```

> **Think of it like sorting mail:** "Is every letter in this word uppercase?"
> `all_upper` checks the whole word for you!

### Glob Patterns: Wildcards!

A **glob pattern** is like a search with wildcards:

- `*` means "any characters" (but not across folders)
- `?` means "exactly one character"

```hica
fun main() {
  // * matches anything
  println(glob_match("*.txt", "readme.txt"))    // true
  println(glob_match("*.txt", "photo.png"))     // false

  // ? matches exactly one letter
  println(glob_match("h?llo", "hello"))         // true
  println(glob_match("h?llo", "hallo"))         // true
  println(glob_match("h?llo", "hllo"))          // false — ? needs one character!
}
```

### Path Globs: The Double Star `**`

When searching through folders, `**` means "any number of folders deep":

```hica
fun main() {
  // ** matches folders at any depth
  println(glob_match_path("**/*.txt", "file.txt"))            // true
  println(glob_match_path("**/*.txt", "docs/notes.txt"))      // true
  println(glob_match_path("**/*.txt", "a/b/c/deep.txt"))      // true

  // Combine with folder prefixes
  println(glob_match_path("src/**/*.hc", "src/lib/util.hc"))  // true
  println(glob_match_path("src/**/*.hc", "test/main.hc"))     // false — wrong folder!
}
```

> **Think of `*` as "look on this shelf" and `**` as "search the whole library!"**

### Challenge

Write a program that checks if a filename is a "safe name" — only letters,
digits, a dot, and `.txt` or `.hc` at the end. Use `is_alnum`, `glob_match`,
and `chars` together!

---
