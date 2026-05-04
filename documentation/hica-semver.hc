// hica-semver: SemVer 2.0.0 parsing & comparison
// Uses: struct, split, index_of, removeprefix, parse_int, string slicing

struct SemVer { major: int, minor: int, patch: int, pre: string, build: string }

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

fun compare(a_str, b_str) {
  match (parse(a_str), parse(b_str)) {
    (Some(av), Some(bv)) => Ok(cmp_versions(av, bv)),
    _                    => Err("bad semver")
  }
}

fun cmp_versions(a: SemVer, b: SemVer) {
  if a.major != b.major { if a.major < b.major { -1 } else { 1 } }
  else if a.minor != b.minor { if a.minor < b.minor { -1 } else { 1 } }
  else if a.patch != b.patch { if a.patch < b.patch { -1 } else { 1 } }
  else if a.pre == "" && b.pre != "" { 1 }
  else if a.pre != "" && b.pre == "" { -1 }
  else { cmp_pre(split(a.pre, "."), split(b.pre, ".")) }
}

fun cmp_pre(ap, bp) {
  if length(ap) == 0 && length(bp) == 0 { 0 }
  else if length(ap) == 0 { -1 }
  else if length(bp) == 0 { 1 }
  else {
    let c = cmp_ids(ap[0], bp[0])
    if c != 0 { c }
    else { cmp_pre(drop(ap, 1), drop(bp, 1)) }
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