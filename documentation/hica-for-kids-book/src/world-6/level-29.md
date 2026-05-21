# Level 29. Asking for Input

So far, your programs have been one-way conversations — the computer talks,
but you can't talk back. Let's change that! The `input` function prints a
question and waits for the user to type an answer.

```hica
fun main() {
  let name = input("What is your name? ")
  println("Hello, " + name + "!")
}
```

When you run this, the computer prints the prompt, then **waits**. You type
your answer, press Enter, and the program continues with whatever you typed.

### Reading numbers

`input` always gives you a **string**. If you want a number, use `parse_int`
or `parse_float` to convert it — and `match` to handle the case where the
user types something that isn't a number:

```hica
fun main() {
  let age_str = input("How old are you? ")
  match parse_int(age_str) {
    Some(age) => println("In 10 years you'll be {age + 10}"),
    None      => println("That's not a number!")
  }
}
```

### A guessing game!

Combine `input`, `parse_int`, and match guards for a mini game:

```hica
fun main() {
  let secret = 7
  println("I'm thinking of a number between 1 and 10...")
  let guess_str = input("Your guess: ")
  match parse_int(guess_str) {
    Some(n) if n == secret => println("Correct!"),
    Some(_)               => println("Wrong! It was {secret}"),
    None                  => println("Please enter a number!")
  }
}
```

Notice how we use a **match guard** (`if n == secret`) — that's the pattern
matching trick from level 11!

**🎯 Try it:** Write a program that asks for your name and your favourite
colour, then prints `"Hi ___, your favourite colour is ___!"`.

**🎯 Challenge:** Make a simple calculator: ask for two numbers and an
operator (`+`, `-`, `*`, `/`), then print the result. Use `match` on the
operator string!

