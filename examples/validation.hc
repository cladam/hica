// examples/validation.hc — Form validation with the Validated type
// Run with: ./hica run examples/validation.hc

import "std/nel"
import "std/validated"

struct User {
  username: string,
  email: string,
  age: int
}

fun validate_username(s: string) : Validated =>
  if str_length(s) < 3 { invalid("Username must be at least 3 characters") }
  else { valid(s) }

fun validate_email(s: string) : Validated =>
  if !contains(s, "@") { invalid("Email must contain @") }
  else { valid(s) }

fun validate_age(s: string) : Validated =>
  match parse_int(s) {
    None => invalid("Age must be a number"),
    Some(n) =>
      if n < 18 { invalid("Must be at least 18 years old") }
      else { valid(s) }
  }

fun signup_sugared(uname: string, email_input: string, age_input: string) : Validated {
  let u = validate_username(uname)&?
  let e = validate_email(email_input)&?
  let a = validate_age(age_input)&?
  Valid("{u}:{e}:{a}")
}

fun signup(uname: string, email_input: string, age_input: string) {
  println("----------------------------------------")
  println("Signing up user: {uname}, {email_input}, {age_input}")

  // Combine multiple validations
  // zip_validated runs both validations and merges errors if any fail.
  let v_user_partial = zip_validated(validate_username(uname), validate_email(email_input), (u, e) => "{u}:{e}")
  let v_all = zip_validated(v_user_partial, validate_age(age_input), (partial, a) => "{partial}:{a}")

  match v_all {
    Valid(info) => {
      let parts = split(info, ":")
      let user = User { username: parts[0], email: parts[1], age: unwrap_maybe_or(parse_int(parts[2]), 0) }
      println("✓ Validation Succeeded!")
      println("  User profile created:")
      println("  - Username: {user.username}")
      println("  - Email:    {user.email}")
      println("  - Age:      {user.age}")
    },
    Invalid(errs) => {
      println("✗ Validation Failed! Found {length(nel_to_list(errs))} error(s):")
      let err_list = nel_to_list(errs)
      for err in err_list {
        println("  - {err}")
      }
    }
  }
}

fun run_sugared_signup(uname: string, email_input: string, age_input: string) {
  println("----------------------------------------")
  println("Signing up user (sugared &?): {uname}, {email_input}, {age_input}")

  match signup_sugared(uname, email_input, age_input) {
    Valid(info) => {
      let parts = split(info, ":")
      let user = User { username: parts[0], email: parts[1], age: unwrap_maybe_or(parse_int(parts[2]), 0) }
      println("✓ Validation Succeeded!")
      println("  User profile created: {user.username}, {user.email}, {user.age}")
    },
    Invalid(errs) => {
      println("✗ Validation Failed! Found {length(nel_to_list(errs))} error(s):")
      let err_list = nel_to_list(errs)
      for err in err_list {
        println("  - {err}")
      }
    }
  }
}

fun main() {
  println("Hica Error Accumulating Validation Example")
  
  // Success case
  signup("cladam", "claes.adamsson@gmail.com", "46")
  run_sugared_signup("cladam", "claes.adamsson@gmail.com", "46")

  // Multi-failure case (sugared early-returns on the first failure in sequence)
  run_sugared_signup("jd", "invalid-email", "15")

  // Multi-failure case (all inputs are invalid)
  signup("jd", "invalid-email", "15")

  // Partial failure case
  signup("john_doe", "john@example.com", "not-a-number")
}
