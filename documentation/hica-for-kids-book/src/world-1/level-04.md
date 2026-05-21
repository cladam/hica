# Level 4. Your First Program — Hello, World!

The classic first program. In Hica, it's just two lines:

```hica
fun main() {
  println("Hello, world!")
}
```

That's it! No imports, no class, no semicolons. Just a function called `main`
that prints a greeting.

**🎯 Try it:** Save that line in a file called `hello.hc` and run it:
```sh
./hica run hello.hc
```

There are actually several ways to write the same thing in Hica:

```hica
// Block body with println
fun main() {
  println("Hello, world!")
}

// Arrow body (shortest)
fun main() => println("Hello, world!")

// Let binding + println
fun main() {
  let msg = "Hello, world!"
  println(msg)
}

// Helper function
fun greet() => "Hello, world!"
fun main() {
  println(greet())
}
```

Pick whichever style you like. They all do the same thing!
