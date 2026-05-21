# Level 28. Enums: Choose Your Adventure

Remember structs? A struct says "every value has the same fields." But what if
a value could be **one of several different things**? That's an **enum**. Short
for "enumeration."

Think of it like a "choose your adventure" book. At each point, the story can
take one of several different paths. An enum says: "this value is one of these
options."

### A simple enum

The simplest enum is just a list of named options, like picking a colour
from a fixed set:

```hica
type Color {
  Red,
  Green,
  Blue
}

fun main() {
  let c = Red
  println(c)        // Red
}
```

`type` creates a new type. `Red`, `Green`, and `Blue` are the **variants** —
the possible values. No numbers, no strings. Just names. Clear and
impossible to misspell (the compiler catches typos!).

### Enums with data

Here's where enums get really powerful. Each variant can carry **different
data**:

```hica
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}
```

- `Circle` carries one float (the radius)
- `Rect` carries two floats (width and height)
- `Point` carries nothing at all

Think of it like different kinds of packages: a round tube for circles,
a flat box for rectangles, and just a dot for points.

### Making enum values

Construct them like function calls:

```hica
fun main() {
  let s1 = Circle(5.0)
  let s2 = Rect(3.0, 4.0)
  let s3 = Point

  println(s1)   // Circle(5)
  println(s2)   // Rect(3, 4)
  println(s3)   // Point
}
```

### Using match with enums

Here's the best part — `match` lets you handle each variant separately,
and it **unpacks the data** for you:

```hica
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}

fun describe(s: Shape) : string => match s {
  Circle(r)  => "a circle with radius {r}",
  Rect(w, h) => "a {w} by {h} rectangle",
  Point      => "just a point"
}

fun main() {
  println(describe(Circle(5.0)))
  println(describe(Rect(3.0, 4.0)))
  println(describe(Point))
}
```

Output:
```
a circle with radius 5
a 3 by 4 rectangle
just a point
```

The variables `r`, `w`, and `h` are bound by the pattern. They hold whatever
data was packed into the variant. It's like opening the package and seeing
what's inside!

### The compiler has your back

If you forget a variant in your `match`, the compiler warns you:

```
warning: non-exhaustive match: missing Point
```

This is like a checklist: the compiler makes sure you've handled every
possible case. No surprises at runtime!

### Enums vs Structs

| | Struct | Enum |
| --- | --- | --- |
| Every value looks... | The same (same fields) | Different (one of several variants) |
| Think of it as... | AND — has field A **and** field B | OR — is variant A **or** variant B |
| Example | `struct Pet { name: string, age: int }` | `type Shape { Circle(r: float), Point }` |

Use a struct when all values have the same shape. Use an enum when a value
can be one of several different things.

### A pet shelter example

```hica
type Animal {
  Dog(name: string, age: int),
  Cat(name: string),
  Fish
}

fun greet(a: Animal) : string => match a {
  Dog(name, age) => "{name} the dog, {age} years old",
  Cat(name)      => "{name} the cat",
  Fish           => "just a fish"
}

fun is_pet(a: Animal) : bool => match a {
  Fish => false,
  _    => true
}

fun main() {
  let animals = [Dog("Buddy", 3), Cat("Whiskers"), Fish]
  let pets = animals |> filter(is_pet)
  println("Pets: {pets}")
}
```

Output: `Pets: [Dog(Buddy, 3),Cat(Whiskers)]`

**🎯 Try it:** Create a `type Vehicle` with variants `Car(seats: int)`,
`Bike`, and `Bus(seats: int)`. Write a function `capacity(v: Vehicle) : int`
that returns the number of seats (bikes have 1).

**🎯 Challenge:** Create a `type Coin` with `Heads` and `Tails`. Use
`random(0, 1)` to pick one and `match` to print the result!

