# Exploratory Learning: Discovering hica via the REPL

The absolute best way to learn `hica` is to load our `examples/` directory into the REPL and explore them interactively. Instead of just running examples as passive, static binaries, the REPL lets you dissect them, query their types, test functions with custom inputs, and even rewrite behavior on the fly.

Here is your step-by-step guide to exploring examples interactively:

### Step 1: Fire Up the REPL
Open your terminal at the root of the project directory and launch the REPL:
```sh
hica repl
```

### Step 2: Load an Example (`:load`)
You can load any example file in the `examples/` directory into your active session using the `:load` command. For instance, let’s load the `fizzbuzz.hc` example:
```hica
hica=> :load examples/fizzbuzz.hc
  loading examples/fizzbuzz.hc
  loaded: fizzbuzz
```
*Behind the scenes, the REPL parses, type-checks, and loads the example's code and all of its dependencies instantly.*

### Step 3: Inspect the Scope (`:defs`)
Curious about what definitions the example introduced? List the current active function, struct, and enum definitions:
```hica
hica=> :defs
  fun fizzbuzz(n)
```

### Step 4: Interrogate Types (`:t`)
Before calling anything, inspect how the compiler inferred the type of the example's functions:
```hica
hica=> :t fizzbuzz
  (n: int) : string
```
*This instantly shows you that `fizzbuzz` takes an `int` and returns a `string`, without you having to read the source file.*

### Step 5: Execute and Experiment
Now, test the functions with your own inputs! You don't have to compile a `main` function—you can evaluate expressions directly:
```hica
hica=> fizzbuzz(15)
"FizzBuzz"
hica=> fizzbuzz(7)
"7"
```

### Step 6: Mutate, Extend, and Refine
You aren't restricted to what’s in the file. You can declare new functions on top of the loaded example, or extend the existing behavior! 
Let's write a small helper to run `fizzbuzz` over a custom range:
```hica
hica=> fun fizz_range(lo, hi) { [lo..=hi] |> map(fizzbuzz) }
  defined: fizz_range
hica=> fizz_range(1, 15)
["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]
```

### Step 7: Wipe the Slate and Move On (`:reset`)
Ready to explore a different example? You don’t need to close and restart the REPL. Simply clear the active session state and load the next file:
```hica
hica=> :reset
  state cleared
hica=> :load examples/word_count.hc
  loading examples/word_count.hc
  loaded: count_words, show_entry
```

---

### Suggested Progression:
1. 💡 **`examples/fizzbuzz.hc`**: Perfect for learning basic control-flow, conditionals, and integer-to-string operations.
2. 📝 **`examples/word_count.hc`**: Ideal for learning list patterns (`[x, ..rest]`), recursive lists, functional folds, and string manipulation.
3. 📦 **`examples/json_parser.hc`** (or other advanced examples): Great for understanding complex custom ADTs (`type` enums), tuples, and state cursors.

This also turned in to a blogpost at https://cladam.github.io/2026/07/21/exploratory-learning/