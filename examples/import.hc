// Import all pub items from greet.hc
import "greet"

fun main() {
  hello("world")
  goodbye("world")
  // secret() will fail as it'snot decladed pub
}
