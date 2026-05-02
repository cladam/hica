// hica-semver: SemVer 2.0.0 parsing & comparison
// Requires: split, find, starts_with, trim, to_int, slice

fun parse(s) {
  let v = if starts_with(s, "v") { s[1:] } else { s };
  let (v2, build) = match find(v, "+") {
    Some(i) => (v[:i], v[i + 1:]),
    None    => (v, "")
  };
  let (v3, pre) = match find(v2, "-") {
    Some(i) => (v2[:i], v2[i + 1:]),
    None    => (v2, "")
  };
  let parts = split(v3, ".");
  if length(parts) != 3 { None }
  else {
    let nums = map(parts, (p) => to_int(p));
    if any(nums, (n) => n < 0) { None }
    else { Some((nums[0], nums[1], nums[2], pre, build)) }
  }
}

fun cmp_ids(a, b) {
  let an = to_int(a);
  let bn = to_int(b);
  let a_num = an >= 0;
  let b_num = bn >= 0;
  if a_num && b_num {
    if an < bn { -1 } else if an > bn { 1 } else { 0 }
  }
  else if a_num { -1 }
  else if b_num { 1 }
  else if a < b { -1 }
  else if a > b { 1 }
  else { 0 }
}

fun compare(a_str, b_str) {
  let a = parse(a_str);
  let b = parse(b_str);
  match (a, b) {
    (Some(av), Some(bv)) => cmp_versions(av, bv),
    _                    => Err("bad semver")
  }
}

fun cmp_versions(a, b) {
  let (amaj, amin, apat, apre, _) = a;
  let (bmaj, bmin, bpat, bpre, _) = b;
  if amaj != bmaj { if amaj < bmaj { -1 } else { 1 } }
  else if amin != bmin { if amin < bmin { -1 } else { 1 } }
  else if apat != bpat { if apat < bpat { -1 } else { 1 } }
  else if apre == "" && bpre != "" { 1 }
  else if apre != "" && bpre == "" { -1 }
  else { cmp_pre(split(apre, "."), split(bpre, ".")) }
}

fun cmp_pre(ap, bp) {
  if length(ap) == 0 && length(bp) == 0 { 0 }
  else if length(ap) == 0 { -1 }
  else if length(bp) == 0 { 1 }
  else {
    let c = cmp_ids(ap[0], bp[0]);
    if c != 0 { c }
    else { cmp_pre(drop(ap, 1), drop(bp, 1)) }
  }
}

fun main() {
  // parse
  println(parse("1.2.3"));
  println(parse("v1.0.0-alpha+build.1"));
  println(parse("bad"));

  // compare
  println(compare("1.0.0", "2.0.0"));
  println(compare("1.2.3", "1.2.3"));
  println(compare("1.0.0-alpha", "1.0.0"));
  println(compare("1.0.0-alpha", "1.0.0-beta"))
}