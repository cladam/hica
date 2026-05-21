# Level 30. Random Numbers: Roll the Dice!

What if your program could surprise you? With `random`, it can! The `random`
function picks a number for you — a different one each time you run the
program.

### Rolling a die

`random(min, max)` gives you a random integer. Both numbers are included —
so `random(1, 6)` can give you 1, 2, 3, 4, 5, or 6. To roll a six-sided die:

```hica
fun main() {
  let die = random(1, 6)
  println("You rolled a {die}!")
}
```

This works just like `for i in 1..6` — both ends are included. Simple!

| Call | Possible results |
| --- | --- |
| `random(1, 6)` | 1, 2, 3, 4, 5, or 6 |
| `random(0, 1)` | 0 or 1 (coin flip!) |
| `random(1, 100)` | 1 through 100 |

**🎯 Try it:** Run the die program several times — you'll get a different
number each time!

### Coin flip

A coin has two sides. Use `random(0, 1)` to pick between them:

```hica
fun main() {
  let flip = random(0, 1)
  if flip == 0 { println("Heads!") }
  else { println("Tails!") }
}
```

### Rolling many dice

Combine `random` with a loop to roll several dice:

```hica
fun main() {
  var total = 0
  for i in 1..3 {
    let roll = random(1, 6)
    println("Die {i}: {roll}")
    total = total + roll
  }
  println("Total: {total}")
}
```

This rolls 3 dice, prints each one, and adds them up — just like a board
game!

### A real guessing game!

Remember the guessing game in level 29? The secret number was hard-coded.
Now we can make it truly random:

```hica
fun main() {
  let secret = random(1, 10)
  println("I picked a number between 1 and 10...")
  let guess_str = input("Your guess: ")
  match parse_int(guess_str) {
    Some(n) if n == secret => println("You got it!"),
    Some(n) if n < secret  => println("Too low! It was {secret}"),
    Some(n)                => println("Too high! It was {secret}"),
    None                   => println("That's not a number!")
  }
}
```

Every time you play, the answer is different. Now it's a *real* game!

### Random choices

You can use `random` to pick a random item from a list by generating a
random index:

```hica
fun main() {
  let snacks = ["apple", "banana", "cookie", "donut"]
  let pick = random(0, length(snacks) - 1)
  println("Today's snack: {snacks[pick]}")
}
```

**🎯 Try it:** Make a list of 5 activities ("read", "draw", "code", etc.)
and have the computer pick one at random. Run it a few times!

**🎯 Challenge:** Write a rock-paper-scissors game. The computer picks
randomly (0 = rock, 1 = paper, 2 = scissors), and the player types their
choice. Use `match` to decide who wins!

