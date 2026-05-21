# Level 33. Sharing Code Between Files

When your programs get bigger, you might want to put some functions in a
separate file. That's what **imports** are for!

### Making things shareable

To share a function from a file, add `pub` in front of it:

```hica
// helpers.hc
pub fun double(x) => x * 2
pub fun triple(x) => x * 3
fun secret() => 42   // no pub — stays hidden!
```

`pub` is short for "public". It means: "other files are allowed to use this."

### Importing

In another file, use `import` to bring those shared functions in:

```hica
// main.hc
import "helpers"

fun main() {
  println(double(5))   // 10
  println(triple(5))   // 15
  // secret() would fail — it's not pub!
}
```

The name in quotes is the file name **without** `.hc`. If `helpers.hc` is in
the same folder as your main file, just write `"helpers"`.

### Picking what you want

Sometimes a file has lots of functions but you only need one. Use
`from ... import { }` to pick:

```hica
from "helpers" import { double }

fun main() {
  println(double(5))   // works!
  // triple(5)         // nope — we didn't import it
}
```

Think of it like ordering from a menu: you don't have to take everything,
just pick the dishes you want.

### Passing things along

If you want to share someone else's functions through your file, use
`pub import`:

```hica
// everything.hc
pub import "helpers"
pub import "math_tools"
```

Now anyone who imports `everything` gets all the pub functions from both
`helpers` and `math_tools`. It's like being a librarian: you collect books
from different shelves and put them on one table.

**🎯 Challenge:** Create two files — `animals.hc` with `pub fun cat()` and
`pub fun dog()`, and a main file that imports them and prints each animal's
sound!

