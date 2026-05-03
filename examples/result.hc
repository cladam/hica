// Hica — result type: Ok and Err
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun validate_age(age) =>
  if age < 0 { Err("age cannot be negative") }
  else if age > 150 { Err("age seems unrealistic") }
  else { Ok(age) }

fun main() {
  // Ok case
  match safe_divide(10, 3) {
    Ok(n)  => println("10 / 3 = {n}"),
    Err(e) => println("error: {e}")
  }

  // Err case
  match safe_divide(10, 0) {
    Ok(n)  => println("10 / 0 = {n}"),
    Err(e) => println("error: {e}")
  }

  // Validation
  match validate_age(25) {
    Ok(a)  => println("valid age: {a}"),
    Err(e) => println(e)
  }

  match validate_age(-5) {
    Ok(a)  => println("valid age: {a}"),
    Err(e) => println(e)
  }
}
