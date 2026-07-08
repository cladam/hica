# Level 20. Tuples: Bundling Values Together

Sometimes you want to keep two (or more) values together, like an **x** and
**y** position, or a name and an age. A **tuple** is a tiny bundle that holds
several values side by side.

### Making a tuple

Wrap values in parentheses, separated by commas:

```hica
let point = (10, 20)
let person = ("Alicia", 15)
```

### Getting values out

Use `.0` for the first item and `.1` for the second:

```hica
let point = (10, 20)
println("{point.0}")  // 10
println("{point.1}")   // 20
```

Think of `.0` as "the first pocket" and `.1` as "the second pocket".

### Destructuring: opening the bundle

You can unpack a tuple into separate variables with `let`:

```hica
let point = (10, 20)
let (x, y) = point
println("{x}")  // 10
println("{y}")  // 20
```

This is called **destructuring**. You "take apart" the tuple and give each
piece its own name.

### When are tuples handy?

* Returning two things from a function
* Grouping coordinates: `(x, y)`
* Keeping a pair of related data together without inventing a new type

**🎯 Try it:** Make a tuple `("hica", 2026)` and print both parts using `.0`
and `.1`.

