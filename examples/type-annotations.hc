// Hica — type annotations
// Type annotations are optional — the compiler infers types.
// But you can add them for clarity or when inference needs help.

// Annotated function: params and return type
fun add(a: int, b: int) : int => a + b

// Only some params annotated — the rest are inferred
fun greet(name: string) => "hello, {name}!"

// Tuple type annotation — solves the polymorphic tuple problem
fun swap(p: (int, int)) : (int, int) => (p.1, p.0)

fun main() {
  // Annotated let bindings
  let x: int = 42
  let msg: string = "the answer"
  println("{msg}: {x}")

  println(add(x, 8))

  println(greet("world"))

  // Tuple annotation
  let pair: (int, int) = (3, 7)
  println(swap(pair))

  // List annotation
  let nums: list<int> = [10, 20, 30]
  println(nums)

  // Maybe annotation
  let found: maybe<int> = Some(99)
  println(found)

  // Without annotations — inference handles it
  let y = 100
  println(add(y, 1))
}
