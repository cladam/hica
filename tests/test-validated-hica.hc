// test-validated-hica.hc — Test suite for std/nel and std/validated
// Run with: ./hica test tests/test-validated-hica.hc

import "std/nel"
import "std/validated"

test "Nel: create and convert to list" {
  let n = nel_of("error 1")
  assert_eq(nel_head(n), "error 1")
  assert_eq(nel_to_list(n), ["error 1"])
}

test "Nel: concatenation" {
  let a = nel_of("error A")
  let b = nel_of("error B")
  let c = nel_concat(a, b)
  assert_eq(nel_to_list(c), ["error A", "error B"])
}

test "Nel: mapping" {
  let n = Nel("a", ["b", "c"])
  let mapped = nel_map(n, (s) => "{s}!")
  assert_eq(nel_to_list(mapped), ["a!", "b!", "c!"])
}

test "Validated: valid constructors" {
  let v = valid("success")
  match v {
    Valid(x) => assert_eq(x, "success"),
    Invalid(_) => assert(false)
  }
}

test "Validated: invalid constructors" {
  let iv = invalid("something went wrong")
  match iv {
    Valid(_) => assert(false),
    Invalid(e) => assert_eq(nel_to_list(e), ["something went wrong"])
  }
}

test "Validated: map_validated" {
  let v = valid("hello")
  let mapped = map_validated(v, (s) => "{s} world")
  match mapped {
    Valid(x) => assert_eq(x, "hello world"),
    Invalid(_) => assert(false)
  }
}

test "Validated: zip_validated success" {
  let v1 = valid("foo")
  let v2 = valid("bar")
  let zipped = zip_validated(v1, v2, (a, b) => "{a}-{b}")
  match zipped {
    Valid(x) => assert_eq(x, "foo-bar"),
    Invalid(_) => assert(false)
  }
}

test "Validated: zip_validated single failure" {
  let v1 = valid("foo")
  let v2 = invalid("bar failed")
  let zipped = zip_validated(v1, v2, (a, b) => "{a}-{b}")
  match zipped {
    Valid(_) => assert(false),
    Invalid(e) => assert_eq(nel_to_list(e), ["bar failed"])
  }
}

test "Validated: zip_validated accumulates multiple errors" {
  let v1 = invalid("first failed")
  let v2 = invalid("second failed")
  let zipped = zip_validated(v1, v2, (a, b) => "{a}-{b}")
  match zipped {
    Valid(_) => assert(false),
    Invalid(e) => assert_eq(nel_to_list(e), ["first failed", "second failed"])
  }
}

test "Validated: conversions" {
  let v = valid("ok")
  let r = as_result(v)
  match r {
    Ok(x) => assert_eq(x, "ok"),
    Err(_) => assert(false)
  }

  let iv = invalid("bad")
  let r2 = as_result(iv)
  match r2 {
    Ok(_) => assert(false),
    Err(es) => assert_eq(es, ["bad"])
  }
}
