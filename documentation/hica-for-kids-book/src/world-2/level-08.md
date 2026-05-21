# Level 8. Functions: Little Machines

A function is like a machine in a factory. You put something in, it does some
work, and something comes out.

Imagine a pizza-making process:

1. `prepare_dough()` — makes the base
2. `add_toppings()` — puts cheese on top
3. `bake()` — cooks it in the oven

Each step is its own little machine. In Hica, you build machines with `fun`:

```hica
fun double(n) => n * 2
fun square(n) => n * n

fun main() {
  let a = double(3)    // a = 6
  let b = square(a)    // b = 36
  println(b)
}
```

You can chain machines — feed the output of one into the next, like an
assembly line!

**🎯 Try it:** Write a function `triple(n)` that multiplies by 3. Then call
it twice:

```hica
fun triple(n) => n * 3

fun main() {
  let a = triple(4)     // What is a?
  let b = triple(a)     // What is b?
  println(b)
}
```

---
