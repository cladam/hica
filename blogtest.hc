fun validate(password) {
  let long_enough = str_length(password) >= 6
  let has_bang = contains(password, "!")
  long_enough && has_bang
}

test "valid password has 6+ characters" {
  assert(validate("secret!123"))
}

test "rejects password without special char" {
  assert_false(validate("noSpecialHere"))
}

test "rejects short password" {
  assert_false(validate("ab!"))
}
