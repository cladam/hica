// hica-semver: SemVer 2.0.0 parsing & comparison
// Uses: struct, split, index_of, removeprefix, parse_int, string slicing, var, loop, break

struct SemVer {
  major: int, 
  minor: int, 
  patch: int, 
  pre: string, 
  build: string
}

fun parse(s) {
  let v = removeprefix(s, "v")
  let (v2, build) = match index_of(v, "+") {
    Some(i) => (v[:i], v[i + 1:]),
    None    => (v, "")
  }
  let (v3, pre) = match index_of(v2, "-") {
    Some(i) => (v2[:i], v2[i + 1:]),
    None    => (v2, "")
  }
  let parts = split(v3, ".")
  if length(parts) != 3 { None }
  else {
    match (parse_int(parts[0]), parse_int(parts[1]), parse_int(parts[2])) {
      (Some(maj), Some(min), Some(pat)) =>
        Some(SemVer { major: maj, minor: min, patch: pat, pre: pre, build: build }),
      _ => None
    }
  }
}

fun cmp_ids(a, b) {
  match (parse_int(a), parse_int(b)) {
    (Some(an), Some(bn)) => if an < bn { -1 } else if an > bn { 1 } else { 0 },
    (Some(_), None)      => -1,
    (None, Some(_))      => 1,
    _                    => if a < b { -1 } else if a > b { 1 } else { 0 }
  }
}

// Compare prerelease identifier lists using loop + break
fun cmp_pre(a_ids, b_ids) {
  var ap = a_ids
  var bp = b_ids
  var result = 0
  loop {
    if length(ap) == 0 && length(bp) == 0 {
      break
    }
    else if length(ap) == 0 {
      result = -1
      break
    }
    else if length(bp) == 0 {
      result = 1
      break
    }
    else {
      let c = cmp_ids(ap[0], bp[0])
      if c != 0 {
        result = c
        break
      }
      ap = drop(ap, 1)
      bp = drop(bp, 1)
    }
  }
  result
}

fun cmp_versions(a: SemVer, b: SemVer) {
  if a.major != b.major { if a.major < b.major { -1 } else { 1 } }
  else if a.minor != b.minor { if a.minor < b.minor { -1 } else { 1 } }
  else if a.patch != b.patch { if a.patch < b.patch { -1 } else { 1 } }
  else if a.pre == "" && b.pre != "" { 1 }
  else if a.pre != "" && b.pre == "" { -1 }
  else { cmp_pre(split(a.pre, "."), split(b.pre, ".")) }
}

fun compare(a_str, b_str) {
  match (parse(a_str), parse(b_str)) {
    (Some(av), Some(bv)) => Ok(cmp_versions(av, bv)),
    _                    => Err("bad semver")
  }
}

fun main() {
  // parse
  println(parse("1.2.3"))
  println(parse("v1.0.0-alpha+build.1"))
  println(parse("bad"))

  // compare
  println(compare("1.0.0", "2.0.0"))
  println(compare("1.2.3", "1.2.3"))
  println(compare("1.0.0-alpha", "1.0.0"))
  println(compare("1.0.0-alpha", "1.0.0-beta"))
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "parse simple version" {
  let v = parse("1.2.3")
  match v {
    Some(sv) => {
      assert_eq(sv.major, 1)
      assert_eq(sv.minor, 2)
      assert_eq(sv.patch, 3)
      assert_eq(sv.pre, "")
      assert_eq(sv.build, "")
    },
    None => assert(false)
  }
}

test "parse with v prefix" {
  let v = parse("v2.0.0")
  match v {
    Some(sv) => assert_eq(sv.major, 2),
    None => assert(false)
  }
}

test "parse with prerelease" {
  let v = parse("1.0.0-alpha.1")
  match v {
    Some(sv) => assert_eq(sv.pre, "alpha.1"),
    None => assert(false)
  }
}

test "parse with build metadata" {
  let v = parse("1.0.0+build.42")
  match v {
    Some(sv) => assert_eq(sv.build, "build.42"),
    None => assert(false)
  }
}

test "parse with pre and build" {
  let v = parse("v1.0.0-alpha+build.1")
  match v {
    Some(sv) => {
      assert_eq(sv.pre, "alpha")
      assert_eq(sv.build, "build.1")
    },
    None => assert(false)
  }
}

test "parse invalid returns None" {
  match parse("bad") {
    None => assert(true),
    _    => assert(false)
  }
  match parse("1.2") {
    None => assert(true),
    _    => assert(false)
  }
}

test "compare: major differs" {
  assert_eq(compare("1.0.0", "2.0.0") |> unwrap, -1)
  assert_eq(compare("2.0.0", "1.0.0") |> unwrap, 1)
}

test "compare: minor differs" {
  assert_eq(compare("1.1.0", "1.2.0") |> unwrap, -1)
  assert_eq(compare("1.3.0", "1.2.0") |> unwrap, 1)
}

test "compare: patch differs" {
  assert_eq(compare("1.0.1", "1.0.2") |> unwrap, -1)
  assert_eq(compare("1.0.3", "1.0.2") |> unwrap, 1)
}

test "compare: equal versions" {
  assert_eq(compare("1.2.3", "1.2.3") |> unwrap, 0)
}

test "compare: prerelease < release" {
  assert_eq(compare("1.0.0-alpha", "1.0.0") |> unwrap, -1)
  assert_eq(compare("1.0.0", "1.0.0-alpha") |> unwrap, 1)
}

test "compare: prerelease ordering" {
  assert_eq(compare("1.0.0-alpha", "1.0.0-beta") |> unwrap, -1)
  assert_eq(compare("1.0.0-beta", "1.0.0-alpha") |> unwrap, 1)
}

test "compare: numeric prerelease ids" {
  assert_eq(compare("1.0.0-1", "1.0.0-2") |> unwrap, -1)
  assert_eq(compare("1.0.0-2", "1.0.0-1") |> unwrap, 1)
}

test "compare: numeric before string in prerelease" {
  assert_eq(compare("1.0.0-1", "1.0.0-alpha") |> unwrap, -1)
}