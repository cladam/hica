// hica — std/validated — Error-accumulating validation
// Import with: import "std/validated"

import "std/nel"

// We use string for the Valid value. Since hica functions are polymorphic,
// combinators like zip_validated can map over different types using HM inference.
pub type Validated {
  Valid(value: string),
  Invalid(errors: Nel)
}

// Wrap a success value
pub fun valid(x: string) : Validated =>
  Valid(x)

// Wrap a single failure message
pub fun invalid(msg: string) : Validated =>
  Invalid(nel_of(msg))

// Map a function over a valid value
pub fun map_validated(v: Validated, f: (string) -> string) : Validated => match v {
  Valid(x)   => Valid(f(x)),
  Invalid(e) => Invalid(e)
}

// Combine/zip two validations. If both are valid, applies f.
// If either or both are invalid, accumulates/merges all errors!
pub fun zip_validated(v1: Validated, v2: Validated, f: (string, string) -> string) : Validated =>
  match v1 {
    Valid(x1) => match v2 {
      Valid(x2)   => Valid(f(x1, x2)),
      Invalid(e2) => Invalid(e2)
    },
    Invalid(e1) => match v2 {
      Valid(_)    => Invalid(e1),
      Invalid(e2) => Invalid(nel_concat(e1, e2))
    }
  }

// Convert a Validated to a standard Result
pub fun as_result(v: Validated) : result<string, list<string>> => match v {
  Valid(x)   => Ok(x),
  Invalid(e) => Err(nel_to_list(e))
}

// Convert a standard Result to a Validated
pub fun from_result(r: result<string, string>) : Validated => match r {
  Ok(x)  => Valid(x),
  Err(e) => invalid(e)
}
