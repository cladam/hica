// ============================================================
// Lesson 27: User Input
// ============================================================
//
// `input(prompt)` prints the prompt and reads a line from the
// user. It returns a `string`.
//
//   let name = input("What is your name? ")
//   println("Hello, " + name)
//
// For numbers, combine input with `parse_int` or `parse_float`:
//
//   match parse_int(input("Age: ")) {
//     Some(n) => println("You are {n}"),
//     None    => println("Not a number!")
//   }
//
// ============================================================

fun greet() {
  let name = input("What is your name? ")
  println("Hello, " + name + "!")
}

fun ask_age() {
  let age_str = input("How old are you? ")
  match parse_int(age_str) {
    Some(age) => println("In 10 years you'll be {age + 10}"),
    None      => println("That's not a number!")
  }
}

fun guess_game() {
  let secret = 7
  println("I'm thinking of a number between 1 and 10...")
  let guess_str = input("Your guess: ")
  match parse_int(guess_str) {
    Some(n) if n == secret => println("Correct!"),
    Some(_)               => println("Wrong! It was {secret}"),
    None                  => println("Please enter a number!")
  }
}

fun main() {
  greet()
  ask_age()
  guess_game()
}

// ============================================================
// Expected interaction:
//   What is your name? Ada
//   Hello, Ada!
//   How old are you? 12
//   In 10 years you'll be 22
//   I'm thinking of a number between 1 and 10...
//   Your guess: 7
//   Correct!
//
// Challenge: Write a simple calculator that asks the user for
// two numbers and an operator (+, -, *), then prints the result.
// ============================================================
