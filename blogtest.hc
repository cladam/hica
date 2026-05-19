fun has_digit(s) => any(chars(s), (c) => is_digit(c))

fun validate(password) {
  let long_enough = str_length(password) >= 6
  long_enough && has_digit(password)
}

test "valid password has 6+ characters" {
  assert(validate("secret123"))
}

test "rejects password without digit" {
  assert_false(validate("noNumbersHere"))
}

test "rejects short password" {
  assert_false(validate("ab1"))
}
