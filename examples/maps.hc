// Maps: key-value dictionaries using {"key": value} syntax

fun main() {
  // Create a map
  let scores = {"kalle": 95, "olle": 87, "lisa": 92}
  println(scores)

  // Lookup
  println(scores.map_get("kalle"))
  println(scores.map_get("nobody"))

  // Update
  let scores2 = scores.map_set("olle", 99)
  println(scores2.map_get("olle"))

  // Remove
  let scores3 = scores2.map_remove("lisa")
  println(scores3.map_keys())

  // Map metadata
  println(scores.map_size())
  println(scores.map_contains_key("kalle"))
  println(scores.map_contains_key("nobody"))

  // Keys and values
  println(scores.map_keys())
  println(scores.map_values())

  // Empty map — use map_set to add entries
  let config = {:}
  let config2 = config.map_set("debug", "true")
  println(config2.map_get("debug"))
}
