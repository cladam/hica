// Fibonacci sequence
//
// Computes the Fibonacci sequence up to the Nth term.
// The sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...
//
// Showcases: recursion vs. iteration, accumulator pattern.
//
// Usage: hica run programs/fibonacci.hc

fun fib_iter(n: int, a: int, b: int) : int =>
  if n == 0 { a }
  else { fib_iter(n - 1, b, a + b) }

fun fib(n: int) : int => fib_iter(n, 0, 1)

fun fib_list_acc(i: int, n: int, acc: list<int>) : list<int> =>
  if i > n { reverse(acc) }
  else { fib_list_acc(i + 1, n, [fib(i)] + acc) }

fun fib_list(n: int) : list<int> => fib_list_acc(0, n, [])

fun main() {
  let line = input("Enter N (which Fibonacci number to compute): ")
  let n = parse_int(trim(line))
  match n {
    None => println("Please enter a valid number."),
    Some(v) =>
      if v < 0 { println("N must be 0 or greater.") }
      else {
        println("fib({v}) = {fib(v)}")
        println("")
        println("Sequence from 0 to {v}:")
        let seq = fib_list(v)
        println(join(map(seq, (x) => show(x)), ", "))
      }
  }
}

test "fib(0) = 0" {
  assert_eq(fib(0), 0)
}

test "fib(1) = 1" {
  assert_eq(fib(1), 1)
}

test "fib(2) = 1" {
  assert_eq(fib(2), 1)
}

test "fib(7) = 13" {
  assert_eq(fib(7), 13)
}

test "fib(10) = 55" {
  assert_eq(fib(10), 55)
}

test "fib(20) = 6765" {
  assert_eq(fib(20), 6765)
}

test "fib_list produces correct sequence" {
  assert_eq(fib_list(7), [0, 1, 1, 2, 3, 5, 8, 13])
}
