# Level 25. Recursion: The Russian Doll Trick

Imagine a Russian doll (matryoshka). You open it, and there's a smaller
identical doll inside. Open that one, and there's an even smaller one. You keep
going until you find the tiniest doll that doesn't open.

**Recursion** is when a function calls *itself*, like those nested dolls.

### How it works

Every recursive function needs exactly two things:

1. **A base case**. When to STOP (the tiniest doll that doesn't open)
2. **A recursive case**: how to make the problem SMALLER (opening the next doll)

### Factorial: the classic example

"5 factorial" means `5 × 4 × 3 × 2 × 1 = 120`. In code:

```hica
fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

fun main() {
  println(factorial(5))   // 120
}
```

Let's trace it like dolls:

```
factorial(5) = 5 × factorial(4)
             = 5 × 4 × factorial(3)
             = 5 × 4 × 3 × factorial(2)
             = 5 × 4 × 3 × 2 × factorial(1)
             = 5 × 4 × 3 × 2 × 1   ← base case! Stop here.
             = 120
```

- **Base case:** `n <= 1` → return `1` (the tiniest doll)
- **Recursive case:** `n * factorial(n - 1)` (open the next doll)

### Adding up: sum from 1 to n

```hica
fun sum_to(n) => if n <= 0 { 0 } else { n + sum_to(n - 1) }

fun main() {
  println(sum_to(10))   // 55
}
```

Think of it like stacking blocks: 10 + 9 + 8 + ... + 1 = 55.

### GCD: a clever recursion

The **Greatest Common Divisor** is the biggest number that divides two numbers
evenly. Euclid figured this out over 2000 years ago:

```hica
fun main() {
  println(gcd(12, 8))   // 4
}
```

hica has `gcd` built in! It works by repeatedly asking: "What's the remainder?"
until there's nothing left. That "nothing left" is the base case.

### The golden rule: always have a base case!

Without a base case, a recursive function would call itself forever, like
dolls that never end, or two mirrors facing each other. The program would
never finish!

```hica
// ❌ BAD — no base case!
// fun forever(n) => forever(n + 1)   // never stops!

// ✅ GOOD — has a base case
fun countdown(n) => if n <= 0 { 0 } else { countdown(n - 1) }
```

### When to use recursion?

Use recursion when a problem can be broken into **smaller copies of itself**:

- "Sum 1 to 100" = 100 + "Sum 1 to 99"
- "Factorial of 5" = 5 × "Factorial of 4"
- "GCD of 12 and 8" = "GCD of 8 and 4"

**🎯 Try it:** Write a `power(base, exp)` function:
- `power(2, 0)` → 1 (base case: anything to the power of 0 is 1)
- `power(2, 3)` → 8 (recursive: `2 * power(2, 2)`)

**🎯 Think:** What's `factorial(0)`? What about `sum_to(0)`?

### Mutual recursion: two functions that take turns

Sometimes two functions call **each other** instead of themselves. Imagine
two friends playing catch: each one throws the ball to the other until
someone decides to stop.

```hica
fun check_even(n) => if n == 0 { true } else { check_odd(n - 1) }

fun check_odd(n) => if n == 0 { false } else { check_even(n - 1) }
```

- `check_even(4)` calls `check_odd(3)`, which calls `check_even(2)`,
  which calls `check_odd(1)`, which calls `check_even(0)` → `true`!
- They keep bouncing back and forth, making the number smaller each time.

hica figures out that these functions call each other. You don't need to
do anything special.

**🎯 Try it:** Trace `check_odd(3)` on paper. What does each call look like?

