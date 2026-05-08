fun sum(a: int, b: int) : int => a + b

fun double(n: int) : int => n * 2

test "addition works" {
  assert(1 + 1 == 2)
  assert(sum(3, 4) == 7)
}

test "double function" {
  assert_eq(double(5), 10)
  assert_eq(double(0), 0)
}

test "string operations" {
  let s = "hello"
  assert(str_length(s) == 5)
  assert_eq(to_upper(s), "HELLO")
}
