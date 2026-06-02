// Hoh-e-joj! This is the Robber Language – rövarspråket
// Translates text into Robber language
//
// The robber language is probably the most famous language game in Sweden.
// The rules are simple so it can be spoken fluently with a little practice:
//   Simply add an "o" after each consonant in every word and then repeat that
//   very same consonant again before moving on to the next letter. I.e.
//   "Hello" becomes "Hohelollolo" in robber language!
//
// Usage: hica run programs/robber_language.hc

//function translateToRobber(text) {
//  var consonants = ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'z'];
//  var result = '';
//
//  for (i = 0; i < text.length; ++i) {
//    let char = text[i];
//    result += char;
//
//    if (consonants.includes(char.toLowerCase())) {
//      result += 'o' + char.toLowerCase();
//    }
//  }
//  return result;
//}

fun is_consonant(c: string) : bool =>
  contains("bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ", c)

// Each consonant c becomes c + "o" + lowercase(c); vowels and other chars are unchanged.
fun robber_char(c: string) : string =>
  if is_consonant(c) { c + "o" + to_lower(c) }
  else { c }

fun robber_word(word: string) : string =>
  join(map(split(word, ""), robber_char), "")

fun robber_language(text: string) : string =>
  join(map(words(text), robber_word), " ")

fun main() {
  println("Robber Language Translator – Rövarspråket")
  println("------------------------------------------")
  let line = input("Enter your message: ")
  let msg = trim(line)
  if str_length(msg) == 0 {
    println("(empty message)")
  } else {
    println(robber_language(msg))
  }
}

test "simple consonant doubled" {
  assert_eq(robber_word("b"), "bob")
}

test "Hello becomes Hohelollolo" {
  assert_eq(robber_word("Hello"), "Hohelollolo")
}

test "vowel-only word unchanged" {
  assert_eq(robber_word("ai"), "ai")
}

test "empty word unchanged" {
  assert_eq(robber_word(""), "")
}

test "Swedish hej becomes hohejoj" {
  assert_eq(robber_word("hej"), "hohejoj")
}

test "uppercase consonant preserved, repeat is lowercase" {
  assert_eq(robber_word("Hej"), "Hohejoj")
}

test "full phrase" {
  assert_eq(robber_language("hej hej"), "hohejoj hohejoj")
}
