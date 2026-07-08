# Level 21. Lists: Collections of Things

What if you have a whole bunch of values. Not just two or three, but five,
ten, or even a hundred? That's what **lists** are for.

A list is like a row of boxes, all holding the same kind of thing.

### Making a list

Wrap values in square brackets, separated by commas:

```hica
let nums = [1, 2, 3, 4, 5]
let words = ["hello", "hej", "hola"]
```

### The empty list

A list with nothing in it:

```hica
let nothing = []
```

### The golden rule: same type!

Every item in a list must be the same type. You can't mix numbers and strings:

```hica
[1, 2, 3]          // ✅ all ints
["a", "b", "c"]    // ✅ all strings
[1, "hello"]       // ❌ type error!
```

This is different from tuples, which *can* hold different types.

### Lists vs Tuples: what's the difference?

| | Tuple | List |
| --- | --- | --- |
| Syntax | `(1, "hi")` | `[1, 2, 3]` |
| Types | Can mix types | All same type |
| Size | Fixed (you know how many) | Any length |
| Use | Bundle a few related values | Collect many values |

### Doing things with lists

hica gives you three super-powers for working with lists:

**`map`. Transform every element**

```hica
let nums = [1, 2, 3]
let doubled = map(nums, (x) => x * 2)
println(doubled)   // [2, 4, 6]
```

Think of `map` like a machine: each item goes in one side, gets changed, and
comes out the other side.

**`filter`. Keep only the ones you want**

```hica
let nums = [1, 2, 3, 4, 5]
let big = filter(nums, (x) => x > 3)
println(big)   // [4, 5]
```

`filter` checks each item: "Does this pass the test?" If yes, it stays.
If no, it's gone.

**`fold`. Combine everything into one value**

```hica
let nums = [1, 2, 3, 4]
let total = fold(nums, 0, (acc, x) => acc + x)
println(total)   // 10
```

`fold` is like a snowball rolling downhill. It starts with an initial value
(here `0`), and adds each element one at a time: `0 + 1 = 1`, `1 + 2 = 3`,
`3 + 3 = 6`, `6 + 4 = 10`.

**🎯 Try it:** Use `map` to add 100 to every number in `[1, 2, 3]`.

**🎯 Try it:** Use `filter` to keep only even numbers from `[1, 2, 3, 4, 5, 6]`.
(Hint: `x % 2 == 0` tests if a number is even.)

### More list tools

hica has a few more handy tools for lists:

**`length`: how many items?**

```hica
let nums = [10, 20, 30]
println(length(nums))   // 3
```

Like counting the boxes in a row.

**`reverse`. Flip the order**

```hica
let nums = [1, 2, 3]
println(reverse(nums))   // [3, 2, 1]
```

Like reading a list backwards!

**`cons`. Add something to the front**

```hica
let nums = [2, 3, 4]
println(cons(1, nums))   // [1, 2, 3, 4]
```

`cons` is super fast, like putting a new box at the start of the row.
If you want to add to the *end* instead, use `+`:

```hica
let nums = [1, 2, 3]
println(nums + [4])   // [1, 2, 3, 4]
```

Adding to the end is slower because the computer has to walk the whole row
first. For most programs it doesn't matter, but if speed is important,
`cons` is the way to go!

**`for x in list`. Do something with each item**

The nicest way to walk through a list is with a `for` loop:

```hica
let names = ["Kalle", "Lisa", "Olle"]
for name in names {
  println("Hi, {name}!")
}
```

This prints:
```
Hi, Kalle!
Hi, Lisa!
Hi, Olle!
```

You can also use the function form: `foreach(names, (name) => println(name))`

`for x in list` is like walking down the row of boxes and doing something at each
one. It's similar to `map`, but you use it when you want to *do* something
(like print) rather than *transform* the values.

**🎯 Try it:** Use `reverse` on `["a", "b", "c"]`: what do you get?

**🎯 Try it:** Use `for` to print each number in `[10, 20, 30]`
multiplied by 5.

### Even more list tools

Here are a few more useful list functions:

**`head` and `last`. Peek at the ends**

```hica
fun main() {
  let nums = [10, 20, 30]
  println(head(nums))   // Some(10)
  println(last(nums))   // Some(30)
  println(head([]))     // None — nothing there!
}
```

`head` gives you the first item, `last` gives you the last. They return
`Some(...)` or `None` because the list might be empty.

**`tail`. Everything except the first**

```hica
println(tail([1, 2, 3]))   // [2, 3]
```

**`sum`. Add them all up**

```hica
println(sum([1, 2, 3, 4, 5]))   // 15
```

No need to write `fold` for the most common case!

**`sort_by`. Put things in order**

```hica
let messy = [3, 1, 4, 1, 5, 9]
let tidy = sort_by(messy, (a, b) => a <= b)
println(tidy)   // [1, 1, 3, 4, 5, 9]
```

You give `sort_by` a comparison function. It returns `true` when the first
value should come before the second. Flip it to sort the other way:

```hica
let biggest_first = sort_by(messy, (a, b) => a >= b)
println(biggest_first)   // [9, 5, 4, 3, 1, 1]
```

**`unique`. Remove repeats**

```hica
println(unique([1, 2, 3, 2, 1]))   // [1, 2, 3]
```

**🎯 Try it:** Sort `[5, 2, 8, 1, 9]` from smallest to biggest, then
print just the first element using `head`.

