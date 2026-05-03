// Hica — Characters
//
// Characters use single quotes: 'a', 'Z', '!', '7'
// Strings use double quotes: "hello"
//
// A char is a single character — one letter, digit, or symbol.

// Characters work in lists
fun vowels() => ['a', 'e', 'i', 'o', 'u']

// You can compare characters
fun is_vowel(c) => c in vowels()

fun main() {
  let letter = 'h'
  println(letter)

  // Chars in string interpolation
  println("the letter is: {letter}")

  // A list of characters
  let letters = ['h', 'i', 'c', 'a']
  println(letters)

  // Check equality
  println('a' == 'a')
  println('a' == 'b')

  // Check membership
  println(is_vowel('e'))
  println(is_vowel('z'))
}
