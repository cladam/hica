// Test: float fields in enum show
type Measurement {
  Celsius(temp: float),
  Fahrenheit(temp: float)
}

fun main() {
  let c = Celsius(36.6)
  let f = Fahrenheit(98.6)
  println(c)
  println(f)
}
