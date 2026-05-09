// ============================================================
// Lesson 30: Maps
// ============================================================
//
// A map holds key-value pairs. Create one with curly braces:
//
//   {"kalle": 30, "olle": 25}    — string keys, int values
//   {"x": true, "y": false}      — string keys, bool values
//   {:}                          — empty map
//
// Under the hood, maps are lists of tuples. All list
// operations (map, filter, fold, …) work on maps too.
//
// Map functions:
//
//   map_get(m, key)              — look up a key (returns maybe)
//   map_set(m, key, value)       — add or update a key
//   map_remove(m, key)           — remove a key
//   map_keys(m)                  — list of all keys
//   map_values(m)                — list of all values
//   map_contains_key(m, key)     — check if a key exists
//   map_size(m)                  — number of entries
//
// ============================================================

fun main() {
  // Create a map
  let ages = {"kalle": 30, "olle": 25, "lisa": 35}
  println(ages)

  // Look up a key — returns maybe
  println(ages.map_get("kalle"))
  println(ages.map_get("nobody"))

  // Add or update a key
  let ages2 = ages.map_set("pelle", 28)
  println(ages2.map_keys())

  // Update an existing key
  let ages3 = ages.map_set("olle", 26)
  println(ages3.map_get("olle"))

  // Remove a key
  let ages4 = ages.map_remove("olle")
  println(ages4.map_keys())

  // Query
  println(ages.map_size())
  println(ages.map_contains_key("kalle"))
  println(ages.map_contains_key("nobody"))
  println(ages.map_values())

  // Empty map — {:}
  // Build up from nothing with map_set
  let m = {:}
  let m2 = m.map_set("x", 1).map_set("y", 2)
  println(m2)

  // Maps are lists — use list operations
  let expensive = ages.filter((entry) => entry.1 >= 30)
  println(expensive)
}

// ============================================================
// Challenge: Create a map of your favourite fruits and their
// colours. Print all the keys.
//
// Challenge: Use map_set to add a new fruit, then remove one
// with map_remove. Print the result.
//
// Challenge: Use filter on a map to keep only entries where
// the value is greater than some threshold.
// ============================================================
