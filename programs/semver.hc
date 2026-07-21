// hica-semver: SemVer 2.0.0 parsing & comparison
// Uses: struct, split, index_of, removeprefix, parse_int, string slicing, slice patterns

// ---------------------------------------------------------------------------
// Core types
// ---------------------------------------------------------------------------

struct SemVer {
  major: int, 
  minor: int, 
  patch: int, 
  pre: string, 
  build: string
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Check if a numeric string is valid (no leading zeros: "01" invalid, "0" valid)
fun valid_num(n: string) : bool {
  if length(n) > 1 && n[:1] == "0" { false }
  else { true }
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/// Parse a SemVer 2.0.0 string into a SemVer struct.
/// Supports optional 'v' prefix, prerelease (-), and build metadata (+).
/// Returns None for invalid versions.
fun parse(s: string) : maybe<SemVer> {
  let v = removeprefix(s, "v")
  
  // Extract build metadata (after +)
  let (v2, build) = match index_of(v, "+") {
    Some(i) => (v[:i], v[i + 1:]),
    None    => (v, "")
  }
  
  // Extract prerelease (after -)
  let (v3, pre) = match index_of(v2, "-") {
    Some(i) => (v2[:i], v2[i + 1:]),
    None    => (v2, "")
  }
  
  // Validate: no leading zeros on numeric parts
  let parts = split(v3, ".")
  if length(parts) != 3 { None }
  else {
    match (
      parse_int(parts[0]), 
      parse_int(parts[1]), 
      parse_int(parts[2])
    ) {
      (Some(maj), Some(min), Some(pat)) =>
        if valid_num(parts[0]) && valid_num(parts[1]) && valid_num(parts[2]) {
          Some(SemVer { major: maj, minor: min, patch: pat, pre: pre, build: build })
        } else {
          None
        },
      _ => None
    }
  }
}

// ---------------------------------------------------------------------------
// Prerelease comparison helpers
// ---------------------------------------------------------------------------

/// Compare two prerelease identifier strings per SemVer 2.0.0 §6.1:
/// - Numeric identifiers always have lower precedence than alphanumeric
/// - Numeric identifiers compare as integers
/// - Alphanumeric identifiers compare lexically
fun cmp_ids(a: string, b: string) : int => match (parse_int(a), parse_int(b)) {
  (Some(an), Some(bn)) => if an < bn { -1 } else if an > bn { 1 } else { 0 },
  (Some(_), None)      => -1,
  (None, Some(_))      => 1,
  _                    => if a < b { -1 } else if a > b { 1 } else { 0 }
}

// Compare prerelease identifier lists using recursion
fun cmp_pre(a_ids: list<string>, b_ids: list<string>) : int => match a_ids {
  [] => if length(b_ids) == 0 { 0 } else { -1 },
  [a, ..a_rest] => match b_ids {
    [] => 1,
    [b, ..b_rest] => {
      let c = cmp_ids(a, b)
      if c != 0 { c } else { cmp_pre(a_rest, b_rest) }
    }
  }
}

// ---------------------------------------------------------------------------
// Version comparison
// ---------------------------------------------------------------------------

/// Compare two SemVer versions: returns -1 (less), 0 (equal), or 1 (greater)
fun cmp_versions(a: SemVer, b: SemVer) : int {
  if a.major != b.major { if a.major < b.major { -1 } else { 1 } }
  else if a.minor != b.minor { if a.minor < b.minor { -1 } else { 1 } }
  else if a.patch != b.patch { if a.patch < b.patch { -1 } else { 1 } }
  else if a.pre == "" && b.pre != "" { 1 }
  else if a.pre != "" && b.pre == "" { -1 }
  else { cmp_pre(split(a.pre, "."), split(b.pre, ".")) }
}

/// Compare two SemVer strings. Returns Ok(int) or Err("bad semver")
fun compare(a_str: string, b_str: string) : result<int, string> {
  match (parse(a_str), parse(b_str)) {
    (Some(av), Some(bv)) => Ok(cmp_versions(av, bv)),
    _                    => Err("bad semver")
  }
}

// ---------------------------------------------------------------------------
// Convenience functions
// ---------------------------------------------------------------------------

/// Check if a version has a prerelease component
fun is_prerelease(s: string) : bool {
  match parse(s) {
    Some(v) => v.pre != "",
    None    => false
  }
}

/// Serialize a SemVer struct back to a string
fun to_string(v: SemVer) : string {
  let core = show(v.major) + "." + show(v.minor) + "." + show(v.patch)
  let with_pre = if v.pre != "" { core + "-" + v.pre } else { core }
  if v.build != "" { with_pre + "+" + v.build } else { with_pre }
}

/// Serialize a SemVer string (convenience wrapper)
fun ver_str(v: string) : string {
  match parse(v) {
    Some(sv) => to_string(sv),
    None     => v
  }
}

// Comparison convenience functions
fun eq(a: string, b: string) : result<bool, string> => compare(a, b) |> map_result((c) => c == 0)
fun lt(a: string, b: string) : result<bool, string> => compare(a, b) |> map_result((c) => c < 0)
fun le(a: string, b: string) : result<bool, string> => compare(a, b) |> map_result((c) => c <= 0)
fun gt(a: string, b: string) : result<bool, string> => compare(a, b) |> map_result((c) => c > 0)
fun ge(a: string, b: string) : result<bool, string> => compare(a, b) |> map_result((c) => c >= 0)

/// Bump major version, reset minor and patch to 0, clear prerelease
fun bump_major(v: SemVer) : SemVer => SemVer { major: v.major + 1, minor: 0, patch: 0, pre: "", build: "" }

/// Bump minor version, reset patch to 0, clear prerelease
fun bump_minor(v: SemVer) : SemVer => SemVer { major: v.major, minor: v.minor + 1, patch: 0, pre: "", build: "" }

/// Bump patch version, clear prerelease
fun bump_patch(v: SemVer) : SemVer => SemVer { major: v.major, minor: v.minor, patch: v.patch + 1, pre: "", build: "" }

// ---------------------------------------------------------------------------
// Main / demo
// ---------------------------------------------------------------------------

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
  
  // convenience
  println(is_prerelease("1.0.0-alpha"))
  println(to_string(SemVer { major: 1, minor: 2, patch: 3, pre: "alpha", build: "build" }))
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

test "parse rejects leading zeros" {
  match parse("1.01.0") {
    None => assert(true),
    _    => assert(false)
  }
  match parse("1.0.00") {
    None => assert(true),
    _    => assert(false)
  }
  match parse("01.0.0") {
    None => assert(true),
    _    => assert(false)
  }
}

test "parse allows single zero" {
  let v = parse("0.0.0")
  match v {
    Some(sv) => {
      assert_eq(sv.major, 0)
      assert_eq(sv.minor, 0)
      assert_eq(sv.patch, 0)
    },
    None => assert(false)
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

test "is_prerelease" {
  assert(is_prerelease("1.0.0-alpha"))
  assert(!is_prerelease("1.0.0"))
}

test "to_string" {
  assert_eq(to_string(SemVer { major: 1, minor: 2, patch: 3, pre: "", build: "" }), "1.2.3")
  assert_eq(to_string(SemVer { major: 1, minor: 0, patch: 0, pre: "alpha", build: "build" }), "1.0.0-alpha+build")
}

test "bump functions" {
  let v = SemVer { major: 1, minor: 2, patch: 3, pre: "", build: "" }
  
  let bumped = bump_major(v)
  assert_eq(bumped.major, 2)
  assert_eq(bumped.minor, 0)
  assert_eq(bumped.patch, 0)
  assert_eq(bumped.pre, "")
  
  let v2 = SemVer { major: 0, minor: 5, patch: 0, pre: "", build: "" }
  let bumped2 = bump_minor(v2)
  assert_eq(bumped2.minor, 6)
  
  let v3 = SemVer { major: 1, minor: 0, patch: 0, pre: "alpha", build: "" }
  let bumped3 = bump_patch(v3)
  assert_eq(bumped3.patch, 1)
  assert_eq(bumped3.pre, "")
}

test "comparison convenience functions" {
  assert(eq("1.0.0", "1.0.0") |> unwrap)
  assert(!eq("1.0.0", "2.0.0") |> unwrap)
  
  assert(lt("1.0.0", "2.0.0") |> unwrap)
  assert(!lt("2.0.0", "1.0.0") |> unwrap)
  
  assert(gt("2.0.0", "1.0.0") |> unwrap)
  assert(!gt("1.0.0", "2.0.0") |> unwrap)
  
  assert(le("1.0.0", "1.0.0") |> unwrap)
  assert(le("1.0.0", "2.0.0") |> unwrap)
  
  assert(ge("2.0.0", "1.0.0") |> unwrap)
  assert(ge("1.0.0", "1.0.0") |> unwrap)
}

test "compare returns Err for invalid input" {
  match compare("bad", "1.0.0") {
    Err(_) => assert(true),
    _      => assert(false)
  }
  match compare("1.0.0", "invalid") {
    Err(_) => assert(true),
    _      => assert(false)
  }
}