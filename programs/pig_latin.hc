// Pig Latin
//
// Translates English text into Pig Latin.
//
// Rules:
//   - Words starting with a vowel: add "yay"          (elephant → elephantyay)
//   - Words starting with consonants: move the
//     leading consonant cluster to the end + "ay"     (pig → igpay, string → ingstray)
//   - Words with no vowels at all: add "ay"            (gym → gymay)
//
// Usage: hica run programs/pig_latin.hc

fun is_vowel(c: string) : bool =>
  contains("aeiouAEIOU", c)

fun consonant_prefix_len(chars: list<string>) : int =>
  match chars {
    [] => 0,
    [h, ..rest] =>
      if is_vowel(h) { 0 }
      else { 1 + consonant_prefix_len(rest) }
  }

fun pig_latin_word(word: string) : string {
  let n = str_length(word)
  if n == 0 { word }
  else if is_vowel(word[:1]) { word + "yay" }
  else {
    let idx = consonant_prefix_len(split(word, ""))
    if idx == n { word + "ay" }
    else { word[idx:] + word[:idx] + "ay" }
  }
}

fun pig_latin(text: string) : string =>
  join(map(words(text), (w) => pig_latin_word(w)), " ")

fun main() {
  println("Pig Latin Translator")
  println("--------------------")
  let line = input("Enter your message: ")
  let msg = trim(line)
  if str_length(msg) == 0 {
    println("(empty message)")
  } else {
    println(pig_latin(msg))
  }
}

test "vowel-initial word gets yay suffix" {
  assert_eq(pig_latin_word("elephant"), "elephantyay")
}

test "vowel-initial word umbrella" {
  assert_eq(pig_latin_word("umbrella"), "umbrellayay")
}

test "single consonant moves to end" {
  assert_eq(pig_latin_word("pig"), "igpay")
}

test "consonant cluster moves to end" {
  assert_eq(pig_latin_word("latin"), "atinlay")
}

test "multi-consonant cluster" {
  assert_eq(pig_latin_word("string"), "ingstray")
}

test "word with no vowels gets ay" {
  assert_eq(pig_latin_word("gym"), "gymay")
}

test "full phrase" {
  assert_eq(pig_latin("pig latin"), "igpay atinlay")
}

test "vowel phrase" {
  assert_eq(pig_latin("elephant umbrella"), "elephantyay umbrellayay")
}
