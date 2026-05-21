# Level 27. Structs: Build Your Own Types

Tuples are great for bundling a few values together, but what if you have three,
four, or more fields? And what if you can't remember whether `.0` is the name or
the age? That's where **structs** come in.

A struct is like designing your own **custom box** with labelled compartments.

### Defining a struct

Use the `struct` keyword to create a new type:

```hica
struct Pet { name: string, species: string, age: int }
```

This creates a new type called `Pet` with three named fields.

### Making a struct value

Fill in the fields by name:

```hica
struct Pet { name: string, species: string, age: int }

fun main() {
  let buddy = Pet { name: "Daisy", species: "cat", age: 3 }
  println(buddy)
}
```

Output: `Pet(name: Daisy, species: cat, age: 3)`

### Reading fields

Use a dot and the field name, this is much clearer than `.0` and `.1`!

```hica
struct Pet { name: string, species: string, age: int }

fun main() {
  let buddy = Pet { name: "Daisy", species: "cat", age: 3 }
  println(buddy.name)     // Daisy
  println(buddy.species)  // cat
  println(buddy.age)      // 3
}
```

### Structs as function parameters

You can pass structs to functions just like any other value:

```hica
struct Pet { name: string, species: string, age: int }

fun introduce(p: Pet) : string =>
  "{p.name} is a {p.age}-year-old {p.species}"

fun main() {
  let daisy = Pet { name: "Daisy", species: "cat", age: 3 }
  println(introduce(daisy))
}
```

Output: `Daisy is a 3-year-old cat`

### Tuples vs Structs

| Tuples | Structs |
|--------|--------|
| `("Daisy", "cat", 3)` | `Pet { name: "Daisy", species: "cat", age: 3 }` |
| Access with `.0`, `.1`, `.2` | Access with `.name`, `.species`, `.age` |
| Good for 2–3 values | Good for any number of fields |
| Quick and anonymous | Named and self-documenting |

Use tuples when it's obvious what the values mean (like `(x, y)` coordinates).
Use structs when you want names that explain the data.

**🎯 Try it:** Create a `Player` struct with `name: string` and `score: int`.
Write a function `level_up(p: Player) : string` that prints
`"{p.name} reached score {p.score}!"`.

### Updating a struct

Structs can't change (they're immutable), but you can make a copy with some
fields changed using `...`:

```hica
struct Pet { name: string, species: string, age: int }

fun main() {
  let daisy = Pet { name: "Daisy", species: "cat", age: 3 }
  let older = Pet { ...daisy, age: 4 }   // everything else stays the same!
  println(older)
}
```

Think of it like photocopying a form and writing over just one field.

### Taking structs apart in match

Remember `match`? You can use it to look inside a struct — like opening a
box and checking what's in each compartment:

```hica
struct Point { x: int, y: int }

fun describe(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y: 0 }    => "on x-axis",
  Point { x, y }       => "({x}, {y})"
}
```

- `Point { x, y }` — opens the box and names each field
- `Point { x: 0, y: 0 }` — only matches when both fields are zero
- `Point { x }` — you can skip fields you don't care about

**🎯 Try it:** Create a `Pet` struct with `name`, `species`, and `age`.
Write a `describe` function that uses match to print different messages
for kittens (age 0) vs older pets!

