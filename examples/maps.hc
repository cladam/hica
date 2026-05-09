// Maps: key-value dictionaries using {"key": value} syntax

fun main() {
  // Create a map
  let scores = {"alice": 95, "bob": 87, "carol": 92}
  println(scores)

  // Lookup
  println(scores.map_get("alice"))
  println(scores.map_get("nobody"))

  // Update
  let scores2 = scores.map_set("bob", 99)
  println(scores2.map_get("bob"))

  // Remove
  let scores3 = scores2.map_remove("carol")
  println(scores3.map_keys())

  // Map metadata
  println(scores.map_size())
  println(scores.map_contains_key("alice"))
  println(scores.map_contains_key("nobody"))

  // Keys and values
  println(scores.map_keys())
  println(scores.map_values())

  // Empty map — use map_set to add entries
  let config = {:}
  let config2 = config.map_set("debug", "true")
  println(config2.map_get("debug"))
}
