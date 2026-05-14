fun my_sum(a: int, b: int) : int => a + b

fun double(n: int) : int => n * 2

test "addition works" {
  assert(1 + 1 == 2)
  assert(my_sum(3, 4) == 7)
}

test "double function" {
  assert_eq(double(5), 10)
  assert_eq(double(0), 0)
  assert_ne(double(3), 0)
}

test "boolean assertions" {
  assert_true(10 > 5)
  assert_false(1 > 2)
}

test "string operations" {
  let s = "hello"
  assert(str_length(s) == 5)
  assert_eq(to_upper(s), "HELLO")
  assert_ne(s, "world")
}

test "list assertions" {
  let xs = [1, 2, 3]
  assert_contains(xs, 2)
  assert_not_empty(xs)
  assert_empty([])
}
