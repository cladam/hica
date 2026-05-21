# Level 15. Counting Loops

What if you want to do something *and* know which round you're on?
That's what `for` is for!

```hica
fun main() {
  for i in 1..5 {
    println(i)
  }
}
```

This prints:
```
1
2
3
4
5
```

The variable `i` counts from the first number to the last number (both
included). Think of it as: *"for every number i from 1 to 5, do this."*

### The range `..`

The two dots `..` mean "from here to there":

| Range | Numbers you get |
| --- | --- |
| `0..4` | 0, 1, 2, 3, 4 |
| `1..3` | 1, 2, 3 |
| `1..100` | 1, 2, 3, ..., 100 |

### FizzBuzz with a for loop

Remember FizzBuzz? Now we can do the *real* version. Loop through all the
numbers!

```hica
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }

fun main() {
  for i in 1..100 {
    println(fizzbuzz(i))
  }
}
```

Notice `show(n)` in the last branch. It turns a number into a string
(so `show(7)` gives `"7"`). We need it because every branch must return the
same type, and the other branches already return strings.

That's only 10 lines of code and it prints all 100 fizzbuzz results!

### Using the loop variable

The loop variable is a regular integer. You can do math with it:

```hica
fun main() {
  for i in 1..5 {
    println(i * i)
  }
}
```

This prints the squares: 1, 4, 9, 16, 25.

**🎯 Try it:** Use a `for` loop to print the first 10 multiples of 7
(7, 14, 21, ...).

**🎯 Try it:** Print a countdown: `for i in 1..5 { println(6 - i) }`.
What numbers do you get?

