# Level 24. Maps: The Lookup Book

Imagine a **dictionary**, you look up a word and find its meaning. Or a **phone book**, you look up a name and find a number. 
In Hica, this is called a **map**.

### Making a map

Use curly braces with `"key": value` pairs:

```hica
let ages = {"kalle": 30, "olle": 25, "lisa": 35}
println(ages)
```

Output: `[("kalle",30),("olle",25),("lisa",35)]`

Think of it like a table with two columns:

| Key       | Value |
| --------- | ----- |
| `"kalle"` | `30`  |
| `"olle"`  | `25`  |
| `"lisa"`  | `35`  |

### Looking things up

Use `map_get` to find a value by its key. It returns a **maybe**: because
the key might not exist!

```hica
let ages = {"kalle": 30, "olle": 25}
println(ages.map_get("kalle"))    // Just(30) — found it!
println(ages.map_get("nobody"))   // Nothing — not there
```

### Adding and changing entries

Use `map_set` to add a new key or change an existing one:

```hica
let ages = {"kalle": 30, "olle": 25}
let ages2 = ages.map_set("lisa", 35)    // adds lisa
let ages3 = ages2.map_set("olle", 26)   // updates olle
println(ages3.map_keys())               // ["kalle", "olle", "lisa"]
```

Maps don't change, `map_set` gives you a **new** map with the change.
The original stays the same.

### Removing entries

```hica
let ages = {"kalle": 30, "olle": 25, "lisa": 35}
let ages2 = ages.map_remove("olle")
println(ages2.map_keys())   // ["kalle", "lisa"]
```

### Empty maps

Use `{:}` to create an empty map, then build it up with `map_set`:

```hica
let m = {:}
let m2 = m.map_set("x", 1).map_set("y", 2)
println(m2)   // [("x",1),("y",2)]
```

### Map tools

| Tool | What it does | Example |
| --- | --- | --- |
| `map_get(m, key)` | Look up a key | `m.map_get("kalle")` → `Just(30)` |
| `map_set(m, key, val)` | Add or change | `m.map_set("lisa", 35)` |
| `map_remove(m, key)` | Remove a key | `m.map_remove("olle")` |
| `map_keys(m)` | All the keys | `m.map_keys()` → `["kalle", "olle"]` |
| `map_values(m)` | All the values | `m.map_values()` → `[30, 25]` |
| `map_contains_key(m, key)` | Is the key there? | `m.map_contains_key("kalle")` → `true` |
| `map_size(m)` | How many entries? | `m.map_size()` → `2` |

### The secret: maps are lists!

Under the hood, a map is just a **list of tuples**. Pairs of (key, value).
That means you can use all the list tools on maps too:

```hica
let scores = {"kalle": 95, "olle": 60, "lisa": 88}
let high = scores.filter((entry) => entry.1 >= 80)
println(high)   // [("kalle",95),("lisa",88)]
```

**🎯 Try it:** Create a map of your favourite animals and their sounds
(like `{"cat": "meow", "dog": "woof"}`). Look up one that exists and one
that doesn't.

**🎯 Try it:** Start with an empty map `{:}` and use `map_set` to add three
friends and their ages. Then print `map_keys()` and `map_size()`.

